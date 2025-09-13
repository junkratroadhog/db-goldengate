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
    OGG_HOME_CORE = '/u02/ogg/ggs_home/ggs_home_core'
    OGG_HOME_MS = '/u02/ogg/ggs_home/ggs_home_ms'
    STAGE_DIR = '/tmp/binaries'
    ORA_BASE = '/u02/ogg'
    ORA_INV = '/u02/oraInventory'
    INSTALL_TYPE = 'ORA21c'
    TABLE_NAME = 'employees'
    TNS_ADMIN = '/u02/ogg/ggs_home/network/admin'

    // GoldenGate binaries (must exist in /software inside Jenkins container)
    GG_binary    = 'gg_binary.zip'
    MS_binary     = 'ms_binary.zip'

    // Goldengate Deployment parameters
    OGG_DEPLOY_NAME = 'ogg_deploy-Users-Detail'
    deploy_username = 'oggadmin'
    deploy_password = 'oracle'
    AM_PORT = 7809
    SM_PORT = 9000
    GG_NETWORK = 'GG_NET'

    New_CN = 'yes' // yes/no - Whether to create a new container or use existing one
  }

  stages {

    stage('Deploy GG Container') {
      steps {
        script {
          if (env.New_CN == "yes") {
            echo "New_CN is yes → running gg-deploy job to redeploy GG container..."
            build job: 'gg-deploy',
              parameters: [
                string(name: 'OGG_VOLUME', value: env.OGG_VOLUME),
                string(name: 'OGG_CONTAINER', value: env.OGG_CONTAINER),
                string(name: 'OGG_HOME_CORE', value: env.OGG_HOME_CORE),
                string(name: 'OGG_HOME_MS', value: env.OGG_HOME_MS),
                string(name: 'STAGE_DIR', value: env.STAGE_DIR),
                string(name: 'GG_NETWORK', value: env.GG_NETWORK),
                string(name: 'MS_binary', value: env.MS_binary),
                string(name: 'GG_binary', value: env.GG_binary),
                string(name: 'TNS_ADMIN', value: env.TNS_ADMIN),
                string(name: 'ORA_INV', value: env.ORA_INV)
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

    stage('Copy scripts') {
      steps {
        sh '''
        docker exec -i $OGG_CONTAINER bash -c "mkdir -p /tmp/install_scripts && chown oracle:oinstall /tmp/install_scripts && chmod 775 /tmp/install_scripts"                
        docker cp scripts/. $OGG_CONTAINER:/tmp/install_scripts
        '''
      }
    }



    stage ('Install GoldenGate + Microservices') {
      steps {
        sh """
          echo "==== Preparing for GoldenGate Installation ===="

          # Create oraInst.loc for Oracle Inventory
          docker exec -i -u root ${env.OGG_CONTAINER} bash -c "
            echo 'inventory_loc=${env.ORA_INV}' > /etc/oraInst.loc
            echo 'inst_group=oinstall' >> /etc/oraInst.loc
            chown oracle:oinstall /etc/oraInst.loc
          "

          # Prepare OGG_HOME_CORE and OGG_HOME_MS directories
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -c "mkdir -p ${env.OGG_HOME_CORE} && chmod 775 ${env.OGG_HOME_CORE}"
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -c "mkdir -p ${env.OGG_HOME_MS} && chmod 775 ${env.OGG_HOME_MS}"
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -c "chown -R oracle:oinstall ${env.OGG_HOME_CORE} ${env.OGG_HOME_MS}"

          # Ensure install script is present and executable
          docker exec -i ${env.OGG_CONTAINER} bash -c "
            if [ ! -f /tmp/install_scripts/installgg.sh ]; then
              echo 'ERROR: installgg.sh not found in /tmp/install_scripts'
              exit 1
            fi
            chmod +x /tmp/install_scripts/installgg.sh
          "

          echo "==== Starting Silent Install of GoldenGate Classic + Microservices ===="

          # Run install script as oracle user with both binaries passed
          docker exec -i -u oracle \
            -e ORA_BASE=${env.ORA_BASE} \
            -e ORA_INV=${env.ORA_INV} \
            -e OGG_HOME_CORE=${env.OGG_HOME_CORE} \
            -e OGG_HOME_MS=${env.OGG_HOME_MS} \
            -e STAGE_DIR=${env.STAGE_DIR} \
            -e GG_binary=${env.GG_binary} \
            -e MS_binary=${env.MS_binary} \
            ${env.OGG_CONTAINER} bash -lc "/tmp/install_scripts/installgg.sh"

          echo "==== GoldenGate Installation Completed ===="
        """
      }
    }
    stage('Setup Core MGR Process') {
      steps {
        sh """
          echo "==== Setting up Core Manager Process ===="

          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -c '
            export OGG_HOME=${env.OGG_HOME_CORE}
            export PATH=\$OGG_HOME:\$PATH
            cd \$OGG_HOME

            # Create required directories
            mkdir -p dirprm dirchk dirdsc dirrpt dirlt dirout dirpcs dirdmp

            # Minimal mgr.prm
            cat > dirprm/mgr.prm <<EOF
PORT 7809
AUTOSTART ER *
EOF

            # Set permissions
            chmod -R 775 \$OGG_HOME

            # Start GGSCI commands using a subshell
            echo -e "INFO ALL\nSTART MGR\nEXIT" | \$OGG_HOME/ggsci
          '
        """
      }
    }

    stage('Validate Core MGR') {
      steps {
        sh """
          echo "==== Validating Core Manager ===="
          docker exec -i ${env.OGG_CONTAINER} bash -c '
            if pgrep -f "./mgr PARAMFILE" > /dev/null; then
              echo "==== Core Manager is RUNNING ===="
            else
              echo "==== ERROR: Core Manager FAILED to start ===="
              exit 1
            fi
          '
        """
      }
    }

    stage('Validate DB Containers') {
      steps {
        script {
          // ✅ Check if network exists
          def netExists = sh(
            script: "docker network ls --format '{{.Name}}' | grep -w ${env.GG_NETWORK} || true",
            returnStdout: true
          ).trim()

          if (!netExists) {
            error "Network ${env.GG_NETWORK} does not exist! Please create it during container build."
          } else {
            echo "Network ${env.GG_NETWORK} exists."
            sh "docker network connect ${env.GG_NETWORK} ${env.OGG_CONTAINER}"
          }

          // ✅ List of DB containers
          def dbs = ["db-dtest", "db-utest"]

          dbs.each { db ->
            echo "=== Checking DB Container: ${db} ==="

            // Check if container is running
            def running = sh(
              script: "docker ps --format '{{.Names}}' | grep -w ${db} || true",
              returnStdout: true
            ).trim()

            if (!running) {
              echo "${db} is not running → starting..."
              sh "docker start ${db}"
            } else {
              echo "${db} is already running."
            }

            // Check if attached to GG_NET
            def attached = sh(
              script: """docker inspect -f '{{json .NetworkSettings.Networks}}' ${db} | grep ${env.GG_NETWORK} || true""",
              returnStdout: true
            ).trim()

            if (!attached) {
              echo "Attaching ${db} to ${env.GG_NETWORK}..."
              sh "docker network connect ${env.GG_NETWORK} ${db} || true"
            } else {
              echo "${db} is already attached to ${env.GG_NETWORK}"
            }
          }
        }
      }
    }

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
        // SRC
        sh """
          docker cp scripts/oggadmin.sql ${env.src_CN}:/tmp/oggadmin.sql
          docker exec ${env.src_CN} sqlplus / as sysdba @/tmp/oggadmin.sql ${env.src_PDB} ${env.deploy_username} ${env.deploy_password}
        """

        // DEST
        sh """
          docker cp scripts/oggadmin.sql ${env.dest_CN}:/tmp/oggadmin.sql
          docker exec ${env.dest_CN} sqlplus / as sysdba @/tmp/oggadmin.sql ${env.dest_PDB} ${env.deploy_username} ${env.deploy_password}
        """
      }
    }

    stage('Add TNS Entries') {
      steps {
        script {
          def dbs = [
            [name: env.src_PDB, host: env.src_CN],
            [name: env.dest_PDB, host: env.dest_CN]
          ]

          dbs.each { db ->
            echo "Adding TNS entry for ${db.name} at ${db.host}"

            sh """
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -lc '
          ls -ltr \$TNS_ADMIN
          touch \$TNS_ADMIN/tnsnames.ora
          cat >> \$TNS_ADMIN/tnsnames.ora <<EOF
${db.name} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${db.host})(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = ${db.name})
    )
  )
EOF'
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -lc 'cat \$TNS_ADMIN/tnsnames.ora'
            """
          }
        }
      }
    }

    stage('Configure and Start GoldenGate Processes') {
      steps {
        script {
          echo "==== Setting up Extract and Replicat Processes ===="

          sh """
          docker exec -i -u oracle ${env.OGG_CONTAINER} bash -c '
            export OGG_HOME=${env.OGG_HOME_CORE}
            export PATH=\$OGG_HOME:\\$PATH
            cd \$OGG_HOME

            # Create directories if missing
            mkdir -p dirprm dirdat dirrpt

            cat > dirprm/ext1.prm <<EXT_EOF
EXTRACT ext1
USERID ${env.deploy_username}@"${env.src_CN}:1521/${env.src_PDB}", PASSWORD ${env.deploy_password}
EXTTRAIL ./dirdat/et
TABLE ${env.src_PDB}.${env.TABLE_NAME};
EXT_EOF


            cat > dirprm/rep1.prm <<REP_EOF
REPLICAT rep1
USERID ${env.deploy_username}@"${env.dest_CN}:1521/${env.dest_PDB}", PASSWORD ${env.deploy_password}
EXTTRAIL ./dirdat/et
MAP ${env.src_PDB}.${env.TABLE_NAME}, TARGET ${env.dest_PDB}.${env.TABLE_NAME};
REP_EOF

            \$OGG_HOME/ggsci <<GGSCI_EOF
dblogin userid ${env.deploy_username}, password ${env.deploy_password}
ADD CHECKPOINTTABLE ${env.deploy_username}.chkptab

ADD EXTRACT ext1, TRANLOG, BEGIN NOW
ADD EXTTRAIL ./dirdat/et EXTRACT ext1

ADD REPLICAT rep1, EXTTRAIL ./dirdat/et, CHECKPOINTTABLE ${env.deploy_username}.chkptab

START EXTRACT ext1
START REPLICAT rep1
INFO ALL
GGSCI_EOF
          '
          """
        }
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