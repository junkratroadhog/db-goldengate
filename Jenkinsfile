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
        OGG_binary = 'gg_binary.zip'
    }

    stages {

        stage('Pre-requisites for Golden-Gate Deploy') {
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
        }

        stage('Extract & Run Goldengate Installer') {
            steps {
                sh '''
                echo "Using existing GoldenGate binary: $OGG_binary"
                pwd
                ls -ltr 
                ls -ltr /tmp
                docker exec my-jenkins ls -ltr /tmp
                docker cp /tmp/gg_binary.zip my-jenkins:/var/jenkins_home/workspace/deploy-goldengate/$OGG_binary

                # Ensure the ZIP exists
                if [ ! -f $OGG_binary ]; then
                    echo "ERROR: $OGG_binary not found in workspace!"
                    exit 1
                fi

                # Unzip the archive
                unzip -o $OGG_binary -d ogg_binary

                # Find the installer recursively
                installer=$(find ogg_binary/ -type f -name "runInstaller" | head -n 1)

                if [ -z "$installer" ]; then
                    echo "ERROR: runInstaller not found!"
                    exit 1
                fi

                echo "Installer found at: $installer"

                # Make it executable and run
                chmod +x "$installer"
                "$installer"
                '''
            }
        }

        /*stage ('Prepare GG Container') {
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
        }*/
    }
}
