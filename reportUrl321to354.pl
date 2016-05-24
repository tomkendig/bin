#use strict;
$| = 1;
# Version 1.2 - new regular expression substitution
# Version 1.1 - new user maximum, coding error on getPropertyPath
# Version 1.0 - first delivery
# script to change URLs on each user's saved setting in release 3.2 format to values in release 3.5 format
#check the regular expression subsitution
my $reportUrl = "https://a/commander/link/projectDetails?projectName=coe_ind_proj_pdit1&objectId=project-1396&filterName=projectsPageSearch&tabGroup=reportsHeader&s=Projects";
print "before $reportUrl\n";
$reportUrl =~ s/projectDetails\?projectName\=/\/projectDetails\/projects\//;
$reportUrl =~ s/\&objectId\=/\?objectId\=/;
$reportUrl =~ s/\&objectId\=/\?objectId\=/;
print "after  $reportUrl\n";

use ElectricCommander;
$ECommander = new ElectricCommander->new("localhost");
$ECommander->login('admin', 'changeme');
$ECommander->abortOnError(0); # have to turn error handling off or none existent properties are printed to screen and stop script

#consider all users
my $xPath = $ECommander->getUsers({maximum=>10000});
my $nodeset1 = $xPath->find('//user');
foreach my $user ($nodeset1->get_nodelist) {
  my $userName = $xPath->findvalue('userName', $user);
  print "processing user $userName\n";

  #consider all shortcut properties
  my $propertyRootPath = "/users/" . $userName . "/userSettings/shortcuts";
  my $xPathPropertySheet = $ECommander->getProperty($propertyRootPath);
  print "property $propertyRootPath\n";
  #only proceed if the shortcut propertysheet exists
  if ($xPathPropertySheet) {
    #consider each of the shortcuts. Clone will work to save the propertysheet after release 3.6
    my $propertyCloneName = "/users/" . $userName . "/userSettings/shortcuts.sav";
    #my $xCloneReturn = $ECommander->clone({path=>$propertyRootPath, cloneName=>$propertyCloneName});
    my $xPath = $ECommander->getProperties({path => $propertyRootPath});
    my $nodeset2 = $xPath->find('//property');
    foreach my $property ($nodeset2->get_nodelist) {
      my $propertyName = $xPath->findvalue('propertyName', $property);
      my $propertyUrlRootPath = $propertyRootPath . "/" . $propertyName . "/url";
      #retreive the property value of "url", transform it and write it back
      my $xPathProperty= $ECommander->getProperty($propertyUrlRootPath);
      print "property name $propertyName with path $propertyUrlRootPath\n";
      #only proceed if the url property exists
      if ($xPathProperty) {
        #my $nodeset3 = $xPath->find('//property');
        my $propertyValueNew = $propertyValue = $xPathProperty->findvalue('//value');
        $propertyValueNew =~ s/projectDetails\?projectName\=/\/projectDetails\/projects\//;
        $propertyValueNew =~ s/\&objectId\=/\?objectId\=/;
        print "path $propertyUrlRootPath with value\nNew $propertyValueNew\nOld $propertyValue\n";
        #my $xPath = $ECommander->setProperty($propertyUrlRootPath, $propertyValue);
      }
    }
  }
}
