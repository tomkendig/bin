#!/bin/bash 
ectool login admin changeme
ectool deleteProperty /projects/Testing/whichTime1
ectool deleteProperty /projects/Testing/whichTime2
ectool setProperty /projects/Testing/whichTime1
touch /tmp/tom.txt
touch ~/Customers/support/tom.txt
touch tom.txt
ectool setProperty /projects/Testing/whichTime2
ls --full-time tom.txt
ls --full-time ~/Customers/support/tom.txt
ls --full-time /tmp/tom.txt
ectool getProperty /projects/Testing/whichTime1/createTime
ectool getProperty /projects/Testing/whichTime2/createTime
rm tom.txt
rm /tmp/tom.txt
