pipeline {
    agent any

    environment {
        src_CN  = 'db-utest'
        src_CDB = 'TUSERS'
        src_PDB = 'TUSERS_PDB'

        dest_CDB = 'TDETAILS'
        dest_CN  = 'db-dtest'
        dest_PDB = 'TDETAILS_PDB'

        // GoldenGate environment NOTE : You must dump the gg_binary.zip into /software volume in jenkins container manually
        OGG_VOLUME = 'ogg_users_detail_vol'
        OGG_CONTAINER = 'ogg-users_detail'
        OGG_HOME = '/u02/ogg/ggs_home'
        OGG_binary = 'gg_binary.zip' // This file has to be copied to my-jenkins docker container manually into /tmp/binaries/
        STAGE_DIR = '/tmp/binaries'

        // Goldengate Deployment parameters
        OGG_DEPLOY_NAME = 'ogg_deploy-Users-Detail'
        deploy_username = 'oggadmin'
        deploy_password = 'oracle'
        port_number   = '7809'
        }

    stages {

/*        stage('Pre-requisites for Golden-Gate Deploy') {
            steps {
                // SRC - Pre-requisite commands to be run on source DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                echo "Running Pre-requisites for Golden-Gate Deploy on Source DB in container $src_CN"
                docker cp scripts/pre-requisite-params.sql $src_CN:/tmp/pre-requisite-params.sql
                docker exec $src_CN sqlplus / as sysdba @/tmp/pre-requisite-params.sql $src_PDB
                '''

                // DEST - Pre-requisite commands to be run on destination DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                echo "Running Pre-requisites for Golden-Gate Deploy on Destination DB in container $dest_CN"
                docker cp scripts/pre-requisite-params.sql $dest_CN:/tmp/pre-requisite-params.sql
                docker exec $dest_CN sqlplus / as sysdba @/tmp/pre-requisite-params.sql $dest_PDB
                '''
           }
        }

        stage ('Creating OGG users and granting required privileges') {
            steps {
                // SRC - Create OGG user in source DB and grant required privileges
                sh '''
                docker cp scripts/oggadmin.sql $src_CN:/tmp/oggadmin.sql
                docker exec $src_CN sqlplus / as sysdba @/tmp/oggadmin.sql $src_PDB
                '''

                // DEST - Create OGG user in destination DB and grant required privileges
                sh '''
                docker cp scripts/oggadmin.sql $dest_CN:/tmp/oggadmin.sql
                docker exec $dest_CN sqlplus / as sysdba @/tmp/oggadmin.sql $dest_PDB
                '''
           }
        }*/

        stage ('Deploy GG Container') {
            steps {
                sh '''
                # Remove old container if exists
                if docker ps -a --format '{{.Names}}' | grep -q "^$OGG_CONTAINER\$"; then
                    docker stop $OGG_CONTAINER
                    docker run --rm -v $OGG_VOLUME:$OGG_HOME alpine sh -c "rm -rf $OGG_HOME/*"
                    docker rm -f $OGG_CONTAINER
                    docker volume rm $OGG_VOLUME
                    
                fi

                if ! docker volume inspect $OGG_VOLUME > /dev/null 2>&1; then
                    docker volume create $OGG_VOLUME
                fi

                # Start new GG container
                docker run -d --name $OGG_CONTAINER -v $OGG_VOLUME:/u02/ogg oraclelinux:8 tail -f /dev/null                
                '''
            }
        }

        stage('Create Oracle User and Copy scripts') {
          steps {
                  sh '''
                  # Create oracle user + group if not exists
                  docker exec -i -u root $OGG_CONTAINER bash -c "
                    getent group oinstall >/dev/null || groupadd -g 54321 oinstall
                    id -u oracle >/dev/null 2>&1 || useradd -u 54321 -g oinstall oracle
                  "
                  docker exec -i $OGG_CONTAINER bash -c "mkdir -p /tmp/install_scripts && chown oracle:oinstall /tmp/install_scripts && chmod 775 /tmp/install_scripts"                
                  docker cp scripts/. $OGG_CONTAINER:/tmp/install_scripts

                  docker exec -i -u root $OGG_CONTAINER bash -c "echo 'export OGG_HOME=/u02/ogg/ggs_home' > /etc/profile.d/ogg.sh"
                  docker exec -i -u root $OGG_CONTAINER bash -c "echo 'export PATH=\$OGG_HOME/bin:\$PATH' >> /etc/profile.d/ogg.sh"
                  '''
          }
        }

        stage ('Copy & Install GoldenGate') {
            steps {
                sh '''
                echo "Using existing GoldenGate binary: $OGG_binary"

                # Prepare directories with correct ownership
                docker exec -i -u root $OGG_CONTAINER bash -c "
                  mkdir -p ${STAGE_DIR} /u02/ogg /u02/oraInventory
                  chown -R oracle:oinstall ${STAGE_DIR} /u02/ogg /u02/oraInventory
                  chmod -R 775 /u02/ogg /u02/oraInventory
                "

                # Copy GG binary zip into container
                docker cp /software/$OGG_binary $OGG_CONTAINER:${STAGE_DIR}/$OGG_binary
                docker exec -i -u root -e STAGE_DIR="$STAGE_DIR" -e OGG_HOME="$OGG_HOME" $OGG_CONTAINER bash -c "chown oracle:oinstall ${STAGE_DIR}/$OGG_binary"

                docker exec -i -u root $OGG_CONTAINER bash -c '
                  if ! command -v unzip >/dev/null 2>&1; then
                    echo "Installing unzip..."
                    yum install -y -q unzip
                  else
                    echo "unzip already installed"
                  fi
                '

                # Install required Java packages
                docker exec -i -u root $OGG_CONTAINER bash -c '
                yum install -y -q libnsl libaio glibc libX11 libXau libxcb libXi libXtst libXrender libXext libstdc++ ksh gcc gcc-c++ make
                '
                
                # Unzip Binaries as oracle
                docker exec -i -u oracle $OGG_CONTAINER bash -c "
                  unzip -q -o ${STAGE_DIR}/$OGG_binary -d ${STAGE_DIR}/${OGG_binary%.zip}
                "

                # Create oraInst.loc
                docker exec -i -u root $OGG_CONTAINER bash -c "
                  echo 'inventory_loc=/u02/oraInventory' > /etc/oraInst.loc
                  echo 'inst_group=oinstall' >> /etc/oraInst.loc
                  chown oracle:oinstall /etc/oraInst.loc
                "
                if [ -d "$OGG_HOME" ]; then
                    echo "Cleaning existing OGG_HOME: $OGG_HOME"
                    rm -rf "$OGG_HOME"
                fi

                docker exec -i -u oracle $OGG_CONTAINER bash -c "mkdir -p $OGG_HOME && chown oracle:oinstall $OGG_HOME && chmod 775 $OGG_HOME"

                # Run GG INSTALLER as oracle user
                docker exec -i $OGG_CONTAINER bash -c "chmod +x /tmp/install_scripts/*"
                docker exec -i -u oracle -e STAGE_DIR="$STAGE_DIR" -e OGG_HOME="$OGG_HOME" $OGG_CONTAINER bash -c './tmp/install_scripts/runInstaller.sh'
                '''
            }
        }

        stage('Create Deployment') {
            steps {
                sh '''
                echo "Creating GoldenGate deployment..."
        
                docker exec -i -u oracle -e OGG_HOME="$OGG_HOME" $OGG_CONTAINER bash -c "
                  export OGG_HOME=${OGG_HOME}
                  export PATH=\$OGG_HOME/bin:\$PATH
                
                  cat > /tmp/ogg_deploy.rsp <<EOF
DEPLOYMENT_NAME=$OGG_DEPLOY_NAME
ADMINISTRATOR_USER=$deploy_username
ADMINISTRATOR_PASSWORD=$deploy_password
SERVICE_MANAGER_PORT=$port_number
OGG_HOME=$OGG_HOME
EOF
                
                  echo '==== Final Deployment Response File ===='
                  cat /tmp/ogg_deploy.rsp
                  echo '========================================'
                
                  \$OGG_HOME/bin/oggca.sh -silent -responseFile /tmp/ogg_deploy.rsp
                "
                '''
            }
        }

        stage('Configure Trails & Networking') {
            steps {
                sh """
                echo "Starting ServiceManager and connecting..."

                docker exec -i -u oracle $OGG_CONTAINER bash -c \"
                  export OGG_HOME=/u02/ogg/ogg_home
                  export PATH=\\\$OGG_HOME/bin:\\\$PATH

                  \$OGG_HOME/bin/ServiceManager start
                  sleep 5

                  echo -e \\\"connect http://localhost:$port_number DEPLOYMENT $OGG_DEPLOY_NAME USER $deploy_username PASSWORD $deploy_password\\\\ninfo all\\\\nexit\\\" | \$OGG_HOME/bin/adminclient
                \"
                """
            }
        }
      }

    post {
        always {
            echo 'Cleaning workspace...'
            /*sh'''
            docker stop $OGG_CONTAINER || true
            docker rm -f $OGG_CONTAINER || true
            docker volume rm $OGG_VOLUME || true
            '''*/
            cleanWs()
        }
    }
}
