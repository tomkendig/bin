# Create a project called "ExitCode1"  & change server name to your installation
use ElectricCommander ();
$ec = new ElectricCommander->new();

   $ec->login('admin', 'changeme');
   #create procedure
   $ec->createProcedure("Testing", "a", {description => "One procedure, many steps, many resources, windows echo"});
   $ec->createProcedure("Testing", "b", {description => "One procedure, many steps, many resources, cygwin echo"});
   #create steps for procedure
   for (2..4) {
      $ec->createStep("Testing", "a", "a_step_$_", {command => 'echo "project exit code 1"', resourceName => "ExitCodeA$_", parallel => 1});
      $ec->createStep("Testing", "b", "b_step_$_", {command => 'c:\usr\bin\echo "project exit code 1"', resourceName => "ExitCodeB$_", parallel => 1});
   }
