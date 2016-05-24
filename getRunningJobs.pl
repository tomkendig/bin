#!/usr/bin/env perl
# -*-Perl-*-

use strict;
use warnings;

use ElectricCommander();
use FindBin;
use XML::XPath;

# Turn off output buffering:

$| = 1;

if (scalar(@ARGV) == 0) {
    print("Usage: perl getRunningJobs.pl hostName\n");
    exit(1);
}

$::gServer = shift;
$::gPassword = "changeme";
$::gPort = 8000;
$::gSecurePort = 8443;
$::gSecure = 0;
$::gTimeout = 180;

#------------------------------------------------------------------------------
# runCommand
#
#       Invokes a given command.
#
# Results:
#       If no error occurs, then the command's output is returned.  If an error
#       occurs, then based on the caller's choice, either the error is printed
#       and the program is killed, or both stdout and stderr are returned.
#
# Side Effects:
#       None except for the side effects of the command being invoked.
#
# Arguments:
#       command -           The command to invoke.
#       dieOnError -        (Optional) Defaults to true.  If set to false, then
#                           errors will be suppressed (included in stdout), and
#                           the combined result will be returned.
#       input -             (Optional) Input to pipe into the command.
#------------------------------------------------------------------------------

sub runCommand($;$) {
    my ($command, $properties) = @_;
    my $dieOnError = 1;
    my $input;
    if (defined($$properties{dieOnError})) {
        $dieOnError = $$properties{dieOnError};
    }
    if (defined($$properties{input})) {
        $input = $$properties{input};
    }

    my $errorFile;
    if ($dieOnError) {
        $errorFile = "$FindBin::RealBin/_err";
        $command .= " 2>\"$errorFile\"";
    } else {
        $command .= " 2>&1";
    }

    # If standard input is provided, open a pipe to the command and print
    # the input to the pipe.  Otherwise, just run the command.

    my $out;
    if (defined($input)) {
        my (undef, $outputName) =
                File::Temp::tempfile("ecout_XXXXXX", OPEN => 0,
                DIR => File::Spec->tmpdir);
        open(PIPE, "|-", "$command >\"$outputName\"");
        print(PIPE $input);
        close(PIPE);
        open(FILE, $outputName);
        my @fileContents = <FILE>;
        $out = join("", @fileContents);
        close(FILE);
        unlink($outputName);
    } else {
        $out = `$command`;
    }
    if ($dieOnError) {
        my $exit = $? >> 8;
        my $err = "";
        open(ERR, $errorFile);
        my @contents = <ERR>;
        $err = join("", @contents);
        close(ERR);
        unlink($errorFile);
        if ($exit != 0 || $err ne "") {
            print("Command \"$command\" failed with exit code $exit "
                    . "and errors:\n$err");
            exit(1);
        }
    }
    return $out;
}

#------------------------------------------------------------------------------
# connectToCommander
#
#       Establishes a connection to the Commander server.
#------------------------------------------------------------------------------

sub connectToCommander()
{
    print("Establishing a connection to ElectricCommander\n");

    # Establish a connection to the Commander server, and set it to return
    # errors rather than aborting on them.

    $::gCommander = new ElectricCommander->new({
            server      => $::gServer,
            port        => $::gPort,
            securePort  => $::gSecurePort,
            secure      => $::gSecure,
            timeout     => $::gTimeout});
    $::gCommander->abortOnError(0);
    $::gServer = $::gCommander->{server};
}

#------------------------------------------------------------------------------
# loginToCommander
#
#       Establishes a connection to the Commander server and logs in via the
#       API, saving the server object for future API calls.
#------------------------------------------------------------------------------

sub loginToCommander($$)
{
    print("Logging into ElectricCommander\n");

    my ($username, $password) = @_;
    my @args = ($username, $password);
    invokeCommander("login", \@args);
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
    print("Invoking function $functionName\n");
    my @functionArgs = @{$functionArgsRef};
    my $xpath = $::gCommander->$functionName(@functionArgs);
    my $errorMessage = $::gCommander->getError();
    if (defined($errorMessage) && $errorMessage ne "") {
        if (defined($suppressError) && $suppressError ne "" &&
                index($errorMessage, $suppressError) >= 0) {
            return (1, $errorMessage);
        } else {
            print($errorMessage);
            exit(1);
        }
    } else {
        $xpath = $xpath->findnodes('/responses/response')->get_node(0);
        return (0, $xpath);
    }
}

sub main()
{
    connectToCommander();
    loginToCommander("admin", $::gPassword);
    my @args = ("job", {
            "filter" => {
                "propertyName" => "status",
                "operator" => "notEqual",
                "operand1" => "completed"
            }
        });
    my ($error, $xpath) = invokeCommander("findObjects", \@args);
    runCommand("ectool --server $::gServer --port $::gPort "
            . "--securePort $::gSecurePort --secure $::gSecure "
            . "--timeout $::gTimeout login admin \"$::gPassword\"");
    my $logFile = "$FindBin::RealBin/runningJobs.out";
    open(LOG, ">$logFile");
    binmode(LOG);
    foreach my $job($xpath->findnodes("//job")) {
        my $jobId = $job->findvalue("jobId")->string_value;
        my $status = $job->findvalue("status")->string_value;
        print("    Job ID: $jobId; Status: $status\n");
        print(LOG runCommand("ectool --server $::gServer --port $::gPort "
                . "--securePort $::gSecurePort --secure $::gSecure "
                . "--timeout $::gTimeout getJobDetails $jobId"));
    }
    print(LOG "---------------------RESOURCES----------------------\n");
    print(LOG runCommand("ectool --server $::gServer --port $::gPort "
            . "--securePort $::gSecurePort --secure $::gSecure "
            . "--timeout $::gTimeout getResources"));
    close(LOG);
    runCommand("ectool --server $::gServer --port $::gPort "
            . "--securePort $::gSecurePort --secure $::gSecure "
            . "--timeout $::gTimeout logout");
}

main();
