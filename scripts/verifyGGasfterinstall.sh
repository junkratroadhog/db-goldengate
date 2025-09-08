
#!/bin/bash
set -e

# Required environment variables: OGG_HOME, STAGE_DIR, ORA_BASE (optional)
: "${OGG_HOME:?Environment variable OGG_HOME must be set}"

export PATH=$OGG_HOME/bin:$PATH

if [ ! -x "$OGG_HOME/bin/adminclient" ]; then
  echo 'ERROR: adminclient not found in $OGG_HOME/bin'
  exit 1
fi
echo 'GoldenGate AdminClient Version:'
$OGG_HOME/bin/adminclient -version