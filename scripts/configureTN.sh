#!/bin/bash
set -e

# Required environment variables: OGG_HOME, STAGE_DIR, ORA_BASE (optional)
: "${PORT:?Environment variable PORT must be set}"
: "${OGG_DEPLOY_NAME:?Environment variable OGG_DEPLOY_NAME must be set}"
: "${deploy_username:?Environment variable deploy_username must be set}"   # Default base if not provided
: "${deploy_password:?Environment variable deploy_password must be set}" # Default inventory location

export PATH=$OGG_HOME/bin:$PATH
echo \$OGG_HOME

export OGG_HOME=${OGG_HOME}
echo \$OGG_HOME

$OGG_HOME/bin/ServiceManager start
sleep 5
echo -e "connect http://localhost:${PORT} DEPLOYMENT ${OGG_DEPLOY_NAME} USER ${deploy_username} PASSWORD ${deploy_password}\ninfo all\nexit" | $OGG_HOME/bin/adminclient
