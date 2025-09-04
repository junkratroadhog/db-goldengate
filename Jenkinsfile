pipeline {
    agent any

    environment {
        src_CDB = 'USERSDB'
        src_CN  = 'db-users'
        src_PDB = 'USERS_PDB'

        dest_CDB = 'DETAILSDB'
        dest_CN  = 'db-details'
        dest_PDB = 'DETAILS_PDB'
    }

    stages {

        stage('Pre-requisites for Golden-Gate Deploy') {
            steps {
                // SRC - Pre-requisite commands to be run on source DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                echo "Running Pre-requisites for Golden-Gate Deploy on Source DB in container $src_CN"
                docker cp scripts/pre-requisites-for-goldengate.sql $src_CN:/tmp/pre-requisites-for-goldengate.sql
                docker exec $src_CN bash "
                echo 'Connecting to PDB $src_PDB in CDB
                sqlplus / as sysdba <<EOF
                @/tmp/pre-requisites-for-goldengate.sql
                exit;
                "
                '''

                // DEST - Pre-requisite commands to be run on destination DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                echo "Running Pre-requisites for Golden-Gate Deploy on Destination DB in container $dest_CN"
                docker cp scripts/pre-requisites-for-goldengate.sql $dest_CN:/tmp/pre-requisites-for-goldengate.sql
                docker exec $dest_CN bash "
                echo 'Connecting to PDB $dest_PDB in CDB
                sqlplus / as sysdba <<EOF
                @/tmp/pre-requisites-for-goldengate.sql
                exit;
                "
                '''
           }

//        stage('Create GG Users') {
            
        
    //    }
    }
}
