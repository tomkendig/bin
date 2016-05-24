#!/bin/sh
if [ -z "$1" ] ; then
    echo "First argument is directory, second argument is the text to prepend to the files, often the name of the directory. Anything in the options third argument will make it a test run"
    exit
elif [ -z "$2" ] ; then
    echo "Must supply a prepend string"
    exit
elif [ -z "$3" ] ; then
     echo "text for prepend is $1"
./exiftool -P -overwrite_original "-filename=${2}_%f.%e" ${1} # change the filename from commandline argument
rm ${1}/*.*_original
else
    echo "this will be a test run and the name will not be changed"
./exiftool -P "-testname=${2}_%f.%e" ${1} # test a filename change
fi
# for f in ${1}/*.jpg ; do
#  ./exiftool -P -progress "-AllDates=${2}" ${f}
#done
