pipeline {
  agent any

  parameters {
    string(name: 'OGG_VOLUME', defaultValue: 'ogg_users_detail_vol', description: 'ogg_users_detail_vol')
    string(name: 'OGG_CONTAINER', defaultValue: 'ogg-users_detail', description: 'ogg-users_detail')
    string(name: 'OGG_HOME', defaultValue: '/u02/ogg/ggs_home', description: '/u02/ogg/ggs_home')
    string(name: 'STAGE_DIR', defaultValue: '/tmp/binaries', description: 'Staging directory inside container')
    string(name: 'OGG_binary', defaultValue: 'gg_binary.zip', description: 'gg_binary.zip')
    string(name: 'GG_NETWORK', defaultValue: 'GG_NET', description: 'GG_NET')
  }

  stages {

    stage ('Deploy GG Container') {
      steps {
        sh """
          # Remove old container if exists
          if docker ps -a --format '{{.Names}}' | grep -q "^${params.OGG_CONTAINER}\$"; then

            docker stop ${params.OGG_CONTAINER}
            docker run --rm -v ${params.OGG_VOLUME}:${params.OGG_HOME} alpine sh -c "rm -rf ${params.OGG_HOME}/*"
            docker rm -f ${params.OGG_CONTAINER}
            docker volume rm ${params.OGG_VOLUME}
          fi

          # Remove old network if exists
          if docker network inspect ${params.GG_NETWORK} >/dev/null 2>&1; then
            for c in \$(docker ps -q --filter network=${params.GG_NETWORK}); do
              docker network disconnect -f ${params.GG_NETWORK} \$c || true
            done
            docker network rm ${params.GG_NETWORK} || true
          fi

          # Create network
          if ! docker volume inspect ${params.OGG_VOLUME} > /dev/null 2>&1; then
            docker volume create ${params.OGG_VOLUME}
          fi

          # Start new GG container
          docker run -d --name ${params.OGG_CONTAINER} \
          --hostname ${params.OGG_CONTAINER}.gg.com \
          -v ${params.OGG_VOLUME}:${params.OGG_HOME} \
          oraclelinux:8 tail -f /dev/null
        """
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
        '''
      }
    }

    stage('Setup Global Env') {
      steps {
        sh """
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -c 'mkdir -p ${params.OGG_HOME}'
        docker exec -i -u root ${params.OGG_CONTAINER} bash -c '
          echo "export OGG_HOME=${params.OGG_HOME}" > /etc/profile.d/ogg.sh
          echo "export PATH=\\\$OGG_HOME/bin:\\\$PATH" >> /etc/profile.d/ogg.sh
          chmod +x /etc/profile.d/ogg.sh
        '
        """
      }
    }

    stage('Verify Env') {
      steps {
        sh """
        # Works for login shells
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -l -c 'echo OGG_HOME=\$OGG_HOME; echo PATH=\$PATH'

        # Works for non-login shells too
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -c 'echo OGG_HOME=\$OGG_HOME; echo PATH=\$PATH'
        """
      }
    }

    stage('Install Dependencies and Unzip Binaries') {
      steps {
        sh """
            echo "Using existing GoldenGate binary: ${OGG_binary}"
  
          # Prepare directories with correct ownership
          docker exec -i -u root ${params.OGG_CONTAINER} bash -c "
            mkdir -p ${params.STAGE_DIR} /u02/ogg /u02/oraInventory
            chown -R oracle:oinstall ${params.STAGE_DIR} /u02/ogg /u02/oraInventory
            chmod -R 775 /u02/ogg /u02/oraInventory
          "
  
          # Copy GG binary zip into container
          docker cp /software/${params.OGG_binary} ${params.OGG_CONTAINER}:${params.STAGE_DIR}/${params.OGG_binary}
          docker exec -i -u root -e STAGE_DIR="${params.STAGE_DIR}" -e OGG_HOME="${params.OGG_HOME}" ${params.OGG_CONTAINER} bash -c "chown oracle:oinstall ${params.STAGE_DIR}/${params.OGG_binary} && chmod 777 ${params.STAGE_DIR}/${params.OGG_binary}"
  
          docker exec -i -u root ${params.OGG_CONTAINER} bash -c '
            if ! command -v unzip >/dev/null 2>&1; then
              echo "Installing unzip..."
              yum install -y -q unzip
            else
              echo "unzip already installed"
            fi
          '
  
          # Install required Java packages
          docker exec -i -u root ${params.OGG_CONTAINER} bash -c '
          yum install -y -q libnsl libaio glibc libX11 libXau libxcb libXi libXtst libXrender libXext libstdc++ ksh gcc gcc-c++ make
          '
          
          # Unzip Binaries as oracle
          docker exec -i -u oracle ${params.OGG_CONTAINER} bash -c "
            unzip -q -o ${params.STAGE_DIR}/${params.OGG_binary} -d ${params.STAGE_DIR}/.
          "
        """
      }
    }
  }
  
  post {
    always {
      echo 'Cleaning workspace...'
      /*sh"""
      docker stop ${params.OGG_CONTAINER} || true
      docker rm -f ${params.OGG_CONTAINER} || true
      docker volume rm ${params.OGG_VOLUME} || true
      """*/
      cleanWs()
    }
  }
}