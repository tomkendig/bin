#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
$ec->login('admin', 'changeme');
#print $ec->getProperty('/myCall/PropertyName');
$ec->createProject("PropertiesSandbox", {description => "Print out all default commander properties in one log file"});
$ec->createProcedure("PropertiesSandbox", "PropertiesShow", {description => 'Use this procedure to put on a properties show', resourceName => "local"});
$ec->createStep("PropertiesSandbox", "PropertiesShow", "StepEnvironment", {parallel => 1, command => '
echo Show all the environment variables ordered alphabetically
env | sort
echo Show all jobId properties with ectool
ectool getProperties --jobId $COMMANDER_JOBID | grep property
echo Show all projectName properties with ectool
ectool getProperties --projectName "PropertiesSandbox"
echo Show all proceureName properties with ectool
ectool getProperties --projectName "PropertiesSandbox" --procedureName PropertiesShow
echo Show all stepName properties with ectool
ectool getProperties --projectName "PropertiesSandbox" --procedureName PropertiesShow --stepName "StepEnvironment"
echo Show all jobStepId properties with ectool
ectool getProperties --jobStepId $COMMANDER_JOBSTEPID
echo Show all userName properties with ectool
ectool getProperties --userName $USER
echo Show all resourceName properties with ectool
ectool getProperties --resourceName local
echo Show all workspaceName properties with ectool
ectool getProperties --workspaceName $COMMANDER_WORKSPACE_NAME
', 
description => 'Use this procedure to list both the OS environment and using getProperties, the commander environment',
});
$ec->createStep("PropertiesSandbox", "PropertiesShow", "GetEnvironment", {parallel => 1, command => '
echo Show all the API get properties
', 
description => 'Use this procedure to list both the OS environment and using getProperties, the commander environment',
});
$ec->createStep("PropertiesSandbox", "PropertiesShow", "PerlProperties", {parallel => 1, command => '
print "Show all properties with perl print statements\n";
print "jobName - $[jobName]\n";
print "myJob/jobName - $[/myJob/jobName]\n";
print "projectName - $[projectName]\n";
print "myProject/projectName - $[/myProject/projectName]\n";
print "resourceName - $[resourceName]\n";
print "myResource/resourceName - $[/myResource/resourceName]\n";
print "workspaceName - $[workspaceName]\n";
print "myWorkspace/workspaceName - $[/myWorkspace/workspaceName]\n";
print "timestamp - $[/timestamp yyyy-MMM-d hh:mm:ss]\n";
', 
description => 'Use this procedure to list, using perl, in a log file all built in properties',
shell => 'perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createStep("PropertiesSandbox", "PropertiesShow", "JavascriptProperties", {parallel => 1, command => '
print "Show all properties the easy way with javascript in perl print statements\n";
', 
description => 'Use this procedure to list, using javascript, in a log file all built in properties',
shell => 'perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createStep("PropertiesSandbox", "PropertiesShow", "JavascriptSimpleExample", {parallel => 1, command => '
print "show property substitution $[/myResource/hostName] \n";
});
$ec->runProcedure("PropertiesSandbox", { procedureName => 'PropertiesShow'});
