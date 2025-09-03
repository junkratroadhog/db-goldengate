pipeline {
    agent any

    environment {
        source_PDB = 'USERS_PDB'
        destination_PDB = 'DETAILS_PDB'
        table = ''
        schema = ''
        SRCCN = ''
        DESTCN = ''
    }

    stages {

        stage('Retrieve the DB Name') {
            steps {
                    SRCCN = sh(
                        script: "docker ps --filter 'ancestor=gvenzl/oracle-xe' --format '{{.Names}}' | head -n1",
                        returnStdout: true
                    ).trim()
           }
        }
    }
}