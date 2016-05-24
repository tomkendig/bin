#!/usr/sh -xf
for dir in `\ls`; do if [ -d $dir ]; then (cd $dir; perl -e 'foreach my $file (glob "commander*") { my $newfile = $file; $newfile =~ s/commander/cmdr/; rename $file, $newfile; }' ); fi; done
perl -e 'print "mark\n";'
exit
