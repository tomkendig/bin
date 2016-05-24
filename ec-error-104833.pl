use strict;

use ElectricCommander;
our $ec = ElectricCommander->new();
$ec->login( 'admin', 'changeme' );
$ec->abortOnError(0);

#-------------------------------------------------------------------
# Prepare parameters
#-------------------------------------------------------------------
my $projName = "tylee-joblock-test";
my $resource = 'chi102073';
my $lockType = 'job';   # Then try with 'step' Step works as expected

$ec->deleteProject($projName);
$ec->createProject($projName);

# Create procedure and simple step that just loops forever
createProcedure( $projName, 'loop' );
createStep(
    $projName,
    'loop',
    'loop-step',
    {
        command      => "while(1){sleep(1);}",
        shell        => "ec-perl",
        resourceName => "$resource",

    }
);

# Create procedure and add subprocedure step that calls 'call-me'
# Set sub-proc step to 'retain exclusve job' <--- Important part!!!!
createProcedure( $projName, 'run-me-first' );
createStep(
    $projName,
    'run-me-first',
    'i-am-looping',
    {
        subproject    => $projName,
        subprocedure  => 'loop',
        exclusive     => 1,
        exclusiveMode => $lockType,
        resourceName  => "$resource",
        parallel      => 0,
    }
);

# New proc and step that will use resource from above, but should wait till
# job above is complete
createProcedure( $projName, 'run-me-next' );
createStep(
    $projName,
    'run-me-next',
    'should-be-waiting',
    {
        command      => "print 'hello';",
        shell        => "ec-perl",
        resourceName => "$resource",

    }
);

exit 0;

#===============================================================================
# Function:	createProcedure ($projName, $procName,
#                               $href_params, $customParameters );
# Purpose:	Creates a procedure in the specified project
# Returns:	Result of ec->getProcedure() for this newly created procedure
# Example:
#               my $projName         = "existing-proj";
#               my $procName         = "new-proc-name";
#               my $customParameters = "arg1=val1,arg2=val2";
#               my $href_params      = {
#                    description  => "Some text...",
#                    resourceName => "existing-agent",
#                };
#
#                my $ecProcedure =
#                    createProcedure( $projName, $procName, $href_params,
#                        $customParameters );
#
# Author:	tgooderham
# Date:		2011-04-13 08:30:07 AM
#===============================================================================
sub createProcedure {
    my ( $project, $procedure, $href_params, $customParams ) = @_;

    our $ec;
    if ( not defined($ec) ) {
        use ElectricCommander;
        $ec = ElectricCommander->new();
    }
    $ec->abortOnError(0);
    if ( ref($href_params) ne "HASH" ) { $href_params = {}; }
    my %parameters = %$href_params;

    #-----------------------------------------------------
    # Process the actualParameter list
    #-----------------------------------------------------
    foreach my $params ( split( ',', "$customParams" ) ) {

        #-----------------------------------------------------
        # We'll let the user specify a series of 'var=value'
        # arguments that we'll turn into API arguments.
        # Split variable at the first equals sign.
        #-----------------------------------------------------
        my ( $varName, $varValue ) = $params =~ m/(.*?)=(.*)/;
        push(
            @{ $parameters{actualParameter} },
            {
                "actualParameterName" => "$varName",
                "value"               => "$varValue",
            },
        );
    }

    print "Creating procedure $project/$procedure\n";

    #---------------------------------------------------------
    # Create a procedure under the specified project
    #---------------------------------------------------------
    $ec->createProcedure( "$project", "$procedure", \%parameters, );

    if ( checkEcError($ec) ) { die "Failed to create procedure"; }

    #---------------------------------------------------------
    # Return this procedure object
    #---------------------------------------------------------
    return $ec->getProcedure( $project, $procedure );
}

#===============================================================================
# Function:	createStep( $projName, $procName, $stepName,
#                               $href_params, $customParameters );
# Purpose:	Creates a new step
#
# Returns:	Result of ec->getStep() for this newly created step
# Example:
#               my $projName         = "existing-proj";
#               my $procName         = "existing-proc";
#               my $stepName         = "new-step-name";
#               my $customParameters = "arg1=val1,arg2=val2";
#               my $href_params      = {
#                    subproject   => "called-project",
#                    subprocedure => "called-procedure",
#                    resourceName => "existing-agent",
#                    parallel     => 0,
#                };
#
#                my $ecStep =
#                    createStep( $projName, $procName, $stepName, $href_params,
#                        $customParameters );
#
# Author:	tgooderham
# Date:		2011-04-13 08:30:07 AM
#===============================================================================
sub createStep {
    my ( $project, $procedure, $step, $href_params, $customParams ) = @_;

    our $ec;
    if ( not defined($ec) ) {
        use ElectricCommander;
        $ec = ElectricCommander->new();
    }
    $ec->abortOnError(0);

    if ( ref($href_params) ne "HASH" ) { $href_params = {}; }
    my %parameters = %$href_params;

    #-----------------------------------------------------
    # Process the actualParameter list
    #-----------------------------------------------------
    foreach my $params ( split( ',', $customParams ) ) {

        #-----------------------------------------------------
        # We'll let the user specify a series of 'var=value'
        # arguments that we'll turn into API arguments.
        # Split variable at the first equals sign.
        #-----------------------------------------------------
        my ( $varName, $varValue ) = $params =~ m/(.*?)=(.*)/;
        push(
            @{ $parameters{actualParameter} },
            {
                "actualParameterName" => "$varName",
                "value"               => "$varValue",
            },
        );
    }

    #-----------------------------------------------------
    # Report what we're doing
    #-----------------------------------------------------
    if ( exists( $parameters{subproject} ) ) {
        my $subProj = $parameters{subproject};
        my $subProc = $parameters{subprocedure};

        print "Creating sub-step: "
          . "$project/$procedure/$step --> $subProj/$subProc\n";
    }
    else {
        print "Creating step: " . "$project/$procedure/$step\n";

    }

    #-----------------------------------------------------
    # Create the step
    #-----------------------------------------------------
    $ec->createStep( "$project", "$procedure", "$step", \%parameters );

    if ( checkEcError($ec) ) {
        die "Failed to create step";
    }

    #---------------------------------------------------------
    # Return this step object
    #---------------------------------------------------------
    return $ec->getStep( $project, $procedure, $step );
}

sub checkEcError {
    my $ec     = shift;
    my $errMsg = $ec->getError();
    if ( defined($errMsg) && $errMsg ne "" ) {
        print("Error: $errMsg\n");
        return 1;    # Error found
    }
    return 0;        # No errors
}
