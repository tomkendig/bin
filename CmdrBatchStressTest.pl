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
   $| = 1;
   use Data::Dumper;
   my $ec = new ElectricCommander->new({timeout => 14400});
   $ec->login("admin", "changeme");
   my $xPath = $ec->getVersions(); 
   foreach ($xPath->findnodes(".")) { print $_->toString(); } print "\n";
   my $cmdrVersion = $xPath->findvalue("//version");
   my $cmdrVersionNumber = "3101";
   my $cmdrBuildNumber = "";
   my @versionElements = split(".", $cmdrVersion);
   my $accululationStart = time;
   my $batchCreateStepStart = time;
   my $batchCreateStepRate = 1;
   my $batchCreatePropertyStart = time;
   my $batchCreatePropertyRate = 1;
   my $batchDeleteStart = time;
   my $batchDeleteRate = 1;
   my @batchList = (
     "serial",  # The slowest creation rate. run first because least likely to cause commander log errors
     "single",  # should be faster than serial, slower than parallel
     "parallel" # The best creation rate. run last because most likely to cause commander log errors
   );
   #my @batchList = ("serial", "single");
   #my @createCount = (1,10);
   my @createCount = (
    100,
    250, 500, 750, #problems occur here
    1000,
    2000, #5000, #smoothing data points, 1.5H to create data points through 2000, 4.0H hours to create data points thru 5000
    10000, #takes 4.0H hours alone - 1.2H  hours * 3 for all batch options and has not completed sucessfully to this point Apr 2012
    1 #keep this last for one quick sanity check and because it lacks a comma
    );
   foreach my $objectCount (@createCount) {
   foreach my $batchMode (@batchList) {
   print "$objectCount, $cmdrVersion\n";

   #create batch for and measure the step create duration
   my $batchAPIs = $ec->newBatch("$batchMode");
   #create batch for and measure the property create duration
   my $batchAPIp = $ec->newBatch("$batchMode");
   if ($batchMode == "parallel") {
      $ec->createProject("BatchPerformance$batchMode$objectCount", {description => "Batchmode Performance Project", workspaceName => "default"});
      $ec->createProcedure("BatchPerformance$batchMode$objectCount", "BatchCheck", {resourceName => "local"});
   } else {
      $batchAPIs->createProject("BatchPerformance$batchMode$objectCount", {description => "Batchmode Performance Project", workspaceName => "default"});
      $batchAPIs->createProcedure("BatchPerformance$batchMode$objectCount", "BatchCheck", {resourceName => "local", workspaceName => "default"});
   }
   for (1..$objectCount) {
     $batchAPIs->createStep("BatchPerformance$batchMode$objectCount", "BatchCheck", "BatchEcho_$_", {command => "echo BatchEcho_$_", resourceName => "local", workspaceName => "default", parallel => 1});
     $batchAPIp->setProperty("/projects/Performance/procedures/BatchImport/propertylist$objectCount/$batchMode$objectCount$_", "$batchMode$objectCount$_");
   }

   $batchCreateStepStart = time;
   print "$batchCreateStepStart, $batchMode, $objectCount, $cmdrVersion $versionElements[0] $versionElements[1] $versionElements[3] buildNumber \n";
   $xPath = $batchAPIs->submit();
   my $batchCreateStepDuration = time - $batchCreateStepStart;
   if ($batchCreateStepDuration == 0) {$batchCreateStepDuration = 1;}
   $batchCreateStepRate = $objectCount / $batchCreateStepDuration;

   $batchCreatePropertyStart = time;
   print "$batchCreatePropertyStart, $batchMode, $objectCount, $cmdrVersion\n";
   $xPath = $batchAPIp->submit();
   my $batchCreatePropertyDuration = time - $batchCreatePropertyStart;
   if ($batchCreatePropertyDuration == 0) {$batchCreatePropertyDuration = 1;}
   $batchCreatePropertyRate = $objectCount / $batchCreatePropertyDuration;

   #create batch for and measure the step delete duration
   $batchDeleteStart = time;
   print "$batchDeleteStart, $batchMode, $objectCount, $cmdrVersion\n";
   my $batchAPId = $ec->newBatch("$batchMode");
   $batchAPId->deleteProject("BatchPerformance$batchMode$objectCount");
   my $xPathd = $batchAPId->submit();
   my $batchDeleteDuration = time - $batchDeleteStart;
   if ($batchDeleteDuration == 0) {$batchDeleteDuration = 1;}
   $batchDeleteRate = $objectCount / $batchDeleteDuration;

   my $logString = "R" . "etry " . "#";
   my $whichSearchString = "false";
   open(FILE,"/opt/electriccloud/electriccommander/logs/commander.log");
   if (grep{/$logString/} <FILE>){
      #print "String found\n";
      $whichSearchString = "true";
   }else{
      #print "String NOT found\n";
      $whichSearchString = "false";
   }
   close FILE;

   my $comboDuration = time - $batchCreateStepStart;
   my $accululationDuration = time - $accululationStart;
   my $performance = "$batchCreateStepRate batchCreateStepRate $batchCreateStepDuration batchCreateStepDuration $batchCreatePropertyRate batchCreatePropertyRate $batchCreatePropertyDuration batchCreatePropertyDuration $batchDeleteRate batchDeleteRate $batchDeleteDuration batchDeleteDuration $comboDuration comboDuration $accululationDuration accululationDuration $batchMode batchMode $objectCount objectCount $whichSearchString whichSearchString $cmdrVersion cmdrVersion \n";
   print $performance,"\n";
   $ec->setProperty("/projects/Performance/procedures/BatchImport/performance/$batchMode$objectCount", $performance);
}
}
'}
);
$ec->runProcedure("Performance", { procedureName => 'BatchImport', pollInterval => 1, timeout => 14400}); # wait for 14400S/240M/4H
my $xPath = $ec->getProperty("/projects/Performance/procedures/BatchImport/procedureName");
#print $xPath->findvalue("//value"), "\n";
$xPath = $ec->getProperties({path => "/projects/Performance/procedures/BatchImport/performance"});
#foreach ($xPath->findnodes(".")) { print $_->toString(); }
my $propertyNodeset = $xPath->findnodes("/responses/response/propertySheet");
#foreach ($propertyNodeset->get_nodelist) { print $_->toString(); }
foreach my $whichProperty ($propertyNodeset->get_nodelist) {
  print $xPath->findvalue("//value", $whichProperty);
}

