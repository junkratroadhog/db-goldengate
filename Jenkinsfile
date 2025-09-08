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
        }

    stages {

        /*stage('Pre-requisites for Golden-Gate Deploy') {
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
                  '''
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

