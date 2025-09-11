#!/bin/bash
set -e

# Required environment variables
: "${STAGE_DIR:?Environment variable STAGE_DIR must be set}"
: "${ORA_BASE:?Environment variable ORA_BASE must be set}"
: "${ORA_INV:?Environment variable ORA_INV must be set}"
: "${OGG_HOME_CORE:?Environment variable OGG_HOME_CORE must be set}"
: "${OGG_HOME_MS:?Environment variable OGG_HOME_MS must be set}"

echo "==== Looking for GoldenGate installers under $STAGE_DIR ===="

# Find Classic GG installer dynamically
GG_INSTALLER=$(find "$STAGE_DIR" -type f -path "*/fbo_ggs_Linux_x64_Oracle_shiphome/Disk1/runInstaller" | head -n 1)
if [ -z "$GG_INSTALLER" ]; then
  echo "ERROR: Classic GoldenGate installer not found in $STAGE_DIR"
  exit 1
fi
echo "==== Found Classic Installer: $GG_INSTALLER ===="

# Find Microservices installer dynamically
MS_INSTALLER=$(find "$STAGE_DIR" -type f -path "*/fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/runInstaller" | head -n 1)
if [ -z "$MS_INSTALLER" ]; then
  echo "ERROR: Microservices installer not found in $STAGE_DIR"
  exit 1
fi
echo "==== Found Microservices Installer: $MS_INSTALLER ===="

# Install Classic GoldenGate Core
echo "==== Installing GoldenGate Classic Core ===="
cd "$(dirname "$GG_INSTALLER")"
./runInstaller -silent \
  oracle.install.option=OGGCORE \
  INSTALL_OPTION=ORA21c \
  SOFTWARE_LOCATION="$OGG_HOME_CORE" \
  ORACLE_BASE="$ORA_BASE" \
  INVENTORY_LOCATION="$ORA_INV" \
  UNIX_GROUP_NAME=oinstall \
  DECLINE_SECURITY_UPDATES=true \
  ACCEPT_LICENSE_AGREEMENT=true

sleep 15

echo "==== Classic GoldenGate installation complete ===="

# Install GoldenGate Microservices
echo "==== Installing GoldenGate Microservices ===="
cd "$(dirname "$MS_INSTALLER")"
./runInstaller -silent \
  INSTALL_TYPE=GG_MICROSERVICES \
  INSTALL_OPTION=ORA21c \
  SOFTWARE_LOCATION="$OGG_HOME_MS" \
  ORACLE_BASE="$ORA_BASE" \
  INVENTORY_LOCATION="$ORA_INV" \
  UNIX_GROUP_NAME=oinstall \
  DECLINE_SECURITY_UPDATES=true \
  ACCEPT_LICENSE_AGREEMENT=true

sleep 15

echo "==== Microservices installation complete ===="
