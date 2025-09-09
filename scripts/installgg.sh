#!/bin/bash
set -e

# Required environment variables: OGG_HOME, STAGE_DIR, ORA_BASE (optional)
: "${OGG_HOME:?Environment variable OGG_HOME must be set}"
: "${STAGE_DIR:?Environment variable STAGE_DIR must be set}"
: "${ORA_BASE:?Environment variable ORA_BASE must be set}"   # Default base if not provided
: "${ORA_INV:?Environment variable ORA_INV must be set}" # Default inventory location

export PATH=${OGG_HOME}/bin:$PATH

# Dynamically find installer
installer=$(find "${STAGE_DIR}" -type f -name runInstaller | head -n 1)
if [ -z "$installer" ]; then
  echo "ERROR: Missing installer file in STAGE_DIR=${STAGE_DIR}"
  exit 1
fi

# Use the directory containing the installer as working directory
installer_dir=$(dirname "$installer")
cd "$installer_dir"

./runInstaller -silent \
  oracle.install.option=OGGCORE \
  INSTALL_TYPE=GG_MICROSERVICES \
  ORACLE_BASE=/u02/ogg \
  INVENTORY_LOCATION=/u02/oraInventory \
  SOFTWARE_LOCATION=/u02/ogg/ggs_home \
  UNIX_GROUP_NAME=oinstall \
  INSTALL_OPTION=ORA21c \
  DECLINE_SECURITY_UPDATES=true \
  ACCEPT_LICENSE_AGREEMENT=true

sleep 20