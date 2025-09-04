pipeline {
    agent any

    environment {
        src_CDB = 'USERSDB'
        src_CN  = 'db-users'
        src_PDB = 'USERS_PDB'
        

        destination_PDB = 'DETAILS_PDB'
        s
    }

    stages {

        stage('Pre-requisites for Golden-Gate Deploy') {
            steps {
                // Pre-requisite commands to be run on source DB Force loggin enabled in CDB and Supplemental log data added in PDB
                sh '''
                docker cp scripts/pre-requisites-for-goldengate.sql $src_CN:/tmp/pre-requisites-for-goldengate.sql
                docker exec $src_CN bash "
                echo 'Connecting to PDB $src_PDB in CDB
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