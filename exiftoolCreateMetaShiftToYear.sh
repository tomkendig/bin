#!/bin/sh
if [ -z "$1" ] ; then
   echo "First argument is directory, second argument is a year date"
   exit
elif [ -z "$2" ] ; then
   echo "date of form year required"
else
   echo "path used is $1 and year used is $2"
fi
exif=0
noexif=0
#./exiftool -P -progress "-AllDates=${2}" ${f}
for f in ${1}/*.jpg ; do
  #echo `./exiftool ${f} | grep "Create Date" | head -1`
  if [ -z "`./exiftool ${f} | grep 'Create Date' | head -1`" ] ; then
    #echo `stat ${f} | grep Modify | cut -d. -f1 | cut -d: -f2,3,4 | sed 's/-/:/g'`
    ./exiftool -P -progress "-AllDates=`stat ${f} | grep Modify | cut -d. -f1 | cut -d: -f2,3,4 | sed 's/-/:/g'`" ${f}
    noexif=$(( noexif+1 ))
  else
    exif=$(( exif+1 ))
  fi
  #echo $((`./exiftool ${1} | grep "Create Date" | head -1 | cut -d: -f2` - ${2})) 
  ./exiftool -P -progress "-AllDates-=$((`./exiftool ${f} | grep "Create Date" | head -1 | cut -d: -f2` - ${2})):0:0 0" ${f} #change all meta dates in a passed directory to a known date from commandline
done
echo "${noexif}/${exif}/$(( $noexif+$exif )) files had exif meta inserted/already had exif data/total files processed"
