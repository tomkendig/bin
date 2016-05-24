#!/bin/sh
if [ -z "$1" ] ; then
    echo 'First argument is directory, second argument is a full date with time, the argument is in double quotes. Example "1926:07:04 12:00:00"'
    exit
elif [ -z "$2" ] ; then
     echo "requires a directory for the second argument"
else
    echo "this will change the files in ${1} to date ${2}"
./exiftool -P -progress "-AllDates=${2}" ${1} # change all the metadata dates
# for f in ${1}/*.jpg ; do
#  ./exiftool -P -progress "-AllDates=${2}" ${f}
#done
fi
