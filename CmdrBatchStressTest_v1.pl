#!/usr/local/perl
# Before runing this script:
#0) use ec-perl to run this script
#1) Be sure to have deleted the projects called "CmdrResourceStressTests" & "Performance"
#2) set the workspace named "default" and "remote" to point to how and where you want.
#3) if you want, change server name ("localhost") to your node of choice
#
use strict;
use ElectricCommander ();
my $ec = new ElectricCommander->new("localhost");
   $ec->login('admin', 'changeme');

   #$ec->createProject("Performance", {description => "Manage the Product CmdrResourceStressTests", workspaceName => "default"});
   $ec->deleteProcedure("Performance", "BatchImport");
   $ec->createProcedure("Performance", "BatchImport", {description => 'Procedure for Batch Import Performance', resourceName => 'local'});
   $ec->createStep("Performance", "BatchImport", "BatchImportCreate", {shell => "ec-perl", command => '
   use strict;
   use ElectricCommander ();
   use Data::Dumper;
   my $ec = new ElectricCommander->new();
   $ec->login("admin", "changeme");
   my $xPath = $ec->getVersions(); 
   foreach ($xPath->findnodes(".")) { print $_->toString(); } print "\n";
   my $cmdrVersion = $xPath->findvalue("//version");
   my $myBatchCreateStart = time;
   my $myBatchDeleteStart = time;
   my $myBatchCreateRate = 1;
   my $myBatchDeleteRate = 1;
   #my @createCount = (1,10);
   my @createCount = (1,100,500,1000);
   foreach my $howMany (@createCount) {
   print "$howMany, $cmdrVersion\n";
   my @batchList = ("serial", "single", "parallel");
   #my @batchList = ("serial", "single");
   foreach my $batchMode (@batchList) {
   $myBatchCreateStart = time;
   print "$myBatchCreateStart, $batchMode, $howMany, $cmdrVersion\n";
   my $batchAPIc = $ec->newBatch("$batchMode");

   if ($batchMode == "parallel") {
      $ec->createProject("BatchPerformance$batchMode$howMany", {description => "Batchmode Performance Project", workspaceName => "default"});
      $ec->createProcedure("BatchPerformance$batchMode$howMany", "BatchCheck", {resourceName => "local"});
   } else {
      $batchAPIc->createProject("BatchPerformance$batchMode$howMany", {description => "Batchmode Performance Project", workspaceName => "default"});
      $batchAPIc->createProcedure("BatchPerformance$batchMode$howMany", "BatchCheck", {resourceName => "local", workspaceName => "default"});
   }
   for (1..$howMany) {
     $batchAPIc->createStep("BatchPerformance$batchMode$howMany", "BatchCheck", "BatchEcho_$_", {command => "echo BatchEcho_$_", resourceName => "local", workspaceName => "default", parallel => 1});
   }

   $xPath = $batchAPIc->submit();
   my $myBatchCreateElapsed = time - $myBatchCreateStart;
   if ($myBatchCreateElapsed == 0) {$myBatchCreateElapsed = 1;}
   $myBatchCreateRate = $howMany / $myBatchCreateElapsed;
   $myBatchDeleteStart = time;
   print "$myBatchDeleteStart, $batchMode, $howMany, $cmdrVersion\n";
   my $batchAPId = $ec->newBatch("$batchMode");
   $batchAPId->deleteProject("BatchPerformance$batchMode$howMany");
   my $xPathd = $batchAPId->submit();
   my $myBatchDeleteElapsed = time - $myBatchDeleteStart;
   if ($myBatchDeleteElapsed == 0) {$myBatchDeleteElapsed = 1;}
   $myBatchDeleteRate = $howMany / $myBatchDeleteElapsed;
   xpath_to_string($xPathd);

   sub xpath_to_string {
   my $xp = shift;
   foreach ($xp->findnodes(".")) {
     print $_->toString();
   }
   }
   my $performance = "$myBatchDeleteRate,$myBatchDeleteElapsed,$myBatchCreateRate,$myBatchCreateElapsed,$batchMode,$howMany,$cmdrVersion\n";
   print $performance,"\n";
   $ec->setProperty("/projects/Performance/procedures/BatchImport/performance/$batchMode$howMany", $performance);
}
}
'}
);
$ec->runProcedure("Performance", { procedureName => 'BatchImport', pollInterval => 1, timeout => 3600});
my $xPath = $ec->getProperty("/projects/Performance/procedures/BatchImport/procedureName");
#print $xPath->findvalue("//value"), "\n";
$xPath = $ec->getProperties({path => "/projects/Performance/procedures/BatchImport/performance"});
#foreach ($xPath->findnodes(".")) { print $_->toString(); }
my $propertyNodeset = $xPath->findnodes("/responses/response/propertySheet");
#foreach ($propertyNodeset->get_nodelist) { print $_->toString(); }
foreach my $whichProperty ($propertyNodeset->get_nodelist) {
  print $xPath->findvalue("//value", $whichProperty);
}

