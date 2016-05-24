#use strict;
$| = 1;
#check the regular expression subsitution
my $reportUrl = "https://a/commander/link/projectDetails?projectName=coe_ind_proj_pdit1&objectId=project-1396&filterName=projectsPageSearch&tabGroup=reportsHeader&s=Projects";
print "before $reportUrl\n";
$reportUrl =~ s/\/projectDetails\?projectName\=/\/projectDetails\/projects\//;
print "after  $reportUrl\n";

use ElectricCommander;
$ECommander = new ElectricCommander->new("localhost");
$ECommander->login('admin', 'changeme');

#consider all users
my $xPath = $ECommander->getUsers();
#my ($success, $xPath) = InvokeCommander("SuppressLog", "getUsers");
my $nodeset1 = $xPath->find('//user');
foreach my $user ($nodeset1->get_nodelist) {
  my $userName = $xPath->findvalue('userName', $user);
  print "processing user $userName\n";

  #consider all shortcut properties
  my $propertyRootPath = "/users/" . $userName . "/userSettings/shortcuts";
  #my ($success, $xPathPropertySheet) = InvokeCommander("SuppressLog IgnoreError", "getProperty", $propertyRootPath);
  $ECommander->abortOnError(0);
  my $xPathPropertySheet = $ECommander->getProperty($propertyUrlRootPath);
  #$ECommander->abortOnError(1);
  print "property $propertyRootPath\n";
  #only proceed if the shortcut propertysheet exists
  if ($xPathPropertySheet) {
    #consider each of the shortcuts
    my $xPath = $ECommander->getProperties({path => $propertyRootPath});
    #my ($success, $xPath) = InvokeCommander("SuppressLog", "getProperties", {path => $propertyRootPath});
    my $nodeset2 = $xPath->find('//property');
    foreach my $property ($nodeset2->get_nodelist) {
      my $propertyName = $xPath->findvalue('propertyName', $property);
      my $propertyUrlRootPath = $propertyRootPath . "/" . $propertyName . "/url";
      #retreive the property value of "url", transform it and write it back
      #my ($success, $xPathProperty) = InvokeCommander("SuppressLog IgnoreError", "getProperty", $propertyUrlRootPath);
      $ECommander->abortOnError(0);
      my $xPathProperty= $ECommander->getProperty($propertyUrlRootPath);
      #$ECommander->abortOnError(1);
      print "property name $propertyName with path $propertyUrlRootPath\n";
      #only proceed if the url property exists
      if ($xPathProperty) {
        #my $nodeset3 = $xPath->find('//property');
        my $propertyValueNew = $propertyValue = $xPathProperty->findvalue('//value');
        $propertyValueNew =~ s/\/projectDetails\?projectName\=/\/projectDetails\/projects\//;
        print "path $propertyUrlRootPath with value\nNew $propertyValueNew\nOld $propertyValue\n";
        #my ($success, $xPathProperty) = InvokeCommander("SuppressLog", "setProperty", $propertyUrlRootPath, $propertyValueNew);
        #my $message = $xPathProperty->findnodes_as_string('/');
        #print "$message\n";
        #foreach my $property ($nodeset3->get_nodelist) {
        #  my $propertyValue = $xPath->findvalue('value', $property);
        #}
      }
    }
  }
}

#-------------------------------------------------------------------------
#  Run an ElectricCommander function using the Perl API
#
#  Params
#       optionFlags - "AllowLog" or "SuppressLog" or "SuppressResult"
#                     combined with "IgnoreError"
#       commanderFunction
#       Variable Parameters
#           The parameters required by the ElectricCommander function
#           according to the Perl API. See the ElectricCommander
#           Help system for more information.
#               (the functions and paramenter are based on "ectool" - run it for documentation)
#
#  Returns
#       success     - 1 if no error was detected
#       xPath       - an XML::XPath object with the result.
#       errMsg      - a message string extracted from Commander on error
#
#-------------------------------------------------------------------------
sub InvokeCommander {

    my $optionFlags = shift;
    my $commanderFunction = shift;
    my $xPath;
    my $success = 1;

    my $bSuppressLog = $optionFlags =~ /SuppressLog/i;
    my $bSuppressResult = $bSuppressLog || $optionFlags =~ /SuppressResult/i;
    my $bIgnoreError = $optionFlags =~ /IgnoreError/i;

    #  Run the command
    print "Request to Commander: $commanderFunction\n" unless ($bSuppressLog);

    $ECommander->abortOnError(0) if $bIgnoreError;
    $xPath = $ECommander->$commanderFunction(@_);
    $ECommander->abortOnError(1) if $bIgnoreError;

    # Check for error return
    my $errMsg = $ECommander->checkAllErrors($xPath);
    if ($errMsg ne "") {

        $success = 0;
    }
    if ($xPath) {

        print "Return data from Commander:\n" .
               $xPath->findnodes_as_string("/") . "\n"
            unless $bSuppressResult;
    }

    # Return the result
    return ($success, $xPath, $errMsg);
}
