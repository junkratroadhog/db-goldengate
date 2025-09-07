set -e

# Required environment variables: OGG_HOME, STAGE_DIR
if [ -z "$OGG_HOME" ] || [ -z "$STAGE_DIR" ]; then
  echo "ERROR: OGG_HOME or STAGE_DIR not set"
  exit 1
fi

export OGG_HOME=${OGG_HOME}
export PATH=\$OGG_HOME/bin:$PATH

# Dynamically find runInstaller inside $STAGE_DIR
installer=$(find "$STAGE_DIR" -type f -name runInstaller | head -n 1)
if [ -z "$installer" ]; then
  echo "ERROR: Missing installer file"
  exit 1
fi

# Dynamically find a response file template if exists
rsp_file=$(find "$STAGE_DIR" -type f -name "ogg*.rsp" | head -n 1)

# If no response file, run installer without -responseFile (interactive defaults)
if [ -z "$rsp_file" ]; then
  echo "WARNING: No response file found, running installer with default options"
  $installer -silent ORACLE_HOME=$OGG_HOME ORACLE_BASE=/u02/ogg INVENTORY_LOCATION=/u02/oraInventory UNIX_GROUP_NAME=oinstall DECLINE_SECURITY_UPDATES=true ACCEPT_LICENSE_AGREEMENT=true
else
  echo "Using response file: $rsp_file"
  $installer -silent -responseFile "$rsp_file" ORACLE_HOME=$OGG_HOME ORACLE_BASE=/u02/ogg INVENTORY_LOCATION=/u02/oraInventory UNIX_GROUP_NAME=oinstall DECLINE_SECURITY_UPDATES=true ACCEPT_LICENSE_AGREEMENT=true
fi