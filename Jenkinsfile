pipeline {
    agent any

    environment {
        src_CN  = 'db-utest'
        src_CDB = 'TUSERS'
        src_PDB = 'TUSERS_PDB'

        dest_CDB = 'TDETAILS'
        dest_CN  = 'db-dtest'
        dest_PDB = 'TDETAILS_PDB'

        // GoldenGate environment
        OGG_VOLUME = 'ogg_users_detail_vol'
        OGG_CONTAINER = 'ogg-users_detail'
        OGG_HOME = '/u02/ogg/ogg_home'
        OGG_binary = 'gg_binary.zip' // This file has to be copied to my-jenkins docker container manually into /tmp/binaries/
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
                if ! docker volume inspect $OGG_VOLUME > /dev/null 2>&1; then
                    docker volume create $OGG_VOLUME
                fi

                # Remove old container if exists
                if docker ps -a --format '{{.Names}}' | grep -q "^$OGG_CONTAINER\$"; then
                    docker stop $OGG_CONTAINER
                    docker rm -f $OGG_CONTAINER
                fi

                # Start new GG container
                docker run -d --name $OGG_CONTAINER -v $OGG_VOLUME:/u02/ogg oraclelinux:8 tail -f /dev/null                
                '''
            }
        }

        stage ('Copy & Install GoldenGate') {
            steps {
                sh '''
                echo "Using existing GoldenGate binary: $OGG_binary"

                # Create oracle user + group if not exists
                docker exec -i -u root $OGG_CONTAINER bash -c "
                  getent group oinstall >/dev/null || groupadd -g 54321 oinstall
                  id -u oracle >/dev/null 2>&1 || useradd -u 54321 -g oinstall oracle
                "

                # Prepare directories with correct ownership
                docker exec -i -u root $OGG_CONTAINER bash -c "
                  mkdir -p /tmp/binaries /u02/ogg /u02/oraInventory
                  chown -R oracle:oinstall /tmp/binaries /u02/ogg /u02/oraInventory
                  chmod -R 775 /u02/ogg /u02/oraInventory
                "

                # Copy GG binary zip into container
                docker cp /tmp/binaries/$OGG_binary $OGG_CONTAINER:/tmp/binaries/$OGG_binary
                docker exec -i -u root $OGG_CONTAINER bash -c "chown oracle:oinstall /tmp/binaries/$OGG_binary"

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

                # Unzip as oracle
                docker exec -i -u oracle $OGG_CONTAINER bash -c "
                  unzip -o /tmp/binaries/$OGG_binary -d /tmp/binaries/ogg_binary
                "

                # Create oraInst.loc
                docker exec -i -u root $OGG_CONTAINER bash -c "
                  echo 'inventory_loc=/u02/oraInventory' > /etc/oraInst.loc
                  echo 'inst_group=oinstall' >> /etc/oraInst.loc
                  chown oracle:oinstall /etc/oraInst.loc
                "

                # Run installer as oracle
                docker exec -i -u oracle $OGG_CONTAINER bash -c '
                  set -e

                  OGG_HOME=/u02/ogg/ogg_home
                  STAGE_DIR=/tmp/binaries/ogg_binary

                  installer=$(find $STAGE_DIR -type f -name runInstaller | head -n 1)
                  rsp=$(find $STAGE_DIR -type f -name oggcore.rsp | head -n 1)

                  if [ -z "$installer" ] || [ -z "$rsp" ]; then
                    echo "ERROR: Missing installer or response file"
                    exit 1
                  fi

                  echo "Installer: $installer"
                  echo "Response : $rsp"

                  # Update response file with correct paths
                  sed -i \
                    -e "s#^SOFTWARE_LOCATION=.*#SOFTWARE_LOCATION=$OGG_HOME#" \
                    -e "s#^INVENTORY_LOCATION=.*#INVENTORY_LOCATION=/u02/oraInventory#" \
                    -e "s#^UNIX_GROUP_NAME=.*#UNIX_GROUP_NAME=oinstall#" \
                    "$rsp"

                  chmod +x "$installer"
                  cd "$(dirname "$installer")"

                  ./runInstaller -silent -waitforcompletion \
                    -responseFile "$rsp" \
                    -ignorePrereqFailure -invPtrLoc /etc/oraInst.loc

                  echo "export OGG_HOME=$OGG_HOME" >> /home/oracle/.bashrc
                  echo "export PATH=\\$OGG_HOME:\\$PATH" >> /home/oracle/.bashrc
                '
                '''
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
