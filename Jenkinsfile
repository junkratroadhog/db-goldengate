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