#!/usr/local/perl
# Before runing this script:
#0) use ec-perl to run this script
#1) Be sure to have deleted the projects called "CmdrResourceStressTests" & "Performance"
#2) set the workspace named "default" and "remote" to point to how and where you want.
#3) if you want, change server name ("localhost") to your node of choice
#
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
   $ec->login('admin', 'changeme');

   $ec->createProject("Performance", {description => "Manage the Product CmdrResourceStressTests", workspaceName => "default"});
   $ec->createProcedure("Performance", "BatchImport", {description => 'Procedure for Batch Import Performance'});
   $ec->createStep("Performance", "BatchImport", "BatchImportCreate", {command => '
   use ElectricCommander ();
   use Data::Dumper;
   $ec = new ElectricCommander->new();
   $ec->login("admin", "changeme");
   $batchAPI = $ec->newBatch("single");

   $batchAPI->createProject("BatchPerformance", {description => "Manage the Product CmdrResourceStressTests", workspaceName => "default"});
   $batchAPI->createProcedure("BatchPerformance", "BatchCheck", {command => 'echo "BatchEcho"', resourceName => "local", workspaceName => "default", parallel => 1});
   for (1..10) {
     $batchAPI->createStep("BatchPerformance", "BatchCheck", "BatchEcho_$_", {command => 'echo "BatchEcho_$_"', resourceName => "local", workspaceName => "default", parallel => 1});
   }
'});

