#!/bin/sh

#
# Generated on Wed Sep 10 18:50:15 GMT 2025
# Start of user configurable variables
#
LANG=C
export LANG

#Trap to cleanup cookie file in case of unexpected exits.
trap 'rm -f $COOKIE_FILE; exit 1' 1 2 3 6 

# Path to wget command
WGET=/usr/bin/wget

# Log directory and file
LOGDIR=.
LOGFILE=$LOGDIR/wgetlog-$(date +%m-%d-%y-%H:%M).log

# Print wget version info 
echo "Wget version info: 
------------------------------
$($WGET -V) 
------------------------------" > "$LOGFILE" 2>&1 

# Location of cookie file 
COOKIE_FILE=$(mktemp -t wget_sh_XXXXXX) >> "$LOGFILE" 2>&1 
if [ $? -ne 0 ] || [ -z "$COOKIE_FILE" ] 
then 
 echo "Temporary cookie file creation failed. See $LOGFILE for more details." |  tee -a "$LOGFILE" 
 exit 1 
fi 
echo "Created temporary cookie file $COOKIE_FILE" >> "$LOGFILE" 

# Output directory and file
OUTPUT_DIR=.
#
# End of user configurable variable
#

 $WGET --load-cookies="$COOKIE_FILE" "https://edelivery.oracle.com/ocom/softwareDownload?fileName=V1042871-01.zip&token=Y3ArYnpJYXl3L3R4c2tGd2tzZzBIZyE6OiFmaWxlSWQ9MTE4NzUyNTkxJmZpbGVTZXRDaWQ9MTE1NzU4MyZyZWxlYXNlQ2lkcz0xMTUwNjc1JmRvd25sb2FkVHlwZT05NTc2MSZhZ3JlZW1lbnRJZD0xMjEyMzg2NCZlbWFpbEFkZHJlc3M9b3NkY19ub25fc3NvX3VzZXJAb3JhY2xlLmNvbSZ1c2VyTmFtZT1FUEQtT1NEQ19OT05fU1NPX1VTRVJAT1JBQ0xFLkNPTSZpcEFkZHJlc3M9MzYuMjU1LjYuMjQ0JnVzZXJBZ2VudD1Nb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvMTQwLjAuMC4wIFNhZmFyaS81MzcuMzYgRWRnLzE0MC4wLjAuMCZjb3VudHJ5Q29kZT1VUyZkbHBDaWRzPTExNTQ0NzgmYXBwbGljYXRpb25JZD05JnNzb3luPU4mcXVlcnlTdHJpbmc9ZGxwX2NpZCwxMTU0NDc4IXJlbF9jaWQsMTE1MDY3NSFhdXRoLGZhbHNl&auth=false" -O "$OUTPUT_DIR/V1042871-01.zip" >> "$LOGFILE" 2>&1 

# Cleanup
rm -f "$COOKIE_FILE" 
echo "Removed temporary cookie file $COOKIE_FILE" >> "$LOGFILE" 

