#!/usr/local/perl
# Before runing this script:
#0) must use the perl with pack ElectricCommander, on windows: /c/Program Files/Electric Cloud/ElectricCommander/perl/bin/perl
#1) Be sure to have deleted the projects called "CmdrResourceStressTests" & "CmdrResourceStressTestMgr"
#2) set the workspace named "default" and "remote" to point to how and where you want.
#3) if you want, change server name ("localhost") to your node of choice
#
#There are two adjustments to be made - for unix - wish to be transperent on windows.
# 1) have to insert a 'use lib "/opt/electriccloud/electriccommander/bin";' before use ElectricCommander
# 2) perl path is just perl on unix - windows has it's own perl location.
#
#use lib "/opt/electriccloud/electriccommander/bin";
use ElectricCommander ();
$ec = new ElectricCommander->new("localhost");
   $ec->login('admin', 'changeme');

   $ec->createProject("CmdrResourceStressTestMgr", {description => "Manage the Product CmdrResourceStressTests", workspaceName => "default"});
   $ec->createProcedure("CmdrResourceStressTestMgr", "ASanityCheck", {description => 'Use this procedure to make sure setup works - checking out the workspaces "default" and "network"
The local (default) workspace is normally of the form with "Drive Path" and "UNC Path" matching entries like "C:\EcWorkspace"
The network workspace is normally of the form with "Drive Path" entry like N: and  "UNC Path" entry like "//myhost/EcWorkspace"
'});
   $ec->createStep("CmdrResourceStressTestMgr", "ASanityCheck", "TryEcholocal", {command => 'echo "TryEchoLocal"', resourceName => "local", workspaceName => "default", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "ASanityCheck", "TryEchoNetwork", {command => 'echo "TryEchoNetwork"', resourceName => "local", workspaceName => "network", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "CreateResources", {description => "setup lots of resources"});
   $ec->createStep("CmdrResourceStressTestMgr", "CreateResources", "localResources", {command => '
#use lib "/opt/electriccloud/electriccommander/bin";
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
for (1..200) {
   $ec->createResource("MrLe$_", { hostName => "localhost" });
   $ec->createResource("MrCe$_", { hostName => "localhost" });
   $ec->createResource("MrEe$_", { hostName => "localhost" });
}
', 
#resourceName => "local", shell => 'ec-perl'
resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("CmdrResourceStressTestMgr", "PopulateStressTests", {description => "generate all the Stress Tests"});
   $ec->createStep("CmdrResourceStressTestMgr", "PopulateStressTests", "localResources", {command => '
   #use lib "/opt/electriccloud/electriccommander/bin";
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
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwLe", {description => "many resources, local resource, local workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwCe", {description => "many resources, local resource, local workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwEe", {description => "many resources, local resource, local workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrLwMe", {description => "single resources, local resource, local workspace, mixed echo (i.e. local echo and ectool version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrLwMe", {description => "many resources, local resource, local workspace, mixed echo (i.e. local echo and ectool version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwLe", {description => "single resource, local resource, network workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwCe", {description => "single resource, local resource, network workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwEe", {description => "single resource, local resource, network workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwLe", {description => "many resources, local resource, network workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwCe", {description => "many resources, local resource, network workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTests", "MrLrNwEe", {description => "many resources, local resource, network workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTests", "SrLrNwMe", {description => "single resources, local resource, network workspace, mixed echo (i.e. local echo and ectool version)"});
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
#resourceName => "local", shell => 'ec-perl'
resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("CmdrResourceStressTestMgr", "RemoveResources", {description => "cleanup lots of resources"});
   $ec->createStep("CmdrResourceStressTestMgr", "RemoveResources", "localResources", {command => '
#use lib "/opt/electriccloud/electriccommander/bin";
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
for (1..200) {
   $ec->deleteResource("MrLe$_");
   $ec->deleteResource("MrCe$_");
   $ec->deleteResource("MrEe$_");
}
', 
#resourceName => "local", shell => 'ec-perl'
resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("CmdrResourceStressTestMgr", "RemoveStressTests", {description => "cleanup the CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "RemoveStressTests", "localResources", {command => '
#use lib "/opt/electriccloud/electriccommander/bin";
use ElectricCommander ();
$ec = new ElectricCommander->new();
$ec->login("admin", "changeme");
$ec->createProject("CmdrResourceStressTestMgr", {description => "Manage the Product CmdrResourceStressTests"});
$ec->DeleteProject("CmdrResourceStressTests", {description => "Remove the CmdrResourceStressTest and all the job log files associated with the Project"});
', 
#resourceName => "local", shell => 'ec-perl'
resourceName => "local", shell => '"$[/server/Electric Cloud/installDirectory]/perl/bin/perl"'
});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinSinPar", {description => "Try each of the Windows Single Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinPar", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinSinSeq", {description => "Try each of the Linux Single Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinSinSeq", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinSinPar", {description => "Try each of the Windows Single Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrNwEe", {subprocedure => "SrNrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinSinParFail", {description => "Try each of the FAIL Windows Single Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrNwEe", {subprocedure => "SrNrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinSinSeq", {description => "Try each of the Windows Single Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrLwLe", {subprocedure => "SrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrLwCe", {subprocedure => "SrLrLwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrNwLe", {subprocedure => "SrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrNwCe", {subprocedure => "SrLrNwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinSeq", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinSinPar", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});

   $ec->createProcedure("CmdrResourceStressTestMgrFail", "BatteryWinSinSeq", {description => "Try each of the FAIL Windows Single Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinSeqFail", "SrLrLwEe", {subprocedure => "SrLrLwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinSeqFail", "SrLrNwEe", {subprocedure => "SrLrNwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrLwMe", {subprocedure => "SrLrLwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinSinParFail", "SrLrNwMe", {subprocedure => "SrLrNwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinMulPar", {description => "Try each of the Linux Multiple Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulPar", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinMulSeq", {description => "Try each of the Linux Multiple Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMulSeq", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinMulPar", {description => "Try each of the Windows Multiple Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulPar", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1, stepCondition => 0});

   $ec->createProcedure("CmdrResourceStressTestMgrFail", "BatteryWinMulPar", {description => "Try each of the FAIL Windows Multiple Resource stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulParFail", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulParFail", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinMulSeq", {description => "Try each of the Windows Multiple Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrLwLe", {subprocedure => "MrLrLwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrLwCe", {subprocedure => "MrLrLwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrNwLe", {subprocedure => "MrLrNwLe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrNwCe", {subprocedure => "MrLrNwCe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMulSeq", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests", stepCondition => 0});

   $ec->createProcedure("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", {description => "Try each of the FAIL Windows Multiple Resource stress tests Sequentially"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrLwEe", {subprocedure => "MrLrLwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrNwEe", {subprocedure => "MrLrNwEe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrLwMe", {subprocedure => "MrLrLwMe", subproject => "CmdrResourceStressTests"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMulSeqFail", "MrLrNwMe", {subprocedure => "MrLrNwMe", subproject => "CmdrResourceStressTests"});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinMaxSeq", {description => "Do all the Linux stress tests Sequentually"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMaxSeq", "BatteryLinSinSeq", {subprocedure => "BatteryLinSinSeq", subproject => "CmdrResourceStressTestMgr"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMaxSeq", "BatteryLinMulSeq", {subprocedure => "BatteryLinMulSeq", subproject => "CmdrResourceStressTestMgr"});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryLinMaxPar", {description => "Do all the Linux stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMaxPar", "BatteryLinSinPar", {subprocedure => "BatteryLinSinPar", subproject => "CmdrResourceStressTestMgr", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryLinMaxPar", "BatteryLinMulPar", {subprocedure => "BatteryLinMulPar", subproject => "CmdrResourceStressTestMgr", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinMaxSeq", {description => "Do all the Windows stress tests Sequentually"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMaxSeq", "BatteryWinSinSeq", {subprocedure => "BatteryWinSinSeq", subproject => "CmdrResourceStressTestMgr"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMaxSeq", "BatteryWinMulSeq", {subprocedure => "BatteryWinMulSeq", subproject => "CmdrResourceStressTestMgr"});

   $ec->createProcedure("CmdrResourceStressTestMgr", "BatteryWinMaxPar", {description => "Do all the Windows stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMaxPar", "BatteryWinSinPar", {subprocedure => "BatteryWinSinPar", subproject => "CmdrResourceStressTestMgr", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgr", "BatteryWinMaxPar", "BatteryWinMulPar", {subprocedure => "BatteryWinMulPar", subproject => "CmdrResourceStressTestMgr", parallel => 1});

   $ec->createProcedure("CmdrResourceStressTestMgrFail", "BatteryWinMaxSeq", {description => "Do all the FAIL Windows stress tests Sequentually"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMaxSeqFail", "BatteryWinSinSeqFail", {subprocedure => "BatteryWinSinSeqFail", subproject => "CmdrResourceStressTestMgrFail"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMaxSeqFail", "BatteryWinMulSeqFail", {subprocedure => "BatteryWinMulSeqFail", subproject => "CmdrResourceStressTestMgrFail"});

   $ec->createProcedure("CmdrResourceStressTestMgrFail", "BatteryWinMaxPar", {description => "Do all the FAIL Windows stress tests in Parallel"});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMaxParFail", "BatteryWinSinParFail", {subprocedure => "BatteryWinSinParFail", subproject => "CmdrResourceStressTestMgrFail", parallel => 1});
   $ec->createStep("CmdrResourceStressTestMgrFail", "BatteryWinMaxParFail", "BatteryWinMulParFail", {subprocedure => "BatteryWinMulParFail", subproject => "CmdrResourceStressTestMgrFail", parallel => 1});
