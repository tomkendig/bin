#!/usr/local/perl
# Before runing this script:
#0) use ec-perl to run this script
#1) Be sure to have deleted the projects called "CmdrCreateDeleteRate" & "Performance"
#2) set the workspace named "default" and "remote" to point to how and where you want.
#3) if you want, change server name ("localhost") to your node of choice
#
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
   $ec->login('admin', 'changeme');

   $ec->createProject("Performance", {description => "Manage the Product CmdrResourceStressTests", workspaceName => "default"});
   $ec->createProcedure("Performance", "CreateSteps", {description => 'Use this procedure to create "
The local (default) workspace is normally of the form with "Drive Path" and "UNC Path" matching entries like "C:\EcWorkspace"
The network workspace is normally of the form with "Drive Path" entry like N: and  "UNC Path" entry like "//myhost/EcWorkspace"
'});
   $ec->createStep("Performance", "ASanityCheck", "TryEcholocal", {command => 'echo "TryEchoLocal"', resourceName => "local", workspaceName => "default", parallel => 1});
   $ec->createStep("Performance", "ASanityCheck", "TryEchoNetwork", {command => 'echo "TryEchoNetwork"', resourceName => "local", workspaceName => "network", parallel => 1});

   $ec->createProcedure("Performance", "CreateResources", {description => "setup lots of resources"});
   $ec->createStep("Performance", "CreateResources", "localResources", {command => '
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
for (1..200) {
   $ec->createResource("MrLe$_", { hostName => "localhost" });
   $ec->createResource("MrCe$_", { hostName => "localhost" });
   $ec->createResource("MrEe$_", { hostName => "localhost" });
}
', 
resourceName => "local",
#shell => '$[/javascript if (navigator.appVersion.indexOf("win")) "$[/server/Electric Cloud/installDirectory]/perl/bin/perl"; else "ec-perl";]'
shell => 'ec-perl'
#shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("Performance", "PopulateStressTests", {description => "generate all the Stress Tests"});
   $ec->createStep("Performance", "PopulateStressTests", "localResources", {command => '
   use ElectricCommander ();
   $ec = new ElectricCommander->new();
   $ec->login("admin", "changeme");
   $ec->createProject("CmdrResourceStressTests", {description => "These procedures will stress the resources. Steps are always in parallel.
Using these definitions:
Muliple Resource (Mr) or Single Resource (Sr)
Local Resource (Lr) or Remote Resource (Rr)
Local Workspace (Lw) or Network Workspace (Nw)
Local Echo - shell or windows (Le) Cygwin Echo (Ce) Ectool Echo i.e. version (Ee) Mixed Echo (Me) Le and Ee alternating"
});

   $ec->createProcedure("CmdrResourceStressTests", "SrLrLwLe", {description => "single resource, local resource, local workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrLwCe", {description => "single resource, local resource, local workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrLwEe", {description => "single resource, local resource, local workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrLwMe", {description => "single resources, local resource, local workspace, mixed echo (i.e. local echo and ectool version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwLe", {description => "many resources, local resource, local workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwCe", {description => "many resources, local resource, local workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwEe", {description => "many resources, local resource, local workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwMe", {description => "many resources, local resource, local workspace, mixed echo (i.e. local echo and ectool version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwLe", {description => "single resource, local resource, network workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwCe", {description => "single resource, local resource, network workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwEe", {description => "single resource, local resource, network workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwMe", {description => "single resources, local resource, network workspace, mixed echo (i.e. local echo and ectool version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwLe", {description => "many resources, local resource, network workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwCe", {description => "many resources, local resource, network workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwEe", {description => "many resources, local resource, network workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwMe", {description => "many resources, local resource, network workspace, mixed echo (i.e. local echo and ectool version)"});
   #create steps for procedures
   for (1..200) {
      $ec->createStep("CmdrResourceStressTests", "SrLrLwLe", "SrLrLwLe_step_$_", {command => \'echo "SrLrLwLe"\', resourceName => "local", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrLwCe", "SrLrLwCe_step_$_", {command => \'c:\cygwin\bin\echo "SrLrLwCe"\', resourceName => "local", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrLwEe", "SrLrLwEe_step_$_", {command => \'ectool --version\', resourceName => "local", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrLwLe", "MrLrLwLe_step_$_", {command => \'echo "MrLrLwLe"\', resourceName => "MrLe$_", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrLwCe", "MrLrLwCe_step_$_", {command => \'c:\cygwin\bin\echo "MrLrLwCe"\', resourceName => "MrCe$_", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrLwEe", "MrLrLwEe_step_$_", {command => \'ectool --version\', resourceName => "MrEe$_", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrLwMe", "SrLrLwMeA_step_$_", {command => \'echo "SrLrLwMe"\', resourceName => "local", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrLwMe", "SrLrLwMeB_step_$_", {command => \'ectool --version\', resourceName => "local", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrLwMe", "MrLrLwMeA_step_$_", {command => \'echo "MrLrLwMe"\', resourceName => "MrLe$_", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrLwMe", "MrLrLwMeB_step_$_", {command => \'ectool --version\', resourceName => "MrEe$_", workspaceName => "default", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrNwLe", "SrLrNwLe_step_$_", {command => \'echo "SrLrNwLe"\', resourceName => "local", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrNwCe", "SrLrNwCe_step_$_", {command => \'c:\cygwin\bin\echo "SrLrNwCe"\', resourceName => "local", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrNwEe", "SrLrNwEe_step_$_", {command => \'ectool --version\', resourceName => "local", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrNwLe", "MrLrNwLe_step_$_", {command => \'echo "MrLrNwLe"\', resourceName => "MrLe$_", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrNwCe", "MrLrNwCe_step_$_", {command => \'c:\cygwin\bin\echo "MrLrNwCe"\', resourceName => "MrCe$_", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrNwEe", "MrLrNwEe_step_$_", {command => \'ectool --version\', resourceName => "MrEe$_", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrNwMe", "SrLrNwMeA_step_$_", {command => \'echo "SrLrNwMe"\', resourceName => "local", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "SrLrNwMe", "SrLrNwMeB_step_$_", {command => \'ectool --version\', resourceName => "local", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrNwMe", "MrLrNwMeA_step_$_", {command => \'echo "MrLrNwMe"\', resourceName => "MrLe$_", workspaceName => "network", parallel => 1});
      $ec->createStep("CmdrResourceStressTests", "MrLrNwMe", "MrLrNwMeB_step_$_", {command => \'ectool --version\', resourceName => "MrEe$_", workspaceName => "network", parallel => 1});
   }
', 
resourceName => "local", shell => 'ec-perl'
#resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("Performance", "RemoveResources", {description => "cleanup lots of resources"});
   $ec->createStep("Performance", "RemoveResources", "localResources", {command => '
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
for (1..200) {
   $ec->deleteResource("MrLe$_");
   $ec->deleteResource("MrCe$_");
   $ec->deleteResource("MrEe$_");
}
', 
resourceName => "local", shell => 'ec-perl'
#resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("Performance", "EstablishStressSchedule", {description => "Run this Procedure to setup the stress test schedules"});
   $ec->createStep("Performance", "EstablishStressSchedule", "localResources", {command => '
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
$ec->createSchedule("CmdrResourceStressTests", "SrLrLwLe", {
description => "simples stress test",
startTime => "00:00",
stopTime => "23:59",
interval => "2",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "SrLrLwLe",
});
$ec->createSchedule("CmdrResourceStressTests", "SrLrNwLe", {
description => "simples stress test",
startTime => "00:00",
stopTime => "23:59",
interval => "3",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "SrLrNwLe",
});
$ec->createSchedule("Performance", "BatteryLinMaxSeq", {
description => "some stress test",
startTime => "20:00",
stopTime => "20:01",
interval => "2",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "BatteryLinMaxSeq",
});
$ec->createSchedule("Performance", "BatteryLinMaxPar", {
description => "most stress test",
startTime => "21:00",
stopTime => "21:01",
interval => "2",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "BatteryLinMaxPar",
});
$ec->createSchedule("Performance", "BatteryLinMaxSeqFail", {
description => "some stress fail test",
startTime => "22:00",
stopTime => "22:01",
interval => "2",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "BatteryLinMaxSeqFail",
});
$ec->createSchedule("Performance", "BatteryLinMaxParFail", {
description => "most stress fail test",
startTime => "23:00",
stopTime => "23:01",
interval => "2",
intervalUnits => "minutes",
weekDays => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
procedureName => "BatteryLinMaxParFail",
});
', 
resourceName => "local", shell => 'ec-perl'
#resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("Performance", "RemoveStressTests", {description => "cleanup the CmdrResourceStressTests"});
   $ec->createStep("Performance", "RemoveStressTests", "localResources", {command => '
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
$ec->createProject("Performance", {description => "Manage the Product CmdrResourceStressTests"});
$ec->DeleteProject("CmdrResourceStressTests", {description => "Remove the CmdrResourceStressTest and all the job log files associated with the Project"});
', 
resourceName => "local", shell => 'ec-perl'
#resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("Performance", "BatteryLinSinPar", {description => "Try each of the Windows Single Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinSinPar", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("Performance", "BatteryLinSinSeq", {description => "Try each of the Linux Single Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinSinSeq", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("Performance", "BatteryWinSinPar", {description => "Try each of the Windows Single Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrNwEe", {subprocedure => "SrNrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinSinPar", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});

   $ec->createProcedure("Performance", "BatteryWinSinParFail", {description => "Try each of the FAIL Windows Single Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinSinParFail", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("Performance", "BatteryWinSinSeq", {description => "Try each of the Windows Single Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinSinSeq", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", condition => 0});

   $ec->createProcedure("Performance", "BatteryWinSinSeqFail", {description => "Try each of the FAIL Windows Single Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinSinSeqFail", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("Performance", "BatteryLinMulPar", {description => "Try each of the Linux Multiple Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMulPar", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("Performance", "BatteryLinMulSeq", {description => "Try each of the Linux Multiple Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryLinMulSeq", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("Performance", "BatteryWinMulPar", {description => "Try each of the Windows Multiple Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});
   $ec->createStep("Performance", "BatteryWinMulPar", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1, condition => 0});

   $ec->createProcedure("Performance", "BatteryWinMulParFail", {description => "Try each of the FAIL Windows Multiple Resource stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMulParFail", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("Performance", "BatteryWinMulSeq", {description => "Try each of the Windows Multiple Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", condition => 0});
   $ec->createStep("Performance", "BatteryWinMulSeq", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", condition => 0});

   $ec->createProcedure("Performance", "BatteryWinMulSeqFail", {description => "Try each of the FAIL Windows Multiple Resource stress tests Sequentially"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("Performance", "BatteryWinMulSeqFail", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("Performance", "BatteryLinMaxSeq", {description => "Do all the Linux stress tests Sequentually"});
   $ec->createStep("Performance", "BatteryLinMaxSeq", "BatteryLinSinSeq", {subprocedure => "BatteryLinSinSeq", subproject => "Performance"});
   $ec->createStep("Performance", "BatteryLinMaxSeq", "BatteryLinMulSeq", {subprocedure => "BatteryLinMulSeq", subproject => "Performance"});

   $ec->createProcedure("Performance", "BatteryLinMaxPar", {description => "Do all the Linux stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryLinMaxPar", "BatteryLinSinPar", {subprocedure => "BatteryLinSinPar", subproject => "Performance", parallel => 1});
   $ec->createStep("Performance", "BatteryLinMaxPar", "BatteryLinMulPar", {subprocedure => "BatteryLinMulPar", subproject => "Performance", parallel => 1});

   $ec->createProcedure("Performance", "BatteryWinMaxSeq", {description => "Do all the Windows stress tests Sequentually"});
   $ec->createStep("Performance", "BatteryWinMaxSeq", "BatteryWinSinSeq", {subprocedure => "BatteryWinSinSeq", subproject => "Performance"});
   $ec->createStep("Performance", "BatteryWinMaxSeq", "BatteryWinMulSeq", {subprocedure => "BatteryWinMulSeq", subproject => "Performance"});

   $ec->createProcedure("Performance", "BatteryWinMaxPar", {description => "Do all the Windows stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinMaxPar", "BatteryWinSinPar", {subprocedure => "BatteryWinSinPar", subproject => "Performance", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMaxPar", "BatteryWinMulPar", {subprocedure => "BatteryWinMulPar", subproject => "Performance", parallel => 1});

   $ec->createProcedure("Performance", "BatteryWinMaxSeqFail", {description => "Do all the FAIL Windows stress tests Sequentually"});
   $ec->createStep("Performance", "BatteryWinMaxSeqFail", "BatteryWinSinSeqFail", {subprocedure => "BatteryWinSinSeqFail", subproject => "Performance"});
   $ec->createStep("Performance", "BatteryWinMaxSeqFail", "BatteryWinMulSeqFail", {subprocedure => "BatteryWinMulSeqFail", subproject => "Performance"});

   $ec->createProcedure("Performance", "BatteryWinMaxParFail", {description => "Do all the FAIL Windows stress tests in Parallel"});
   $ec->createStep("Performance", "BatteryWinMaxParFail", "BatteryWinSinParFail", {subprocedure => "BatteryWinSinParFail", subproject => "Performance", parallel => 1});
   $ec->createStep("Performance", "BatteryWinMaxParFail", "BatteryWinMulParFail", {subprocedure => "BatteryWinMulParFail", subproject => "Performance", parallel => 1});
