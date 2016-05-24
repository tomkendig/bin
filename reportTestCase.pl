#use strict;
$| = 1;
#check the regular expression subsitution
use ElectricCommander;
$ECommander = new ElectricCommander->new("localhost");
$ECommander->login('admin', 'changeme');
my $propertyPath = "/user/admin";
$ECommander->abortOnError(0);
my $xPath = $ECommander->getProperty($propertyPath);
$propertyPath = "/users/admin";
$xPath = $ECommander->getProperty($propertyPath);
$propertyPath = "/user/admin";
$xPath = $ECommander->getProperty($propertyPath);
