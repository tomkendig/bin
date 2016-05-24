# Create a project called "ExitCode1"  & change server name to your installation
use ElectricCommander ();
$ec = new ElectricCommander->new({
   server      =>  "cirrus1",     
   port        =>  "8000",       
   securePort  =>  "8443",
   });

   $ec->login('admin', 'changeme');
   #create procedure
   $ec->createProcedure("ExitCode1", "a", {description => "One procedure, many steps, many resources, windows echo"});
   $ec->createProcedure("ExitCode1", "b", {description => "One procedure, many steps, many resources, cygwin echo"});
   $ec->createProcedure("ExitCode1", "c", {description => "One procedure, many steps, many resources, ectool echo (i.e. version)"});
   #create steps for procedure
   for (2..200) {
      $ec->createResource("ExitCodeA$_", { hostName => 'localhost' });
      $ec->createResource("ExitCodeB$_", { hostName => 'localhost' });
      $ec->createResource("ExitCodeC$_", { hostName => 'localhost' });
      $ec->createStep("ExitCode1", "a", "a_step_$_", {command => 'echo "project exit code 1"', resourceName => "ExitCodeA$_", parallel => 1});
      $ec->createStep("ExitCode1", "b", "b_step_$_", {command => 'c:\usr\bin\echo "project exit code 1"', resourceName => "ExitCodeB$_", parallel => 1});
      $ec->createStep("ExitCode1", "c", "c_step_$_", {command => 'ectool --version"', resourceName => "ExitCodeC$_", parallel => 1});
   }
#   for (2..200) {
#      $ec->deleteResource("ExitCodeA$_", { hostName => 'localhost' });
#      $ec->deleteResource("ExitCodeB$_", { hostName => 'localhost' });
#      $ec->deleteResource("ExitCodeC$_", { hostName => 'localhost' });
#   }
