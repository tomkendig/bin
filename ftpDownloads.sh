#!/usr/sh -xf
grep data /var/log/pureftpd.log.* /var/log/pureftpd.log | grep commander | grep -v txt | grep -v pdf | tail -100
grep customer /var/log/ftp.log.* /var/log/ftp.log | grep cmdr | grep -v txt | grep -v pdf | tail -100
for whichdir in `\ls -r /var/log/pureftpd.log*`; do `\grep commander | grep -v txt | grep -v pdf`  done; | tail -100
exit
