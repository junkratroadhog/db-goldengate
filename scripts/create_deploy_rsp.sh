#!/bin/bash
set -e

: "${OGG_DEPLOY_NAME:?Environment variable OGG_DEPLOY_NAME must be set}"
: "${DEPLOY_USERNAME:?Environment variable DEPLOY_USERNAME must be set}"
: "${DEPLOY_PASSWORD:?Environment variable DEPLOY_PASSWORD must be set}"
: "${SM_PORT:?Environment variable SM_PORT must be set}"
: "${AM_PORT:?Environment variable AM_PORT must be set}"
: "${OGG_HOME:?Environment variable OGG_HOME must be set}"

mkdir -p ${OGG_HOME}/var

cat > /tmp/install_scripts/ogg_deploy.rsp <<EOF
DEPLOYMENT_NAME=${OGG_DEPLOY_NAME}
ADMINISTRATOR_USERNAME=${DEPLOY_USERNAME}
ADMINISTRATOR_PASSWORD=${DEPLOY_PASSWORD}
SERVICE_MANAGER_LISTENER_PORT=${SM_PORT}
ADMIN_SERVER_LISTENER_PORT=${AM_PORT}
DEPLOYMENT_HOME=${OGG_HOME}/var
EOF

echo "Response file created at /tmp/install_scripts/ogg_deploy.rsp"