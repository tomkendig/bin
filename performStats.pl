#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
$ec->login('admin', 'changeme');
$ec->createProject("Performance", {description => "Performance Tests. Look at the commander reported step times for reasonable times. Version 1.0"});
$ec->createProcedure("Performance", "Simple", {description => 'Simple Performance Test. Version 1.0', resourceName => "local"});
$ec->createStep("Performance", "Simple", "ectoolParSetup", {command => '
ectool setProperty timingP "scratchP"
', 
description => 'Setup for parallel timing tests',
});
$ec->createStep("Performance", "Simple", "EchoP", {parallel => 1, command => '
echo step OS overhead, expect one second or under
', 
description => 'measure the commander step overhead',
});
$ec->createStep("Performance", "Simple", "ectoolVersionP", {parallel => 1, command => '
ectool --version
', 
description => 'measure the ectool unwrap time expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolDatabaseP", {parallel => 1, command => '
ectool getServerStatus --serverStateOnly true
', 
description => 'measure the encription and database server overhead expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolGetPropertyP", {parallel => 1, command => '
ectool getProperty projectName
', 
description => 'measure the time it takes to get a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolSetPropertyP", {parallel => 1, command => '
ectool setProperty timing "scratch"
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolDeletePropertyP", {parallel => 1, command => '
ectool deleteProperty timingP
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "PerlTimesP", {parallel => 1, command => '
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
$ec->createStep("Performance", "Simple", "ectoolParCleanup", {command => '
ectool deleteProperty timing
', 
description => 'Cleanup after parallel timing tests',
});
$ec->createStep("Performance", "Simple", "EchoS", {command => '
echo set OS overhead, expect one second or under.
', 
description => 'measure the commander step overhead',
});
$ec->createStep("Performance", "Simple", "ectoolVersionS", {command => '
ectool --version
', 
description => 'measure the ectool unwrap time expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolDatabaseS", {command => '
ectool getServerStatus --serverStateOnly true
', 
description => 'measure the encription and database server overhead expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolGetPropertyS", {command => '
ectool getProperty projectName
', 
description => 'measure the time it takes to get a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolSetPropertyS", {command => '
ectool setProperty timing "scratch"
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "ectoolDeletePropertyS", {command => '
ectool deleteProperty timing
', 
description => 'measure the time it takes to set a property expect three seconds or under',
});
$ec->createStep("Performance", "Simple", "PerlTimesS", {command => '
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
$ec->runProcedure("Performance", { procedureName => 'Simple'});
