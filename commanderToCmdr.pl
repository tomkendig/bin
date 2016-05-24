#!/usr/bin/env perl -w
foreach my $file (glob "commander*") { my $newfile = $file; $newfile =~ s/commander/cmdr/; print "rename $file, $newfile\n"; }
