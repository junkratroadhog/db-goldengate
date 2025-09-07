#!/bin/bash
set -e

# Required environment variables: OGG_HOME, STAGE_DIR, ORA_BASE (optional)
: "${OGG_HOME:?Environment variable OGG_HOME must be set}"
: "${STAGE_DIR:?Environment variable STAGE_DIR must be set}"
: "${ORA_BASE:=/u02/ogg}"   # Default base if not provided
: "${ORA_INV:=/u02/oraInventory}" # Default inventory location

export PATH=$OGG_HOME/bin:$PATH

# Dynamically find installer
installer=$(find "$STAGE_DIR" -type f -name runInstaller | head -n 1)
if [ -z "$installer" ]; then
  echo "ERROR: Missing installer file in STAGE_DIR=$STAGE_DIR"
  exit 1
fi

# Use the directory containing the installer as working directory
installer_dir=$(dirname "$installer")
cd "$installer_dir"

# Dynamically find response file (if any)
rsp_file=$(find "/tmp" -type f -name "ogg*.rsp" | head -n 1)

# If response file exists
if [ -n "$rsp_file" ]; then
    # Patch INSTALL_TYPE dynamically
    sed -i 's|^#*INSTALL_TYPE=.*|INSTALL_TYPE=GG_MICROSERVICES|' "$rsp_file"
    $installer -silent -responseFile "$rsp_file" \
        oracle.install.option=OGGCORE \
        ORACLE_BASE="$ORA_BASE" \
        INVENTORY_LOCATION="$ORA_INV" \
        UNIX_GROUP_NAME=oinstall \
        DECLINE_SECURITY_UPDATES=true \
        ACCEPT_LICENSE_AGREEMENT=true \
        INSTALL_OPTION=ORA21c \
        SOFTWARE_LOCATION="$OGG_HOME"
else
    $installer -silent \
        oracle.install.option=OGGCORE \
        ORACLE_BASE="$ORA_BASE" \
        INVENTORY_LOCATION="$ORA_INV" \
        UNIX_GROUP_NAME=oinstall \
        DECLINE_SECURITY_UPDATES=true \
        ACCEPT_LICENSE_AGREEMENT=true \
        INSTALL_OPTION=ORA21c \
        SOFTWARE_LOCATION="$OGG_HOME"
fi
