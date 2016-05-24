#!/bin/bash 
function quit {
exit
}
function hello {
echo Hello!
}
ectool login admin changeme
ectool deleteProperty /projects/TestingCopy/whichTime1
ectool deleteProperty /projects/TestingCopy/whichTime2
ectool setProperty /projects/TestingCopy/whichTime1
touch tom.txt
touch /tmp/tom.txt
ectool setProperty /projects/TestingCopy/whichTime2
ls --full-time tom.txt
ls --full-time /tmp/tom.txt
ectool getProperty /projects/TestingCopy/whichTime1/createTime
ectool getProperty /projects/TestingCopy/whichTime2/createTime
rm tom.txt
rm /tmp/tom.txt
hello
quit
echo foo 
if [ -f /tmp/MSInstaller/*.md5 ]
then
    rm /tmp/MSInstaller/*.md5
fi
