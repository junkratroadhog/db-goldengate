pipeline {
  agent any

  parameters {
    string(name: 'OGG_VOLUME', defaultValue: '', description: 'ogg_users_detail_vol')
    string(name: 'OGG_CONTAINER', defaultValue: '', description: 'ogg-users_detail')
    string(name: 'OGG_HOME', defaultValue: '', description: '/u02/ogg/ggs_home')
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

          if ! docker volume inspect ${params.OGG_VOLUME} > /dev/null 2>&1; then
            docker volume create ${params.OGG_VOLUME}
          fi

          # Start new GG container
          docker run -d --name ${params.OGG_CONTAINER} -v ${params.OGG_VOLUME}:${params.OGG_HOME} oraclelinux:8 tail -f /dev/null
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
        docker exec -i -u root ${params.OGG_CONTAINER} bash -c 'echo "OGG_HOME=${params.OGG_HOME}" >> /etc/environment && echo "PATH=\$OGG_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment'
        """
      }
    }

    stage('Verify Env') {
      steps {
        sh """
        # Run in a fresh login shell
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -l -c 'echo OGG_HOME=\$OGG_HOME; echo PATH=\$PATH'
        docker exec -i -u oracle ${params.OGG_CONTAINER} bash -c 'echo "export OGG_HOME=${params.OGG_HOME}" >> ~/.bashrc && echo "export PATH=${params.OGG_HOME}/bin:\$PATH" >> ~/.bashrc'
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