#!/bin/bash
set -e
$OGG_HOME/bin/ServiceManager start
sleep 5
echo -e "connect http://localhost:$port_number DEPLOYMENT $OGG_DEPLOY_NAME USER $deploy_username PASSWORD $deploy_password\ninfo all\nexit" | $OGG_HOME/bin/adminclient
