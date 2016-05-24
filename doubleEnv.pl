#!/usr/local/perl
use ElectricCommander ();
$ec = new ElectricCommander->new("cirrus9");
$ec->login('admin', 'changeme');
$ec->createProject("doubleEnv", {description => "Show Commander environment with double Path"});
$ec->createProcedure("doubleEnv", "doubleEnvCmd", {description => 'Use this procedure to show the double Cmd environment', resourceName => "local"});
$ec->createStep("doubleEnv", "doubleEnvCmd", "Show Double CMD Env Simple", {parallel => 1, command => '
set
echo set > ShowCmdSet.cmd
"$[/server/Electric Cloud/installDirectory]/perl/bin/perl" -e "system \'ShowCmdSet.cmd\'"
', 
description => 'Use this procedure to show the Cmd double Path',
});
$ec->createStep("doubleEnv", "doubleEnvCmd", "Show Double CMD Env Everything", {parallel => 1, command => '
set
echo set > ShowCmdSet.cmd
"$[/server/Electric Cloud/installDirectory]/perl/bin/perl" -e "system \'ShowCmdSet.cmd\'"
"$[/server/Electric Cloud/installDirectory]/perl/bin/perl" -e "system \'cmd /c perl -e \"system \\\'ShowCmdSet.cmd\\\'\"\'"
perl -e "system \'ShowCmdSet.cmd\'"
perl -e "system \'cmd /c perl -e \"system \\\'ShowCmdSet.cmd\\\'\"\'"
', 
description => 'Use this procedure to show the Cmd double Path in distributed perl and lack of double Path in cygwin perl',
});
$ec->createProcedure("doubleEnv", "doubleEnvPerl", {description => 'Use this procedure to show the double perl environment', resourceName => "local"});
$ec->createStep("doubleEnv", "doubleEnvPerl", "Show Double Perl Env", {parallel => 1, command => '
my $cmdfile = "ShowPerlSet.cmd";
open CMD, ">$cmdfile" or die("Error: Opening cmd file $cmdfile; aborting!\n");
print CMD "set";
close CMD;
print "showing environment in ", $cmdfile, "\n";
system $cmdfile;
unlink $cmdfile;
', 
description => 'Use this procedure to show the perl double Path',
#shell => 'ec-perl'
shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->createProcedure("doubleEnv", "doubleEnvFixPerl", {description => 'Use this procedure to show the double perl environment fix', resourceName => "local"});
$ec->createStep("doubleEnv", "doubleEnvFixPerl", "Correct Double Env", {parallel => 1, command => '
my $cmdfile = "ShowSetCorrected.cmd";
open CMD, ">$cmdfile" or die("Error: Opening cmd file $cmdfile; aborting!\n");
print CMD "set";
close CMD;
print "showing before environment in ", $cmdfile, "\n";
system $cmdfile;
# Delete and reset each Perl ENV (which converts to UPPER case)
foreach my $key (sort keys %ENV) { my $value = $ENV{$key}; delete $ENV{$key}; $ENV{$key} = $value; }; 
print "showing after environment in ", $cmdfile, "\n";
system $cmdfile;
unlink $cmdfile;
', 
description => 'Use this procedure to show the double Path',
#shell => 'ec-perl'
shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});
$ec->runProcedure("doubleEnv", { procedureName => 'doubleEnvCmd', });
$ec->runProcedure("doubleEnv", { procedureName => 'doubleEnvPerl', });
$ec->runProcedure("doubleEnv", { procedureName => 'doubleEnvFixPerl', });
