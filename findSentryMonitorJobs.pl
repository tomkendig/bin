$|=1;
use utf8;
use Data::Dumper;
use ElectricCommander;

our $ec = new ElectricCommander();
$ec->abortOnError(0);
$ec->login();
print "Connected to server " . $ec->{server} . "\n";

my @filter = ();
my @projectFilter = ();
my @procedureFilter = ();
my @selects = ();

push (@projectFilter, {"propertyName" => "projectName",
                       "operator" => "equals",
                       "operand1" => "Electric Cloud"});

push (@procedureFilter, {"propertyName" => "procedureName",
                         "operator" => "like",
                         "operand1" => "%ElectricSentry"});

push (@procedureFilter, {"propertyName" => "procedureName",
                         "operator" => "equals",
                         "operand1" => "MultipleRunSentry"});

push (@procedureFilter, {"propertyName" => "procedureName",
                         "operator" => "equals",
                         "operand1" => "RunSentry"});

push (@filter, {"propertyName" => "projectName",
                "operator" => "equals",
                "operand1" => "Electric Cloud"});
                
push (@filter, {"operator" => "or",
                "filter" => \@procedureFilter});

#push (@selects,  {propertyName  => 'projectList'});
#push (@selects,  {propertyName  => 'SentrySchedules'});

print "findObjects " . Dumper({filter => \@filter,
#                              select  => \@selects 
                              }) . "\n";

my $xpath = $ec->findObjects("job", {filter => \@filter,
                                     select => \@selects
});

print "\nFindObjects Results:\n";
printXPath($xpath);

print "\nSentry Monitor Jobs:\n";
my $obNodeset = $xpath->find('//response/object/job');
foreach my $node ($obNodeset->get_nodelist) {
    my $projectName = $xpath->findvalue('projectName', $node);
    my $scheduleName = $xpath->findvalue('scheduleName', $node);
    my $jobName = $xpath->findvalue('jobName', $node);
    my $jobId = $xpath->findvalue('jobId', $node);
    my $elapsed = $xpath->findvalue('elapsedTime', $node);

    print "\n\nProject: $projectName\nSchedule: $scheduleName\nJob: $jobName $jobId\nElapsed: $elapsed\n";   

    my $propertiesXpath = $ec->getProperties({jobId => "$jobId", recurse => "1"});
    print "Sentry Job Properties:\n";
    printXPath($propertiesXpath);
}

sub printXPath($) {
    my ($xpath) = @_;
    print "\n" . $xpath->findnodes_as_string("/") . "\n";
}
