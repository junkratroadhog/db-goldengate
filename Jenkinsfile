pipeline {
    agent any

    environment {
        src_CN  = 'db-utest'
        src_CDB = 'TUSERS'
        src_PDB = 'TUSERS_PDB'

        dest_CDB = 'TDETAILS'
        dest_CN  = 'db-dtest'
        dest_PDB = 'TDETAILS_PDB'
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
    }
}