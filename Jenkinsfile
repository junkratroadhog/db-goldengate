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
    ORA_BASE = '/u02/ogg'
    ORA_INV = '/u02/oraInventory'

    // Goldengate Deployment parameters
    OGG_DEPLOY_NAME = 'ogg_deploy-Users-Detail'
    deploy_username = 'oggadmin'
    deploy_password = 'oracle'
    PORT   = 7809
    INSTALL_TYPE = 'ORA21c'

    New_CN = 'yes' // yes/no - Whether to create a new container or use existing one
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

    stage('Deploy GG Container') {
      steps {
        script {
          if (env.New_CN == "yes") {
            echo "New_CN is yes → running gg-deploy job to redeploy GG container..."
            build job: 'gg-deploy',
              parameters: [
                string(name: 'OGG_VOLUME', value: env.OGG_VOLUME),
                string(name: 'OGG_CONTAINER', value: env.OGG_CONTAINER),
                string(name: 'OGG_HOME', value: env.OGG_HOME),
                string(name: 'OGG_binary', value: env.OGG_binary),
                string(name: 'STAGE_DIR', value: env.STAGE_DIR),
              ]
          } 
          
          else {
            echo "New_CN is not yes → checking existing container..."
            def containerExists = sh(
              script: "docker ps -a --format '{{.Names}}' | grep -w ${env.OGG_CONTAINER} || true",
              returnStdout: true
            ).trim()
    
            if (containerExists) {
              def containerRunning = sh(
                script: "docker ps --format '{{.Names}}' | grep -w ${env.OGG_CONTAINER} || true",
                returnStdout: true
              ).trim()
    
              if (containerRunning) {
                echo "Container ${env.OGG_CONTAINER} is already running → reusing it."
              } else {
                echo "Container ${env.OGG_CONTAINER} exists but is stopped → starting it."
                sh "docker start ${env.OGG_CONTAINER}"
              }
            } else {
              error "Container ${env.OGG_CONTAINER} does not exist and New_CN is not yes → cannot continue."
            }
          }
        }
      }
    }

    stage('Create Oracle User and Copy scripts') {
      steps {
        sh '''
        docker exec -i $OGG_CONTAINER bash -c "mkdir -p /tmp/install_scripts && chown oracle:oinstall /tmp/install_scripts && chmod 775 /tmp/install_scripts"                
        docker cp scripts/. $OGG_CONTAINER:/tmp/install_scripts
        '''
      }
    }



    stage ('Copy & Install GoldenGate') {
      steps {
        sh """
          # Create oraInst.loc
          docker exec -i -u root ${OGG_CONTAINER} bash -c "
            echo 'inventory_loc=/u02/oraInventory' > /etc/oraInst.loc
            echo 'inst_group=oinstall' >> /etc/oraInst.loc
            chown oracle:oinstall /etc/oraInst.loc
          "
          if [ -d "\$OGG_HOME" ]; then
              echo "Cleaning existing OGG_HOME: \$OGG_HOME"
              rm -rf "\$OGG_HOME"
          fi

          docker exec -i -u oracle ${OGG_CONTAINER} bash -c "mkdir -p \$OGG_HOME && chown oracle:oinstall \$OGG_HOME && chmod 775 \$OGG_HOME"

          # Run GG INSTALLER as oracle user
          docker exec -i ${OGG_CONTAINER} bash -c "chmod +x /tmp/install_scripts/*"
          "
        """
      }
    }

    /*stage('Configure Trails & Networking') {
      steps {
        sh """
          docker exec -i -u oracle \
            -e PORT=${PORT} \
            -e OGG_DEPLOY_NAME=${OGG_DEPLOY_NAME} \
            -e deploy_username=${deploy_username} \
            -e deploy_password=${deploy_password} \
          ${OGG_CONTAINER} bash -lc "./tmp/install_scripts/configureTN.sh"
        """
      }
    }
  }*/
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