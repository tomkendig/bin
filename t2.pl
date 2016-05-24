#!/usr/local/perl
# Before runing this script:
#0) use ec-perl to run this script
#1) Be sure to have deleted the projects called "CmdrResourceStressTests" & "Performance"
#2) set the workspace named "default" and "remote" to point to how and where you want.
#3) if you want, change server name ("localhost") to your node of choice
#
use strict;
use ElectricCommander ();
#use ElectricCommander;
#my $ec = new ElectricCommander({debug=>1});
my $ec = new ElectricCommander->new({debug => 1, logFile => "/var/tmp/tom.log"});
#my $ec = new ElectricCommander->new({debug => 1});
$ec->login('admin', 'changeme');
my $xPath = $ec->getProperty("/projects/Performance/procedures/BatchImport/procedureName");
print $xPath->findvalue("//value"), "\n";
my $xpath = $ec->getVersions();
print "got versions\n";
