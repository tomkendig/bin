#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
$ec->login('admin', 'changeme');
#print $ec->getProperty('/myCall/PropertyName');
$ec->createProject("ScheduleAtMidnight", {description => "Show Commander schedules two jobs at midnight"});
$ec->createProcedure("ScheduleAtMidnight", "Short Step", {description => 'Use this procedure to show the two jobs at midnight', resourceName => "local"});
$ec->createStep("ScheduleAtMidnight", "Short Step", "Short 10 sec Step", {parallel => 1, command => '
use Time::Local;
$startTime = time();
print "Short Step start\n";
sleep (10);
$stopTime = time();
print "Short Step stop ", $stopTime - $startTime, "\n";
', 
description => 'Use this procedure to show a short 10 second sleep step works',
shell => 'ec-perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createProcedure("ScheduleAtMidnight", "Medium Step", {description => 'Use this procedure to show the two jobs at midnight', resourceName => "local"});
$ec->createStep("ScheduleAtMidnight", "Medium Step", "Medium 5 min Step", {parallel => 1, command => '
use Time::Local;
$startTime = time();
print "Medium Step start\n";
sleep (60 * 5);
$stopTime = time();
print "Medium Step stop ", $stopTime - $startTime, "\n";
', 
description => 'Use this procedure to show a medium 5 minute sleep step works',
shell => 'ec-perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createProcedure("ScheduleAtMidnight", "Long Step", {description => 'Use this procedure to show the two jobs at midnight', resourceName => "local"});
$ec->createStep("ScheduleAtMidnight", "Long Step", "Long 6 hour Step", {parallel => 1, command => '
use Time::Local;
$startTime = time();
print "Long Step start\n";
sleep (60 * 60 * 6);
$stopTime = time();
print "Long Step stop ", $stopTime - $startTime, "\n";
', 
description => 'Use this procedure to show a long 11 hour sleep step works',
shell => 'ec-perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createSchedule("ScheduleAtMidnight", "Overlap Midnight Short", {
startTime => '00:00',
stopTime => '23:59',
interval => '5',
intervalUnits => 'hours',
weekDays => 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday',
procedureName => 'Short Step',
});
$ec->createSchedule("ScheduleAtMidnight", "Overlap Midnight Medium", {
startTime => '00:00',
stopTime => '23:59',
interval => '5',
intervalUnits => 'hours',
weekDays => 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday',
procedureName => 'Medium Step',
});
$ec->createSchedule("ScheduleAtMidnight", "Overlap Midnight Long", {
startTime => '00:00',
stopTime => '23:59',
interval => '5',
intervalUnits => 'hours',
weekDays => 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday',
procedureName => 'Long Step',
});
$ec->createSchedule("ScheduleAtMidnight", "Midnight Medium", {
startTime => '00:00',
weekDays => 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday',
procedureName => 'Medium Step',
});
$ec->createSchedule("ScheduleAtMidnight", "Midnight Short", {
startTime => '00:01',
weekDays => 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday',
procedureName => 'Short Step',
});
$ec->runProcedure("ScheduleAtMidnight", { procedureName => 'Short Step', });
$ec->runProcedure("ScheduleAtMidnight", { procedureName => 'Medium Step', });
$ec->runProcedure("ScheduleAtMidnight", { procedureName => 'Long Step', });
