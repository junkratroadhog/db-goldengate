pipeline {
  agent any

  parameters {
    string(name: 'OGG_VOLUME', defaultValue: 'ogg_users_detail_vol', description: 'ogg_users_detail_vol')
    string(name: 'OGG_CONTAINER', defaultValue: 'ogg-users_detail', description: 'ogg-users_detail')
    string(name: 'STAGE_DIR', defaultValue: '/tmp/binaries', description: 'Staging directory inside container')
    string(name: 'GG_NETWORK', defaultValue: 'GG_NET', description: 'GG_NET')
    string(name: 'GG_binary', defaultValue: 'gg_binary.zip', description: 'gg_binary.zip')
    string(name: 'MS_binary', defaultValue: 'ms_binary.zip', description: 'ms_binary.zip')
    string(name: 'OGG_HOME', defaultValue: '/u02/ogg/ggs_home', description: '/u02/ogg/ggs_home')
    string(name: 'OGG_HOME_CORE', defaultValue: '/u02/ogg/ggs_home/ggs_home_core', description: '/u02/ogg/ggs_home/ggs_home_core')
    string(name: 'OGG_HOME_MS', defaultValue: '/u02/ogg/ggs_home/ggs_home_ms', description: '/u02/ogg/ggs_home/ggs_home_ms')
    string(name: 'TNS_ADMIN', defaultValue: '/u02/ogg/network/admin', description: '/u02/ogg/network/admin')
  }

  stages {

    stage ('Deploy GG Container') {
      steps {
        sh """
          # Remove old container if exists
          if docker ps -a --format '{{.Names}}' | grep -q "^${params.OGG_CONTAINER}\$"; then

            docker stop ${params.OGG_CONTAINER}
            docker run --rm -v ${params.OGG_VOLUME}:${params.OGG_HOME} alpine sh -c "rm -rf ${params.OGG_HOME}/*"
            docker run --rm -v ${params.OGG_VOLUME}:${params.OGG_HOME_CORE} alpine sh -c "rm -rf ${params.OGG_HOME_CORE}/*"
            docker run --rm -v ${params.OGG_VOLUME}:${params.OGG_HOME_MS} alpine sh -c "rm -rf ${params.OGG_HOME_MS}/*"
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

          # Create GG VOLUME
          if ! docker volume inspect ${params.OGG_VOLUME} > /dev/null 2>&1; then
            docker volume create ${params.OGG_VOLUME}
          fi
          
          docker network create ${params.GG_NETWORK}

          # Start new GG container
          docker run -d \
          --name ${params.OGG_CONTAINER} \
          --hostname ${params.OGG_CONTAINER}.gg.com \
          -v ${params.OGG_VOLUME}:${params.OGG_HOME} \
          oraclelinux:8 tail -f /dev/null
        """
      }
    }

    stage('Create Oracle User') {
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

    stage('Copy scripts') {
      steps {
        sh '''
        docker exec -i $OGG_CONTAINER bash -c "mkdir -p /tmp/install_scripts && chown oracle:oinstall /tmp/install_scripts && chmod 775 /tmp/install_scripts"                
        docker cp scripts/. $OGG_CONTAINER:/tmp/install_scripts
        '''
      }
    }

    stage('Setup Global Env') {
      steps {
        sh """
          # Prepare directories with correct ownership
          docker exec -i -u root ${params.OGG_CONTAINER} bash -c "
            mkdir -p ${params.OGG_HOME} ${params.STAGE_DIR} ${params.TNS_ADMIN} ${params.OGG_HOME_CORE} ${params.OGG_HOME_MS}
            chown -R oracle:oinstall ${params.OGG_HOME} ${params.STAGE_DIR} ${params.TNS_ADMIN} ${params.OGG_HOME_CORE} ${params.OGG_HOME_MS}
            chmod 775 ${params.OGG_HOME} ${params.STAGE_DIR} ${params.TNS_ADMIN} ${params.OGG_HOME_CORE} ${params.OGG_HOME_MS}
          "

          docker exec -i -u root ${params.OGG_CONTAINER} bash -c '
            echo "export OGG_HOME=${params.OGG_HOME}" >> /etc/profile.d/ogg.sh
            echo "export OGG_HOME_CORE=${params.OGG_HOME_CORE}" > /etc/profile.d/ogg.sh
            echo "export OGG_HOME_MS=${params.OGG_HOME_MS}" >> /etc/profile.d/ogg.sh
            echo "export TNS_ADMIN=${params.TNS_ADMIN}" >> /etc/profile.d/ogg.sh
            chmod +x /etc/profile.d/ogg.sh
          '
        """
      }
    }

    stage('Verify Env') {
      steps {
        sh """
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -l -c '
          echo OGG_HOME_CORE=\$OGG_HOME_CORE
          echo OGG_HOME_MS=\$OGG_HOME_MS
          echo PATH=\$PATH
        '
        """
      }
    }

    stage('Install Dependencies and Unzip Binaries') {
      steps {
        sh """
            echo "Using existing GoldenGate binary: ${params.GG_binary} and Microservices binary: ${params.MS_binary}"


  
          # Copy GG binary zip into container and set permissions
          docker cp /software/${params.GG_binary} ${params.OGG_CONTAINER}:${params.STAGE_DIR}/${params.GG_binary}
          docker exec -i -u root -e STAGE_DIR="${params.STAGE_DIR}" -e OGG_HOME_CORE="${params.OGG_HOME_CORE}" ${params.OGG_CONTAINER} bash -c "chown oracle:oinstall ${params.STAGE_DIR}/${params.GG_binary} && chmod 777 ${params.STAGE_DIR}/${params.GG_binary}"

          # Copy MS binary zip into container and set permissions
          docker cp /software/${params.MS_binary} ${params.OGG_CONTAINER}:${params.STAGE_DIR}/${params.MS_binary}
          docker exec -i -u root -e STAGE_DIR="${params.STAGE_DIR}" -e OGG_HOME_MS="${params.OGG_HOME_MS}" ${params.OGG_CONTAINER} bash -c "chown oracle:oinstall ${params.STAGE_DIR}/${params.MS_binary} && chmod 777 ${params.STAGE_DIR}/${params.MS_binary}"


          #docker exec -i -u root ${params.OGG_CONTAINER} bash -c '
          #  if ! command -v hostname >/dev/null 2>&1; then
          #    echo "Installing hostname..."
          #    yum install -y hostname
          #  else
          #    echo "hostname already installed"
          #  fi
          #'

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
            unzip -q -o ${params.STAGE_DIR}/${params.GG_binary} -d ${params.STAGE_DIR}/.
            unzip -q -o ${params.STAGE_DIR}/${params.MS_binary} -d ${params.STAGE_DIR}/.
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