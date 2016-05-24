use ElectricCommander ();
$ec = new ElectricCommander->new();
use XML::XPath;
my $osname = $^O;
$my_job="$[/myJob/jobName]";
$xPath=$ec->setProperty("BUILD_ON","1",
          {"jobId"=>"$my_job"});
 my $mycode= $xPath->findvalue('//code');
 die ( "Failed to set $my_job BUILD_SYSTEM - $code \n") if ( $code );
exit(0);
