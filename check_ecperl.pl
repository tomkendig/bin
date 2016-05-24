#! perl
#
# Scan for job steps that do not have the right stuff in them
#

use strict;
use ElectricCommander ();
use XML::XPath;

my($ecperl) = "C:\\Program Files\\Electric Cloud\\ElectricCommander\\perl\\bin\\perl";

my($Ec);        # electric commander object

&main;

sub main {
    my(@params);

    if (!defined $ENV{COMMANDER_SERVER}) {
        die("Environment variable COMMANDER_SERVER is not set\n");
    }

    # Create an Ecommander object
    $Ec = new ElectricCommander->new();
    $Ec->abortOnError(0);

    # the call to getVersions is just to verify that we're logged in
    # this isn't strictly necessary if called from a jobstep
    my $xPath = $Ec->getVersions();
    $_ = $Ec->checkAllErrors($xPath);
    if ($_ ne "") {
        if ($_ =~ /no credentials/i || $_ =~ /expired/i) {
            print STDERR "$0:  not logged in to commander\n";
            print STDERR "  Use \"ectool login username password\" to establish a session\n";
            exit(1);
        } else {
            die($_);
        }
    }
    # end of login section

    &doScan();
}

# print a usage message and exit
sub usage {
    if (@_) {
        print STDERR "$0: @_\n";
    }
    print STDERR "add usage error message here\n";
    exit(1);
}

#
# collect information about the jobs in the system
#
sub doScan {
    my($project, $procedure, $step);

    for $project (&getProjects) {
        for $procedure (&getProcedures($project)) {
            for $step (&getSteps($project, $procedure)) {
                #if ($interesting{$step}) {
                    my($Xpath) = $Ec->getStep($project, $procedure, $step);
                    my($shell) = &getField($Xpath, "shell");
                    if ($shell =~ /\Q$ecperl\E/i) {
                        print "found ecperl used in $project/$procedure/$step\n";

                        #print "Fixing...\n";
                        $Ec->modifyStep($project, $procedure, $step,
                                    { shell => "ec-perl" }
                                       );
                    }
                    elsif ($shell =~ /ec-perl/i) { next }
                    elsif ($shell =~ /perl/i) {
                        print "found \"$shell\" in $project/$procedure/$step\n";
                    }
                #}
            }
        }
    }
}

# get a list of projects
sub getProjects {
    my(@projects);
    my($xpath) = $Ec->getProjects();

    # Loop over all projects
    my $nodeset = $xpath->find('//project');
    foreach my $node ($nodeset->get_nodelist) {
        my $project = $xpath->findvalue('projectName', $node);
        #print "Found project $project\n";
        push(@projects, $project);
    }
    return @projects;
}

# get a list of procedures in a project
sub getProcedures {
    my($project) = @_;
    my(@procedures);
    my($xpath) = $Ec->getProcedures($project);

    # Loop over all projects
    my $nodeset = $xpath->find('//procedure');
    foreach my $node ($nodeset->get_nodelist) {
        my $procedure = $xpath->findvalue('procedureName', $node);
        push(@procedures, $procedure);
    }
    return @procedures;
}

# get a list of steps in a procedure
sub getSteps {
    my($project, $procedure) = @_;
    my(@steps);
    my($xpath) = $Ec->getSteps($project, $procedure);

    # Loop over all projects
    my $nodeset = $xpath->find('//step');
    foreach my $node ($nodeset->get_nodelist) {
        my $step = $xpath->findvalue('stepName', $node);
        push(@steps, $step);
    }
    return @steps;
}

sub getField {
    my($xpath, $field) = @_;

    # for Debug
    #print $xpath->findnodes_as_string("/"), "\n";

    my($value) = $xpath->findvalue("//$field");
    $value =~ s/\&amp;/&/g;
    $value =~ s/\&lt;/</g;
    return "$value";
}
