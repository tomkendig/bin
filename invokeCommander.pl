#------------------------------------------------------------------------------
# loginToCommander
#
#       Establishes a connection to the Commander server and logs in via the
#       API, saving the server object for future API calls.
#
# Arguments:
#       username -          The name of the Commander user to login as.
#       password -          The password of the user.
#------------------------------------------------------------------------------

sub loginToCommander()
{
    if (!defined($::gPassword) || $::gPassword eq "") {
        # Retrieve the Commander user's password.

        $::gPassword = getPassword("Enter the password for Commander user $::gUserName: ");
    }

    display("Logging into ElectricCommander");
    debug("Logging in as \"$::gUserName\"");

    if (defined($ENV{ECPREFLIGHT_TEST})) {
        return;
    }

    invokeCommander("login", [$::gUserName, $::gPassword]);
    $::gCommander->saveSessionFile();
}

#------------------------------------------------------------------------------
# invokeCommander
#
#       Run a command on the Commander server and return the results,
#       optionally suppressing certain errors.
#
# Results:
#       A pair of values is returned, the first of which indicates whether an
#       error that was chosen to be suppressed was found.  If the error was
#       found, then the second value contains the error message.  Otherwise,
#       the second value is an XPath element containing the server's response
#       to the method invocation.
#
# Side Effects:
#       If an error occurs and it was not chosen to be suppressed, we generate
#       an error message on standard error and exit the application.
#
# Arguments:
#       functionName -      The name of the Commander method to invoke.
#       functionArgs -      The arguments to the method being invoked.  This
#                           should be an array ref.
#       suppressError -     A string containing an error code or message from
#                           the server response that should be ignored.
#------------------------------------------------------------------------------

sub invokeCommander($$;$)
{
    my ($functionName, $functionArgsRef, $suppressError) = @_;
    debug("Invoking function $functionName");
    my @functionArgs = @{$functionArgsRef};
    my $xpath = $::gCommander->$functionName(@functionArgs);
    my $errMsg = $::gCommander->getError();
    if (defined($errMsg) && $errMsg =~ m{ExpiredSession|NoCredentials}) {
        loginToCommander();
        $xpath = $::gCommander->$functionName(@functionArgs);
        $errMsg = $::gCommander->getError();
    }
    if (defined($errMsg) && $errMsg ne "") {
        if (defined($suppressError) && $suppressError ne "" &&
                index($errMsg, $suppressError) >= 0) {
            return (1, $errMsg);
        } else {
            error($errMsg);
        }
    } else {
        $xpath = $xpath->findnodes('/responses/response')->get_node(0);
        return (0, $xpath);
    }
}