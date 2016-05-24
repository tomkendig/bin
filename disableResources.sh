#!/bin/sh
# resourceDisable.sh
# This script will take a compressed full export of a commander database and create a new uncompressed XML file with all resources set to be disabled
#
# Example "disableResource.sh export-20110909"
######################################################################

if [ $# -lt 1 -o $# -gt 1 ] ; then
    echo "Usage: $0 <compressed export file>"
    exit 2
fi

if [ ! -e $1.xml.gz ]; then 
    echo "The export source file $1.xml.gz does not exist"
    exit 2
fi

zcat $1.xml.gz | sed '/<resourceDisabled>0</ s/>0</>1</g' > $1.xml # disable all resources in a ectool export
