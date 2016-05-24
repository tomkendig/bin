#!/usr/bin/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
$ec->login('admin', 'changeme');
$ec->createProject("NestedProcDepth", {description => "Check Nested Procedure Depth"});

$ec->createProcedure("NestedProcDepth", "Proc1", {description => 'top level procedure', resourceName => "local"});
$ec->createStep("NestedProcDepth", "Proc1", "StepT", {parallel => 1, command => '
echo ProcT
', 
description => 'First Simple step',
});
$ec->createStep("NestedProcDepth", "Proc1", "Proc1", {subprocedure => "Proc1", subproject => "NestedProcDepth", parallel => 1});

$ec->createProcedure("NestedProcDepth", "Proc1", {description => 'top level procedure', resourceName => "local"});
$ec->createStep("NestedProcDepth", "Proc1", "StepT", {parallel => 1, command => '
echo ProcT
', 
description => 'First Simple step',
});
#$ec->createStep("NestedProcDepth", "Proc1", "Proc1", {subprocedure => "Proc2", subproject => "NestedProcDepth", parallel => 1});

$ec->createProcedure("NestedProcDepth", "ProcT", {description => 'top level procedure', resourceName => "local"});
$ec->createStep("NestedProcDepth", "ProcT", "StepT", {parallel => 1, command => '
echo ProcT
', 
description => 'First Simple step',
});
$ec->createStep("NestedProcDepth", "ProcT", "Proc1", {subprocedure => "Proc1", subproject => "NestedProcDepth", parallel => 1});

$ec->createProcedure("NestedProcDepth", "ProcT", {description => 'top level procedure', resourceName => "local"});
$ec->createStep("NestedProcDepth", "ProcT", "StepT", {parallel => 1, command => '
echo ProcT
', 
description => 'First Simple step',
});
$ec->createStep("NestedProcDepth", "ProcT", "Proc1", {subprocedure => "Proc1", subproject => "NestedProcDepth", parallel => 1});

$ec->runProcedure("Performance", { procedureName => 'Simple'});
