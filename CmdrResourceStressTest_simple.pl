# Create a project called "CmdrResourceStressTest" & "CmdrResourceStressTestCreate" & change server name to your installation
use ElectricCommander ();
$ec = new ElectricCommander->new({
   server      =>  "cirrus10",
   port        =>  "8000",
   securePort  =>  "8443",
   });

   $ec->login('admin', 'changeme');
   #create procedures for:
   #Muliple Resource (Mr) or Single Resource (Sr)
   #Local Resource (Lr) or Remote Resource (Rr)
   #Local Workspace (Lw) or Network Workspace (Nw)
   #Local Echo - shell or windows (Le) Cygwin Echo (Ce) Ectool Echo i.e. version (Ee)
   $ec->createProcedure("CmdrResourceStressTest", "SrLrLwLe", {description => "single resource, local resource, local workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTest", "SrLrLwCe", {description => "single resource, local resource, local workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTest", "SrLrLwEe", {description => "single resource, local resource, local workspace, ectool echo (i.e. version)"});
   $ec->createProcedure("CmdrResourceStressTest", "MrLrLwLe", {description => "many resources, local resource, local workspace, local echo"});
   $ec->createProcedure("CmdrResourceStressTest", "MrLrLwCe", {description => "many resources, local resource, local workspace, cygwin echo"});
   $ec->createProcedure("CmdrResourceStressTest", "MrLrLwEe", {description => "many resources, local resource, local workspace, ectool echo (i.e. version)"});
   #create steps for procedure
   for (1..200) {
      $ec->createResource("MrLrLwWe$_", { hostName => 'localhost' });
      $ec->createResource("MrLrLwCe$_", { hostName => 'localhost' });
      $ec->createResource("MrLrLwEe$_", { hostName => 'localhost' });
      $ec->createStep("CmdrResourceStressTest", "SrLrLwWe", "SrLrLwWe_step_$_", {command => 'echo "SrLrLwWe"', resourceName => "MrLrLwWe1", parallel => 1});
      $ec->createStep("CmdrResourceStressTest", "SrLrLwCe", "SrLrLwCe_step_$_", {command => 'c:\cygwin\bin\echo "SrLrLwCe"', resourceName => "MrLrLwCe1", parallel => 1});
      $ec->createStep("CmdrResourceStressTest", "SrLrLwEe", "SrLrLwEe_step_$_", {command => 'ectool --version"', resourceName => "MrLrLwEe1", parallel => 1});
      $ec->createStep("CmdrResourceStressTest", "MrLrLwWe", "MrLrLwWe_step_$_", {command => 'echo "MrLwWe"', resourceName => "MrLrLwWe$_", parallel => 1});
      $ec->createStep("CmdrResourceStressTest", "MrLrLwCe", "MrLrLwCe_step_$_", {command => 'c:\cygwin\bin\echo "MrLrLwCe"', resourceName => "MrLrLwCe$_", parallel => 1});
      $ec->createStep("CmdrResourceStressTest", "MrLrLwEe", "MrLrLwEe_step_$_", {command => 'ectool --version"', resourceName => "MrLrLwEe$_", parallel => 1});
      #$ec->deleteResource("MrLrLwWe$_");
      #$ec->deleteResource("MrLrLwCe$_");
      #$ec->deleteResource("MrLrLwEe$_");
   }
