#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
$ec->login('admin', 'changeme');
$ec->createProject("ExportUtilities", {description => "Export Utilities for Commander. Version 0.1"});
$ec->createProcedure("ExportUtilities", "Simple", {description => 'Simple Performance Test. Version 0.1', resourceName => "local"});
$ec->createStep("ExportUtilities", "Simple", "ectoolParSetup", {command => '
ectool setProperty timingP "scratchP"
', 
description => 'Setup for parallel timing tests',
});
$ec->createStep("ExportUtilities", "Simple", "EchoP", {parallel => 1, command => '
echo step OS overhead, expect one second or under
', 
description => 'measure the commander step overhead',
});
$ec->createProcedure("ExportUtilities", "ExportProcWithNotifiers", {description => 'Export a procedure with notifiers. Version 0.1', resourceName => "local"});
$ec->createStep("ExportUtilities", "ExportProcWithNotifiers", "doExport", {command => '
use strict;
use ElectricCommander ();
sub copySubTree {
  my ($sourcenode, $destnode) = @_;
  my $copy_node =  $sourcenode->cloneNode(1);
  if ( $sourcenode->getOwnerDocument() ne $destnode->getOwnerDocument() ) {
    $copy_node->setOwnerDocument( $destnode->getOwnerDocument() );
  }
  $destnode->appendChild($copy_node);
  return $copy_node;
}
my $ec = new ElectricCommander->new();
my $projectName = "$[projName]"; #Testing by default
my $procedureName = "$[procName]"; #NotiferCheck by default
my $outputPath = "$[outputPath]"; #/tmp/ by default
my $outputReloc = $outputPath . $procedureName . "R" . ".xml";
my $outputReg = $outputPath . $procedureName . "F" . ".xml";
my $procPath = "/projects/" . $projectName . "/procedures/" . $procedureName;
my %temp = $ec->export($outputReg, {path => $procPath});
my @resultReg = %temp;
%temp = $ec->export($outputReloc, {path => $procPath, relocatable => "true"});
my @resultReloc = %temp;
print  @resultReg . " status on full export; " . @resultReloc . " status on relative export\n";
my $xPathReloc = XML::XPath->new(filename => $outputReloc);
my $xPathReg = XML::XPath->new(filename => $outputReg);
print $xPathReg->find('/exportedData/procedure/step')->get_nodelist . " steps, " . 
      $xPathReg->find('/exportedData/procedure/step/systemPropertySheet')->get_nodelist . " with systemPropertySheet\n";
my $whichStep = 0;
foreach my $node ($xPathReg->findnodes('/exportedData/procedure/step')) {
  $whichStep = $whichStep + 1;
  if (1 == $node->find("./systemPropertySheet")->get_nodelist) {
    my $tmpString = "/exportedData/procedure/step[" . $whichStep . "]/systemPropertySheet"; #print $whichStep . "\n";
    my $scratch = $xPathReloc->createNode($tmpString);
  }
}
if (1 == $xPathReg->find("/exportedData/procedure/systemPropertySheet")->get_nodelist) {
  my $scratch1 = $xPathReg->find("/exportedData/procedure/systemPropertySheet")->get_node;
  my $scratch2 = $xPathReloc->find("/exportedData/procedure");
  copySubTree ($scratch1, $scratch2);
  my $scratch = $xPathReloc->createNode('/exportedData/procedure/systemPropertySheet');
}
my $outputPlus = ">" . $outputPath . $procedureName . ".xml";
open(XML, $outputPlus);
print XML $xPathReloc->findnodes_as_string("/");
close XML;
', 
shell => 'ec-perl',
description => 'Get an initial export',
});
$ec->runProcedure("ExportUtilities", { procedureName => 'Simple'});
$ec->runProcedure("ExportUtilities", { procedureName => 'ExportProcWithNotifiers'});
