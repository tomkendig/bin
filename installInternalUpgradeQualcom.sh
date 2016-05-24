#!/bin/sh
#Use this script to install software required support software and configure Commander for Usman's RHEL4 VMware distribution
rm -f /opt/*.bin /opt/upgrad* ~/.ecsession
cp -p /net/f2home/tkendig/installFiles/linux221/* /opt
/opt/commander_i686_Linux.bin -q -f --config /net/f2home/tkendig/config/support-rhel4-cmdr.config
/opt/electriccloud/electriccommander/bin/ectool login admin changeme
/opt/electriccloud/electriccommander/bin/ectool importLicenseData /net/f2home/tkendig/license/electriccloud-cmdr.txt
rpm -Uvh /net/f2home/tkendig/perl-XML-XPath-1.13-2.2.el4.rf.noarch.rpm
/opt/electriccloud/electriccommander/bin/ec-perl /net/f2home/tkendig/bin/CmdrResourceStressTest.pl
rm -f /opt/*.bin /opt/upgrad*
cp -p /net/f2home/tkendig/installFiles/linux223/* /opt
echo  ; echo admin ; echo commander ; echo commander ; | /opt/upgrade
rm -f /opt/*.bin /opt/upgrad*
cp -p /net/f2home/tkendig/installFiles/linux301/* /opt
echo ; echo qa ; echo qa ; echo ; | /opt/commander_i686_Linux.bin
rm -f /opt/*.bin /opt/upgrad*
cp -p /net/f2home/tkendig/installFiles/linux310/* /opt
echo ; echo ; | /opt/commander_i686_Linux.bin 
rm -f /opt/*.bin /opt/upgrad*
cp -p /net/f2home/tkendig/installFiles/linux311/* /opt
echo y ; echo y ; echo y ; | /opt/commander_i686_Linux.bin # this upgrade failed!!
rm -f /opt/*.bin /opt/upgrad*
cp -p /net/f2home/tkendig/installFiles/linux320/* /opt
/opt/commander_i686_Linux.bin -q -f --config /net/f2home/tkendig/config/support-rhel4-cmdr.config
