# This example is a check of the default value of findObjects
use ElectricCommander ();
my @filterList;
push (@filterList, {"propertyName" => "jobName",
                    "operator" => "like",
                    "operand1" => "%job%"});
push (@filterList, {"propertyName" => "jobName",
                    "operator" => "like",
                    "operand1" => "EC%"});
my $result = $cmdr->findObjects('job', 
				{maxIds => "10",
				filter => [ { operator => 'or', filter => \@filterList, } ]}
				);
print "result = " . $result->findnodes_as_string("/") . "\n";

my $result = $cmdr->findObjects('job', 
				{maxIds => "0",
				filter => [ { operator => 'or', filter => \@filterList, } ]}
				);
print "result = " . $result->findnodes_as_string("/") . "\n";

my $result = $cmdr->findObjects('job', 
				{filter => [ { operator => 'or', filter => \@filterList, } ]}
				);
print "result = " . $result->findnodes_as_string("/") . "\n";
