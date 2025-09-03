FIND_PDB="USERS"   # substring to match in PDB name
SRCCN=""

# Loop over all running Docker containers
for c in $(docker ps --format '{{.Names}}'); do
    # Check if container name contains the substring (case-insensitive)
    if [[ "$c" =~ ${FIND_PDB,,} ]]; then   # ,, converts FIND_PDB to lowercase
        SRCCN=$c
        echo "Found container '$SRCCN' matching PDB substring '$FIND_PDB'"
        break
    fi
done

if [ -z "$SRCCN" ]; then
    echo "No container found matching PDB substring '$FIND_PDB'"
    exit 1
fi

echo "SRCCN=$SRCCN"