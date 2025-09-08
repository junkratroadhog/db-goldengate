#!/bin/bash
set -e

# Required environment variables: OGG_HOME, STAGE_DIR, ORA_BASE (optional)
: "${PORT:?Environment variable PORT must be set}"
: "${OGG_DEPLOY_NAME:?Environment variable OGG_DEPLOY_NAME must be set}"
: "${deploy_username:=oggadmin}"   # Default base if not provided
: "${deploy_password:=oracle}" # Default inventory location

export PATH=$OGG_HOME/bin:$PATH

$OGG_HOME/bin/ServiceManager start
sleep 5
echo -e "connect http://localhost:${PORT} DEPLOYMENT ${OGG_DEPLOY_NAME} USER ${deploy_username} PASSWORD ${deploy_password}\ninfo all\nexit" | $OGG_HOME/bin/adminclient
