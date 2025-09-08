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
        sh '''
          # Remove old container if exists
          if docker ps -a --format '{{.Names}}' | grep -q "^$OGG_CONTAINER\$"; then
            docker stop $OGG_CONTAINER
            docker run --rm -v $OGG_VOLUME:$OGG_HOME alpine sh -c "rm -rf $OGG_HOME/*"
            docker rm -f $OGG_CONTAINER
            docker volume rm $OGG_VOLUME
          fi

          if ! docker volume inspect $OGG_VOLUME > /dev/null 2>&1; then
            docker volume create $OGG_VOLUME
          fi

          # Start new GG container
          docker run -d --name $OGG_CONTAINER -v $OGG_VOLUME:/u02/ogg oraclelinux:8 tail -f /dev/null                
        '''
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