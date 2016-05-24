# This example is a test script to run very basic EC setup
use strict;
use ElectricCommander ();

my $user;
my $pw;

print "This is a test program\n";

#my $N=new ElectricCommander("c-ssanga");
my $N=new ElectricCommander();
$N->login($user, $pw);
