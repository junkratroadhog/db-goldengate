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
rsp_file=$(find "$STAGE_DIR" -type f -name "ogg*.rsp" | head -n 1)

# Run installer in silent mode
if [ -z "$rsp_file" ]; then
  echo "Running installer without response file"
  $installer -silent \
    ORACLE_BASE="$ORA_BASE" \
    INVENTORY_LOCATION="$ORA_INV" \
    UNIX_GROUP_NAME=oinstall \
    DECLINE_SECURITY_UPDATES=true \
    ACCEPT_LICENSE_AGREEMENT=true
else
  echo "Running installer using response file: $rsp_file"
  $installer -silent -responseFile "$rsp_file" \
    ORACLE_BASE="$ORA_BASE" \
    INVENTORY_LOCATION="$ORA_INV" \
    UNIX_GROUP_NAME=oinstall \
    DECLINE_SECURITY_UPDATES=true \
    ACCEPT_LICENSE_AGREEMENT=true
fi
