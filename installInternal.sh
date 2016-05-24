#!/bin/sh
#Use this script to install software required support software and configure Commander for Usman's RHEL4 VMware distribution
cp /net/f2home/tkendig/installFiles/linux370/* /opt
mkdir /opt/ECworkspace
chown build /opt/ECworkspace
chmod 777 /opt/ECworkspace
/opt/ElectricCommander-3.7.0.34410 
#/opt/ElectricCommander-3.7.0.34410 -q -f --config /net/f2home/tkendig/config/support-rhel4-cmdr.config
/opt/electriccloud/electriccommander/bin/ectool login admin changeme
/opt/electriccloud/electriccommander/bin/ectool importLicenseData /net/f2home/tkendig/license/electriccloud-cmdr.txt
rpm -Uvh /net/f2home/tkendig/perl-XML-XPath-1.13-2.2.el4.rf.noarch.rpm
/opt/electriccloud/electriccommander/bin/ec-perl /net/f2home/tkendig/bin/CmdrResourceStressTest.pl
