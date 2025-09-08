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

    // Goldengate Deployment parameters
    OGG_DEPLOY_NAME = 'ogg_deploy-Users-Detail'
    deploy_username = 'oggadmin'
    deploy_password = 'oracle'
    port_number   = '7809'
    INSTALL_TYPE = 'ORA21c'
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
        build job: 'branched-job-name',
          parameters: [
            string(name: 'OGG_VOLUME', value: env.OGG_VOLUME),
            string(name: 'OGG_CONTAINER', value: env.OGG_CONTAINER),
            string(name: 'OGG_HOME', value: env.OGG_HOME)
          ] 
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

    stage('Setup Global Env') {
        steps {
            sh """
            docker exec -i -u root $OGG_CONTAINER bash -c 'echo "OGG_HOME=${OGG_HOME}" >> /etc/environment && echo "PATH=${OGG_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment'
            """
        }
    }

    stage('Verify Env') {
        steps {
            sh """
            source /etc/environment || true
            # Run in a fresh login shell
            docker exec -i -u oracle $OGG_CONTAINER bash -l -c 'echo OGG_HOME=\$OGG_HOME; echo PATH=\$PATH'
            docker exec -i -u oracle $OGG_CONTAINER bash -c 'echo "export OGG_HOME=${OGG_HOME}" >> ~/.bashrc && echo "export PATH=${OGG_HOME}/bin:\$PATH" >> ~/.bashrc'

            """
        }
    }

    stage ('Copy & Install GoldenGate') {
      steps {
        sh '''
          echo "Using existing GoldenGate binary: $OGG_binary"

          # Prepare directories with correct ownership
          docker exec -i -u root $OGG_CONTAINER bash -c "
            mkdir -p ${STAGE_DIR} /u02/ogg /u02/oraInventory
            chown -R oracle:oinstall ${STAGE_DIR} /u02/ogg /u02/oraInventory
            chmod -R 775 /u02/ogg /u02/oraInventory
          "

          # Copy GG binary zip into container
          docker cp /software/$OGG_binary $OGG_CONTAINER:${STAGE_DIR}/$OGG_binary
          docker exec -i -u root -e STAGE_DIR="$STAGE_DIR" -e OGG_HOME="$OGG_HOME" $OGG_CONTAINER bash -c "chown oracle:oinstall ${STAGE_DIR}/$OGG_binary"

          docker exec -i -u root $OGG_CONTAINER bash -c '
            if ! command -v unzip >/dev/null 2>&1; then
              echo "Installing unzip..."
              yum install -y -q unzip
            else
              echo "unzip already installed"
            fi
          '

          # Install required Java packages
          docker exec -i -u root $OGG_CONTAINER bash -c '
          yum install -y -q libnsl libaio glibc libX11 libXau libxcb libXi libXtst libXrender libXext libstdc++ ksh gcc gcc-c++ make
          '
          
          # Unzip Binaries as oracle
          docker exec -i -u oracle $OGG_CONTAINER bash -c "
            unzip -q -o ${STAGE_DIR}/$OGG_binary -d ${STAGE_DIR}/${OGG_binary%.zip}
          "

          # Create oraInst.loc
          docker exec -i -u root $OGG_CONTAINER bash -c "
            echo 'inventory_loc=/u02/oraInventory' > /etc/oraInst.loc
            echo 'inst_group=oinstall' >> /etc/oraInst.loc
            chown oracle:oinstall /etc/oraInst.loc
          "
          if [ -d "$OGG_HOME" ]; then
              echo "Cleaning existing OGG_HOME: $OGG_HOME"
              rm -rf "$OGG_HOME"
          fi

          docker exec -i -u oracle $OGG_CONTAINER bash -c "mkdir -p $OGG_HOME && chown oracle:oinstall $OGG_HOME && chmod 775 $OGG_HOME"

          # Run GG INSTALLER as oracle user
          docker exec -i $OGG_CONTAINER bash -c "chmod +x /tmp/install_scripts/*"
          docker exec -i -u oracle -e STAGE_DIR="$STAGE_DIR" -e OGG_HOME="$OGG_HOME" $OGG_CONTAINER bash -c './tmp/install_scripts/runInstaller.sh'
        '''
      }
    }

    stage('Configure Trails & Networking') {
        steps {
            sh """
            docker exec -i -u oracle \
              -e PORT=${port_number} \
              -e DEPLOYMENT=${OGG_DEPLOY_NAME} \
              -e DEPLOY_USER=${deploy_username} \
              -e DEPLOY_PASS=${deploy_password} \
              ${OGG_CONTAINER} bash -l -c './tmp/install_scripts/configureTN.sh'
            """
        }
    }

    /*stage('TEST') {
        steps {
            sh """
            docker exec -i -u oracle $OGG_CONTAINER bash -l -c '
            echo \$OGG_HOME
            export PATH=\$OGG_HOME/bin:\$PATH
            echo \$PATH
            '
            """
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