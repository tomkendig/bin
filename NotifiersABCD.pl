#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("chronic2");
$ec->login('qa', 'qa');
$ec->createProcedure("QA Tests", "NotifierB", {description => 'check nested notifier', resourceName => "local"});
$ec->createStep("QA Tests", "NotifierB", "B", {parallel => 1, command => '
ectool --version B
', 
description => 'step for NotifierB',
});
$ec->createProcedure("QA Tests", "NotifierC", {description => 'check nested notifier', resourceName => "local"});
$ec->createStep("QA Tests", "NotifierC", "C", {parallel => 1, command => '
ectool --version C
', 
description => 'step for NotifierC',
});
$ec->createProcedure("QA Tests", "NotifierD", {description => 'check nested notifier', resourceName => "local"});
$ec->createStep("QA Tests", "NotifierD", "D", {parallel => 1, command => '
ectool --version D
', 
description => 'step for NotifierD',
});
$ec->createProcedure("QA Tests", "NotifierA", {description => 'check nested notifier', resourceName => "local"});
$ec->createStep("QA Tests", "NotifierA", "A", {parallel => 1, command => '
ectool --version A
', 
description => 'step for NotifierA',
});
$ec->createStep("QA Tests", "NotifierA", "B", {parallel => 1, subprocedure => "NotifierB"});
$ec->createStep("QA Tests", "NotifierA", "C", {parallel => 1, subprocedure => "NotifierC"});
$ec->createStep("QA Tests", "NotifierA", "D", {parallel => 1, subprocedure => "NotifierD"});
$ec->createEmailNotifier("emailA", {projectName => "QA Tests", procedureName => "NotifierA", formattingTemplate => 'Subject: $[procedureName] A', destinations => 'tkendig@electric-cloud.com'});
$ec->createEmailNotifier("emailB", {projectName => "QA Tests", procedureName => "NotifierB", formattingTemplate => 'Subject: $[procedureName] B', destinations => 'tkendig@electric-cloud.com'});
$ec->createEmailNotifier("emailC", {projectName => "QA Tests", procedureName => "NotifierC", formattingTemplate => 'Subject: $[procedureName] C', destinations => 'tkendig@electric-cloud.com'});
$ec->createEmailNotifier("emailD", {projectName => "QA Tests", procedureName => "NotifierD", formattingTemplate => 'Subject: $[procedureName] D', destinations => 'tkendig@electric-cloud.com'});
$ec->runProcedure("QA Tests", { procedureName => 'NotifierA'});
