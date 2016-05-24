# Execute script from Cygwin on a machine with Electric Commander installed
# The following 3 steps enable the remaining steps below behave as if run from ec-perl
#!/bin/sh
exec "c:/Program Files/Electric Cloud/ElectricCommander/bin/ec-perl" -x "`cygpath -m "$0"`" "${@}"
#!perl

use strict;
use ElectricCommander ();
$| = 1;

my $ec = new ElectricCommander->new();

for my $plugin ($ec->getPlugins()->find('//pluginName')->get_nodelist) {
	print "Plugin: ", $plugin->string_value(), "\n";
	for my $procedure ($ec->getProcedures($plugin->string_value())->find('//procedureName')->get_nodelist) {
#	for my $procedure ($ec->getProcedures("ECSCM-Git-1.2.3.43267")->find('//procedureName')->get_nodelist) {
		print " - ", $procedure->string_value(), "\n";
	}
	print "\n";
}
