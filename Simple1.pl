#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("chronic2");
$ec->login('qa', 'qa');
$ec->createProcedure("QA Tests", "Simple", {description => 'Simple Performance Test. Version 1.0', resourceName => "local"});
$ec->createStep("QA Tests", "Simple", "ectoolParSetup", {command => '
ectool setProperty timingP "scratchP"
', 
description => 'Setup for parallel timing tests',
});
$ec->createStep("QA Tests", "Simple", "EchoP", {parallel => 1, command => '
echo step OS overhead, expect one second or under
', 
description => 'measure the commander step overhead',
});
$ec->createStep("QA Tests", "Simple", "ectoolVersionP", {parallel => 1, command => '
ectool --version
', 
description => 'measure the ectool unwrap time expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolDatabaseP", {parallel => 1, command => '
ectool getServerStatus --serverStateOnly true
', 
description => 'measure the encription and database server overhead expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolGetPropertyP", {parallel => 1, command => '
ectool getProperty projectName
', 
description => 'measure the time it takes to get a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolSetPropertyP", {parallel => 1, command => '
ectool setProperty timing "scratch"
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolDeletePropertyP", {parallel => 1, command => '
ectool deleteProperty timingP
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "PerlTimesP", {parallel => 1, command => '
use Time::HiRes qw(time);
use ElectricCommander ();
$ec = new ElectricCommander->new();
$myStartTime = time;
$prenow = $myStartTime;
system "echo step OS overhead, expect under one second";
$now = time;
print "For echo        - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->getServerStatus({serverStateOnly => "true"});
$now = time;
print "getServerStatus - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->getProperty("projectName", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "getProperty     - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->setProperty("/myStep/timing", "scratch", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "setProperty     - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->deleteProperty("/myStep/timing", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "deleteProperty  - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
', 
description => 'Use this procedure to create a test of the perl API performance',
shell => 'ec-perl'
});
$ec->createStep("QA Tests", "Simple", "ectoolParCleanup", {command => '
ectool deleteProperty timing
', 
description => 'Cleanup after parallel timing tests',
});
$ec->createStep("QA Tests", "Simple", "EchoS", {command => '
echo set OS overhead, expect one second or under.
', 
description => 'measure the commander step overhead',
});
$ec->createStep("QA Tests", "Simple", "ectoolVersionS", {command => '
ectool --version
', 
description => 'measure the ectool unwrap time expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolDatabaseS", {command => '
ectool getServerStatus --serverStateOnly true
', 
description => 'measure the encription and database server overhead expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolGetPropertyS", {command => '
ectool getProperty projectName
', 
description => 'measure the time it takes to get a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolSetPropertyS", {command => '
ectool setProperty timing "scratch"
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "ectoolDeletePropertyS", {command => '
ectool deleteProperty timing
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("QA Tests", "Simple", "PerlTimesS", {command => '
use Time::HiRes qw(time);
use ElectricCommander ();
$ec = new ElectricCommander->new();
$myStartTime = time;
$prenow = $myStartTime;
system "echo step OS overhead, expect under one second";
$now = time;
print "For echo        - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->getServerStatus({serverStateOnly => "true"});
$now = time;
print "getServerStatus - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->getProperty("projectName", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "getProperty     - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->setProperty("/myStep/timing", "scratch", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "setProperty     - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
$prenow = $now;
$ec->deleteProperty("/myStep/timing", {jobStepId => $ENV{COMMANDER_JOBSTEPID}});
$now = time;
print "deleteProperty  - current time $now, command time ", $now-$prenow, "sec, elapsed time ", $now-$myStartTime, "sec\n";
', 
description => 'Use this procedure to create a test of the perl API performance',
shell => 'ec-perl'
});
$ec->runProcedure("QA Tests", { procedureName => 'Simple'});
