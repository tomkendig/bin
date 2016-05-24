#!/bin/sh -x
#Use this script to install Commander software
echo arch `uname -a` cores `cat /proc/cpuinfo | grep processor | wc -l`
cp -p /net/f2home/tkendig/installFiles/linux$1/ElectricCommander-* /opt
now=`date +%s`
#/opt/ElectricCommander-* --mode silent --installServer --installAgent --installDatabase --installWeb --unixServerUser build --unixServerGroup build --unixAgentUser qa --unixAgentGroup qa --dataDirectory /opt/data
/opt/ElectricCommander-* --mode silent --installServer --installAgent --installDatabase --unixServerUser build --unixServerGroup build --unixAgentUser qa --unixAgentGroup qa
echo -n "version `/opt/electriccloud/electriccommander/bin/ectool --version|head -n 1|awk '{print $6}'` installDuration "
expr `date +%s` - $now
now=`date +%s`
/opt/electriccloud/electriccommander/bin/ectool --timeout 600 login admin changeme #extended timeout from 3 min to 10 min for 4.1 startup time
echo -n "loginDelay "
expr `date +%s` - $now
now=`date +%s`
/opt/electriccloud/electriccommander/bin/ectool importLicenseData /net/f2home/tkendig/license/electriccloud-cmdr.txt
/opt/electriccloud/electriccommander/bin/ec-perl /net/f2home/tkendig/bin/CmdrResourceStressTest.pl
/opt/electriccloud/electriccommander/bin/ec-perl /net/f2home/tkendig/bin/CmdrBatchStressTest.pl > /net/f2home/tkendig/results/`hostname`_`date +%Y%m%d_%H%M`.txt
echo -n "executionDuration "
expr `date +%s` - $now
now=`date +%s`
/opt/electriccloud/electriccommander/uninstall --mode silent
echo -n "uninstallDuration "
expr `date +%s` - $now
rm -rf /opt/ElectricCommander-* /opt/electriccloud
