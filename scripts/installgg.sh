#!/bin/bash
set -e

# Required environment variables
: "${OGG_HOME:?OGG_HOME must be set}"
: "${STAGE_DIR:?STAGE_DIR must be set}"
: "${ORA_BASE:?ORA_BASE must be set}"
: "${ORA_INV:?ORA_INV must be set}"

export PATH=${OGG_HOME}/bin:$PATH

# Function to run installer from a given extracted directory
install_from_dir() {
  local dir=$1
  local install_type=$2

  installer=$(find "$dir" -type f -name runInstaller | head -n 1)
  if [ -z "$installer" ]; then
    echo "ERROR: runInstaller not found under $dir"
    exit 1
  fi

  installer_dir=$(dirname "$installer")
  cd "$installer_dir"

  echo ">>> Running installer [$install_type] from $installer_dir"

  ./runInstaller -silent \
    oracle.install.option=OGGCORE \
    INSTALL_TYPE=$install_type \
    ORACLE_BASE=$ORA_BASE \
    INVENTORY_LOCATION=$ORA_INV \
    SOFTWARE_LOCATION=$OGG_HOME \
    UNIX_GROUP_NAME=oinstall \
    INSTALL_OPTION=ORA21c \
    DECLINE_SECURITY_UPDATES=true \
    ACCEPT_LICENSE_AGREEMENT=true
}

# Find extracted GG and MS directories
GG_DIR=$(find "${STAGE_DIR}" -maxdepth 1 -type d -name "fbo_ggs_Linux*" | head -n 1)
MS_DIR=$(find "${STAGE_DIR}" -maxdepth 1 -type d -name "fbo_ggs_ms_*" | head -n 1)

if [ -z "$GG_DIR" ] || [ -z "$MS_DIR" ]; then
  echo "ERROR: Could not find extracted GoldenGate directories under ${STAGE_DIR}"
  exit 1
fi

# Install Classic (Core)
install_from_dir "$GG_DIR" OGGCLASSIC

# Install Microservices
install_from_dir "$MS_DIR" GG_MICROSERVICES

echo ">>> GoldenGate Classic + Microservices installed successfully!"
