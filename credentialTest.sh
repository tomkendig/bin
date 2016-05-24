#/bin/sh
ectool login admin changeme
ectool getCredential Testing root
#/opt/electriccloud/electriccommander/bin/ec-perl /net/f2home/tkendig/bin/CmdrResourceStressTest.pl
#/opt/electriccloud/electriccommander/bin/ec-perl -e 'print "Hello"; use ElectricCommander (); $ec = new ElectricCommander->new("localhost"); $ec->login('admin', 'changeme'); $xPath=$ec->getVersions(); print "Return:\n" . $xPath-> findnodes_as_string("/");'
#/opt/electriccloud/electriccommander/bin/ec-perl -e 'use ElectricCommander (); $ec = new ElectricCommander->new("localhost"); $ec->login('admin', 'changeme'); $xPath=$ec->getVersions(); print "Returns:\n" . $xPath-> findnodes_as_string("/");'
#/opt/electriccloud/electriccommander/bin/ec-perl -e 'use ElectricCommander (); $ec = new ElectricCommander->new("localhost"); $ec->login('admin', 'changeme'); $xPath=$ec->getCredential(projectName->"Testing"; credentialName->"root"); print "Returns:\n" . $xPath-> findnodes_as_string("/");'
/opt/electriccloud/electriccommander/bin/ec-perl -e 'use ElectricCommander (); $ec = new ElectricCommander->new("localhost"); $ec->login('admin', 'changeme'); $xPath=$ec->getCredential("Testing", "root"); print "getCredential returns:\n".$xPath-> findnodes_as_string("/")."\n";'
