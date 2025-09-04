pipeline {
    agent any

    environment {
        src_CN  = 'db-utest'
        src_CDB = 'TUSERS'
        src_PDB = 'TUSERS_PDB'

        dest_CDB = 'TDETAILS'
        dest_CN  = 'db-dtest'
        dest_PDB = 'TDETAILS_PDB'

        # GoldenGate environment
        OGG_VOLUME = 'ogg_users_detail_vol'
        OGG_CONTAINER = 'ogg-users_detail'
        OGG_HOME = '/u02/ogg/ogg_home'
        OGG_ZIP = '/tmp/fbo_ggs_Linux_x64_Oracle_services_shiphome.zip'
        OGG_binary = 'https://drive.google.com/file/d/1fuUNJpBnC8bBuB9zRuwNvgzAFhVPlrUR/view?usp=drive_link'
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

        stage('Download & Extract Goldengate Binaries') {
            steps {
                sh '''
                echo "Downloading Goldengate Binaries"
                cd /tmp/

                # Set temporary zip file
                tmp_zip="/tmp/ogg_download_$$.zip"

                # Extract file ID from Google Drive link
                file_id=$(echo "$OGG_binary" | grep -o 'd/[^/]*' | cut -d'/' -f2)

                # Fetch confirmation token and download file
                confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate \
                "https://docs.google.com/uc?export=download&id=${file_id}" -O- | \
                sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p')

                wget --load-cookies /tmp/cookies.txt \
                "https://docs.google.com/uc?export=download&confirm=${confirm}&id=${file_id}" -O "$tmp_zip"

                # Clean up cookies
                rm -f /tmp/cookies.txt

                echo "Download completed: $tmp_zip"

                # Optionally, extract if needed
                unzip -o "$tmp_zip" -d /tmp/
                '''
            }
        }

        stage ('Prepare GG Container') {
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

            stage ('Install Golden-Gate Binaries') {
                sh '''
                docker cp /tmp/ogg_install
                '''
            }
            }
        }
    }
}
