#!/bin/sh
if [ -z "$1" ] ; then
    echo "First argument is directory, second argument is a year date"
    exit
elif [ -z "$2" ] ; then
    echo "date of form year required"
else
     echo "path used is $1 and year used is $2"
fi
echo $((`./exiftool ${1} | grep Create | head -1 | cut -d: -f2` - ${2})) 
./exiftool -P -progress "-AllDates-=$((`./exiftool ${1} | grep Create | head -1 | cut -d: -f2` - ${2})):0:0 0" ${1} #change all meta dates in a passed directory to a known date from commandline
# for f in ${1}/*.jpg ; do
#  ./exiftool -P -progress "-AllDates=${2}" ${f}
#done
