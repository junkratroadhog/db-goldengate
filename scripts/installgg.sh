#!/bin/bash
set -e

: "${OGG_HOME:?Environment variable OGG_HOME must be set}"
: "${STAGE_DIR:?Environment variable STAGE_DIR must be set}"
: "${ORA_BASE:?Environment variable ORA_BASE must be set}"
: "${ORA_INV:?Environment variable ORA_INV must be set}"

echo "==== Looking for GoldenGate installers under ${STAGE_DIR} ===="

# Find GG Classic installer
gg_installer=$(find "${STAGE_DIR}" -type f -path "*/fbo_ggs_Linux_x64_Oracle_shiphome/Disk1/runInstaller" | head -n 1)
if [ -z "$gg_installer" ]; then
  echo "ERROR: GoldenGate Classic installer not found under ${STAGE_DIR}"
  exit 1
fi

# Find GG Microservices installer
ms_installer=$(find "${STAGE_DIR}" -type f -path "*/fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/runInstaller" | head -n 1)
if [ -z "$ms_installer" ]; then
  echo "ERROR: GoldenGate Microservices installer not found under ${STAGE_DIR}"
  exit 1
fi

echo "==== Found installers ===="
echo "Classic: $gg_installer"
echo "Microservices: $ms_installer"

echo "==== Installing GoldenGate Classic Core ===="
"$gg_installer" -silent \
  oracle.install.option=OGGCORE \
  ORACLE_BASE=$ORA_BASE \
  INVENTORY_LOCATION=$ORA_INV \
  SOFTWARE_LOCATION=$OGG_HOME \
  UNIX_GROUP_NAME=oinstall \
  INSTALL_OPTION=ORA21c \
  DECLINE_SECURITY_UPDATES=true \
  ACCEPT_LICENSE_AGREEMENT=true

sleep 15

echo "==== Installing GoldenGate Microservices ===="
"$ms_installer" -silent \
  oracle.install.option=OGGCORE \
  INSTALL_TYPE=GG_MICROSERVICES \
  ORACLE_BASE=$ORA_BASE \
  INVENTORY_LOCATION=$ORA_INV \
  SOFTWARE_LOCATION=$OGG_HOME \
  UNIX_GROUP_NAME=oinstall \
  INSTALL_OPTION=ORA21c \
  DECLINE_SECURITY_UPDATES=true \
  ACCEPT_LICENSE_AGREEMENT=true

sleep 15

echo "==== GoldenGate Classic + Microservices Installation Completed Successfully ===="
