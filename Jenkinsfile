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
                docker cp scripts/pre-requisites-for-goldengate.sql $src_CN:/tmp/pre-requisite-params.sql
                docker exec $src_CN bash "
                echo 'Connecting to PDB $src_PDB in CDB
                sqlplus / as sysdba <<EOF
                @/tmp/pre-requisite-params.sql
                exit;
                "
                '''

                // DEST - Pre-requisite commands to be run on destination DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                echo "Running Pre-requisites for Golden-Gate Deploy on Destination DB in container $dest_CN"
                docker cp scripts/pre-requisites-for-goldengate.sql $dest_CN:/tmp/pre-requisite-params.sql
                docker exec $dest_CN bash "
                echo 'Connecting to PDB $dest_PDB in CDB
                sqlplus / as sysdba <<EOF
                @/tmp/pre-requisite-params.sql
                exit;
                "
                '''
           }
        }
    }
}