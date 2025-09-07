set -e
export OGG_HOME=${OGG_HOME}
export PATH=\$OGG_HOME/bin:$PATH
# Dynamically find runInstaller inside $STAGE_DIR
installer=$(find $STAGE_DIR -type f -name runInstaller | head -n 1)
if [ -z "$installer" ]; then
  echo "ERROR: Missing installer file"
  echo "installer=$installer"
  exit 1
fi
# Run installer in silent mode
$installer -silent -responseFile $rsp_file ORACLE_HOME=$OGG_HOME ORACLE_BASE=/u02/ogg INVENTORY_LOCATION=/u02/oraInventory UNIX_GROUP_NAME=oinstall DECLINE_SECURITY_UPDATES=true ACCEPT_LICENSE_AGREEMENT=true