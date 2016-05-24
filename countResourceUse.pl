use strict;
use ElectricCommander;
use Data::Dumper;

my $ec = ElectricCommander->new();

my @filterList;
push (@filterList, {'propertyName' => 'projectName',
    'operator' => 'notEqual',
    'operand1' => 'Electric Cloud'});

my $xpath = $ec->findObjects('procedure', {filter => \@filterList});
my %resources;

my $nodeset = $xpath->find('//procedure');
foreach my $node ($nodeset->get_nodelist) {
  my $procedureName = $xpath->findvalue('procedureName', $node);
  my $resourceName = $xpath->findvalue('resourceName', $node);
  if ($resourceName ne '') {
    $resources{$resourceName}{counter}++;
    $resources{$resourceName}{usedBy} .= "\n\t\t\tprocedure: $procedureName";
  }
}

print "Resource Name\tUsed\tUsed By\n\n";
foreach my $resourceName (keys %resources) {
  print "$resourceName\t";
  print "$resources{$resourceName}{counter}\t";
  print "$resources{$resourceName}{usedBy}\n";
}

#print(Data::Dumper->Dump([\%resources]));