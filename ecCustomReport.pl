#!/usr/bin/env perl
# -*-Perl-*-

# ecreport -
#
# This file implements a basic report generator for ElectricCommander.
# It extracts postprocessor data for a job and generates a report in
# the form of a 2-dimensional summary table.
#
# The following special keyword indicates that the "cleanup" script should
# scan this file for formatting errors, even though it doesn't have one of
# the expected extensions.
# CLEANUP: CHECK
#
# Copyright (c) 2006-2009 Electric Cloud, Inc.
# All rights reserved

use strict;
use warnings;
use File::Spec;
use Getopt::Long;
use HTTP::Date;
use XML::XPath;

# This is the version of ecreport.  The Makefile sed's this script to define
# version properly when building the executable.

my $version = "3.2.0.28533";
if ( !defined( $version ) ) {
    $version = 'unpackaged';
}

my $gBanner = "ElectricCommander Report Generator version $version\n"
        . "Copyright (C) 2006-2009 Electric Cloud, Inc.\n"
        . "All rights reserved.\n";

# ------------------------------------------------------------------------
# Command-Line Options
# ------------------------------------------------------------------------

# The following variables hold information from command-line arguments:

$::gCulpritSubject = "";             # Value of --culprit option.
$::gDataFile = "";                   # If non-empty, gives the name of a
                                     # file containing information about
                                     # the job in the same form as
                                     # "ectool getJobDetails" output.
$::gDirectory = "";                  # If non-empty, gives the name of a
                                     # directory that we should change to
                                     # before doing any processing
$::gHelp = 0;                        # 1 means --help was specified.
$::gVersion = 0;                     # 1 means --version was specified.
$::gJobId = "";                      # ElectricCommander identifier of
                                     # the job for which we are creating
                                     # a report.
$::gJobStepId = "";                  # ElectricCommander identifier of
                                     # the job Step for which we are creating
                                     # a report. Requires a JobId.
@::gLoadFiles = ();                  # Names of Perl files to load and
                                     # evaluate immediately after option
                                     # processing; from the --load option.
$::gMailTo = "";                     # Value of --mailto option.
$::gReplyTo = "";                    # Value of --replyto option.
$::gServer = "";                     # Value of --server option.
$::gEmailSubject = "";               # Value of --subject option.
$::gUpdateFile = "";                 # Name of file containing information
                                     # about recent updates to the source
                                     # (empty means no such file).  This
                                     # info is included in the report.
$::gWebRoot = "http://chronic2/commander";
                                     # URL for the root of the Commander
                                     # Web server; used for generating
                                     # URL's in the report.

# Input for GetOptions:

my %gOptions = (
             "culprit=s"                             => \$::gCulpritSubject,
             "data=s"                                => \$::gDataFile,
             "dir=s"                                 => \$::gDirectory,
             "help"                                  => \$::gHelp,
             "jobId=s"                               => \$::gJobId,
             "jobStepId=s"                           => \$::gJobStepId,
             "load=s"                                => \@::gLoadFiles,
             "mailto=s"                              => \$::gMailTo,
             "replyto=s"                             => \$::gReplyTo,
             "server=s"                              => \$::gServer,
             "subject=s"                             => \$::gEmailSubject,
             "updates=s"                             => \$::gUpdateFile,
             "version"                               => \$::gVersion,
             "webRoot=s"                             => \$::gWebRoot,
             );

# Help text to print in response to "-help":

$::gHelpMessage = "$gBanner\n" . q{Usage: ecreport [options]

This program extracts information about a particular job from an
ElectricCommander server and writes an HTML report to standard
output.  The report is organized as a 2-dimensional table
summarizing the results of the steps in the job; the table layout
can be customized by describing its formatting Perl using the
--load option.  The program should be invoked in the top-level
directory of the job's workspace so it can access log file
extracts left there (or, use the --dir option).

Options:
--culprit              If specified and the job failed, the report
                       will be emailed to each user mentioned in
                       the updates file.  The value of this option
                       gives the subject line for the message (%s
                       will be replaced with the job name).
--data                 Name of file containing job data for report.
                       If specified, this data is used in place of
                       querying the ElectricCommander server.  Used
                       primarily for testing.
--dir                  Change to this working directory before
                       doing anything else.
--help                 Print this message and exit without doing
                       anything.
--jobId                Identifier for the ElectricCommander job to
                       report on (required unless --data is
                       supplied).
--load                 Name of a file containing Perl code to
                       evaluate after option processing.  Used
                       mostly for debugging.  There may be multiple
                       --load options.
--mailto               E-mail the report to this address.
--replyto              Value for the "Reply-To" field in e-mailed
                       reports.
--server               Location of the ElectricCommander server
                       (hostname or hostname:port), to retrieve
                       job data.  Defaults to COMMANDER_SERVER
                       environment variable.
--subject              Value for the "Subject" field in e-mailed
                       reports.  If it contains a %s, a string
                       summarizing the job replaces the %s.
--updates              Name of a file containing information about
                       recent updates reflected in the job.  If
                       specified, the contents of this file are
                       included in the report.
--version              Print ecreport version number.
--webRoot              Base URL for the ElectricCommander Web
                       server where the job was run, such as
                       http://myServer.  URLs in the report will
                       refer to ElectricCommander Web pages
                       relative to this URL.
};

# ------------------------------------------------------------------------
# Miscellaneous Globals
# ------------------------------------------------------------------------

$::gOutHandle = *STDOUT;             # Report info gets written to this
                                     # file handle.
$::gNumDiagFiles = 0;                # Number of times readDiagFile has been
                                     # invoked.
$::gReport = "";                     # The contents of the report accumulates
                                     # here, in HTML format.
$::gMailCommand = "/usr/sbin/sendmail -t";
                                     # Command to run sendmail .  If empty,
                                     # don't run sendmail: instead, just dump
                                     # to standard output whatever we
                                     # would normally pipe to sendmail.
@::gTempFiles = ();                  # Names of temporary files created
                                     # during this run; must be deleted at
                                     # the end of the job.
@::gInternalErrors = ();             # Each element of this array contains
                                     # the error message for one internal error
                                     # that occurred, such as not being able
                                     # to read a file.

# ------------------------------------------------------------------------
# Report Data
# The following hash contains reporting information for each step in the
# job.  The key for an entry is the name of the step's log file, with an
# extensions such as "#2" added if needed to make it unique.  The value
# of each entry is a reference to a hash whose key-value pairs represent
# the reporting properties for that step.
# ------------------------------------------------------------------------

%::gReportData = ();
%::gStepsReported = ();             # Each entry in this hash corresponds to
                                    # the entry with the same name in
                                    # %::gReportData.  If the entry exists it
                                    # means that the data from %::gReportData
                                    # has been used in the report.  This hash
                                    # helps us to identify errors in steps
                                    # that aren't displayed in the main report.
@::gStepIds = ();                   # List of all of the keys for
                                    # %::gReportData, in the order of the steps
                                    # in the build.  Only steps that invoke
                                    # commands are recorded here, not those
                                    # that invoke subprocedures.

# ------------------------------------------------------------------------
# Table Description
#
# The following array describes how to generate a summary table.
# Each entry in the array describes one row of the table.  The first
# entry contains an array of strings giving the column titles to
# display for each column.  After that, each entry describes one
# row as an array.  The first entry for the row gives a text string
# to display in the first column, then each additional entry contains
# either the name of a log file (which identifies the step whose data
# should be displayed in that cell) or an array containing other display
# options (see below).  We use log file names to identify steps because
# the name of a step is not always unique (a single subprocedure might
# be invoked multiple times during a job), whereas the log file name is
# unique.
#
# If an entry contains an empty string, nothing is displayed in the cell.
#
# If an entry contains the value "span", then that entry will be joined
# with the following entry so that the information spans multiple columns
# of the table.
#
# If a nested array is used, the first element in the array is a string
# representing the type of information being displayed (e.g. "link").
# The rest of the elements provide other required information depending
# on the type.  The supported types are:
# "link" -  Followed by the text, then the URL.  The string $[jobId] will
#           be subsititued with the id of the job.
# ------------------------------------------------------------------------

@::gTableRows = (
    ["",
            "Solaris",
            "Windows XP",
            "Windows 2003",
            "Linux 2.4",
            "Linux 2.6"],
    ["Cleanup",
            "cleanup-solaris.log",
            "span",
            "cleanup-windows.log",
            "span",
            "cleanup-linux.log"],
    ["Build",
            "build-solaris.log",
            "span",
            "build-windows.log",
            "span",
            "build-linux.log"],
    ["Unit test",
            "unittest-solaris.log",
            "span",
            "unittest-windows.log",
            "span",
            "unittest-linux.log"],
    ["System test (local)",
            "localsystemtest-solaris.log",
            "span",
            "localsystemtest-windows.log",
            "span",
            "localsystemtest-linux.log"],
    ["Build installer",
            "installer-solaris.log",
            "span",
            "installer-windows.log",
            "span",
            "installer-linux.log"],
    ["Install",
            "install-solaris.log",
            "span",
            "install-windows.log",
            "span",
            "install-linux.log"],
    ["Agent/EFS tests",
            "agentefstest-solaris.log",
            "agentefstest-windows-xp.log",
            "agentefstest-windows-2k3.log",
            "agentefstest-linux-2.4.log",
            "agentefstest-linux-2.6.log"],
    ["System test (cluster)",
            "clustersystemtest-solaris.log",
            "span",
            "clustersystemtest-windows.log",
            "span",
            "clustersystemtest-linux.log"],
    ["CM tests",
            "cmtest-solaris.log",
            "span",
            "cmtest-windows.log",
            "span",
            "cmtest-linux.log"],
    ["Collect logs",
            "collectlogs-solaris.log",
            "span",
            "collectlogs-windows.log",
            "span",
            "collectlogs-linux.log"],
    ["Resource links",
            ["link",
                "Solaris link",
                "http://resource-machine/solaris-\$[jobId]"],
            "span",
            ["link",
                "Windows link",
                "http://resource-machine/windows-\$[jobId]"],
            "span",
            ["link",
                "Linux link",
                "http://resource-machine/linux-\$[jobId]"]],
);

# ------------------------------------------------------------------------
# Style Sheet:
# The following string represents a CSS stylesheet, which controls the
# formatting of the report.
# ------------------------------------------------------------------------

$::gStyleSheet = q{    <style type="text/css">
        body {
            font-family: Tahoma, Helvetica, sans-serif;
            background: #ffffff;
            color: #000000;
            font-size: 11px;
            margin: 5px 0px 0px 5px;
        }

        /* Styles for the outcome area at the top of the report. */

        .outcome table.outcomeOk {
            background: #bef0bc;
        }
        .outcome table.outcomeError {
            background: #f7cfcf;
        }
        .outcome table.outcomeWarning {
            background: #fff2bf;
        }
        .outcome td {
            padding: 5px;
        }
        .outcome td.outcome {
            font-size: 14px;
            font-weight: bold;
        }
        .outcome td.viewOnline a {
            font-size: 12px;
            font-weight: bold;
            text-decoration: none;
            border-bottom: dotted 1px;
        }

        /* Styles for the main summary table. */

        div.summary {
            margin: 20px 0px 0px 0px;
        }
        .summary table {
            background: #ffffff;
        }
        .summary td {
            padding: 3px 15px 3px 5px;
            vertical-align: top;
        }
        .summary .header td {
            background: #c8cacf;
            font-weight: bold;
        }
        td.labelEven {
            background: #f5f5f7;
            font-weight: bold;
        }
        td.labelOdd {
            background: #ffffff;
            font-weight: bold;
        }
        .summary td.success {
            background: #bef0bc;
        }
        .summary td.warning {
            background: #fff2bf;
        }
        .summary td.warning a {
            text-decoration: none;
            border-bottom: dotted 1px;
        }
        .summary td.error {
            background: #f7cfcf;
        }
        .summary td.error a {
            text-decoration: none;
            border-bottom: dotted 1px;
        }
        .summary td.noData {
            background: #dfe1e7;
            color: #666666;
        }

        /* Styles for section headings. */

        div.heading {
            margin: 15px 0px 0px 0px;
            border-top: solid 1px #d1d1d1;
            width: 98%;
            padding-top: 5px;
        }
        span.headerText {
            padding-left: 5px;
            font-size: 12px;
            font-weight: bold;
            color: #555e7e;
        }

        /* Styles for simple striped tables like those in the
         * General Information section.
         */

        div.stripes {
            margin: 10px 0px 0px 0px;
        }
        .stripes tr.odd {
            background: #f5f5f7;
        }
        .stripes tr.even {
            background: #ffffff;
        }
        .stripes td {
            padding: 4px 5px 4px 5px;
        }
        .stripes td.label {
            font-weight: bold;
            width: 20%;
        }
        .stripes td.error {
            color: #cc0000;
        }
        .stripes td.warning {
            color: #7c5c17;
        }

        /* Styles for diagnostic messages. */

        div.diagnostics {
            margin: 10px 0px 0px 0px;
        }
        .diagnostics td.stepHeader {
            padding: 8px 5px 8px 5px;
            background: #f5f5f7;
        }
        .diagnostics span.stepName {
            font-weight: bold;
        }
        .diagnostics td {
            padding: 5px 5px 5px 5px;
        }
        .diagnostics td.indexError {
            padding: 15px 5px 0px 5px;
            font-weight: bold;
            color: #cc0000;
        }
        .diagnostics td.indexWarning {
            padding: 15px 5px 0px 5px;
            font-weight: bold;
            color: #7c5c17;
        }
        .diagnostics td.indexMiscellaneous {
            padding: 15px 5px 0px 5px;
            font-weight: bold;
        }
        .diagnostics td.logLink {
            color: #999999;
            padding-bottom: 10px;
        }
        .diagnostics td.logLink a {
            text-decoration: none;
            border-bottom: dotted 1px;
            color: #333333;
        }
        .diagnostics td.logLink a:hover {
            color: #cc6600;
        }
        .diagnostics td.logExtract pre {
            padding: 8px 15px 8px 15px;
            margin: 0px;
            border: 1px dashed #cccccc;
            font-family: Courier New, Courier, monospace;
            font-size: 12px;
        }

        /* Styles for updates section. */

        div.updates {
            margin-top: 10px;
        }
        div.updates td pre {
            padding: 8px 15px 8px 15px;
            margin: 0px 5px 0px 5px;
            border: 1px dashed #cccccc;
            font-family: Courier New, Courier, monospace;
            font-size: 12px;
        }

        /* Overall colors. */

        a {
            color: #000000;
        }
        a:hover {
            color: #cc6600;
        }
    </style>
};

# ------------------------------------------------------------------------
# internalError
#
#      This function is invoked to record information about internal
#      errors.
#
# Results:
#      None.
#
# Side Effects:
#      The error message is saved so that it can be output in various
#      forms later on.
#
# Arguments:
#      message        - (string) describes what went wrong
# ------------------------------------------------------------------------

sub internalError($) {
    my ($message) = @_;
    push(@::gInternalErrors, $message);
}

# ------------------------------------------------------------------------
# readFile
#
#      Return the contents of a given file.  Exits with an error if the
#      file doesn't exist.
#
# Arguments:
#      fileName       - (string) name of the file
# ------------------------------------------------------------------------

sub readFile($) {
    my ($fileName) = @_;
    my $result = "";
    my $buffer;
    my $f;
    if (!open($f, "< $fileName")) {
        internalError("Couldn't open file \"$fileName\": $!");
        return "";
    }
    while (read($f, $buffer, 4096)) {
        $result .= $buffer;
    }
    close($f);
    return $result;
}

#-------------------------------------------------------------------------
# sendMail
#
#      Invoke the sendmail program to deliver the report (or anything at
#      all) by e-mail.
#
# Results:
#      None.
#
# Side Effects:
#      An e-mail message is sent.
#
# Arguments:
#      message -        (string) Contents of message (must be HTML).
#      to -             (string) Address of recipient.
#      replyTo -        (string) Return address for message, or "" if none.
#      subject -        (string) Subject line for message.
#-------------------------------------------------------------------------

sub sendMail($$$$) {
    my ($message, $to, $replyTo, $subject) = @_;

    my $handle;
    if ($::gMailCommand eq "") {
        # We are debugging: just write all of the information to
        # standard output instead of piping it to sendmail.

        $handle = *STDOUT;
    } else {
        if (!open($handle, "|-", $::gMailCommand)) {
            internalError("Couldn't start sendmail process: $!");
            return;
        }
    }
    print $handle "To: $to\n";
    if ($replyTo ne "") {
        print $handle "Reply-To: $replyTo\n";
    }
    print $handle "Subject: $subject\n";
    print $handle "Content-type: text/html\n";
    print $handle $message;
    if ($::gMailCommand ne "") {
        if (!close $handle) {
            internalError("Error in sendmail: $!");
        }
    }
}

#-------------------------------------------------------------------------
# bulkMail
#
#      Send an e-mail message to each person in a group.
#
# Results:
#      None.
#
# Side Effects:
#      An e-mail message is sent.
#
# Arguments:
#      message -        (string) Contents of message (must be HTML).
#      recipients -     (ref array) Names of recipients (just the names,
#                       no "@foo.com").  We will add on the @foo.com part
#                       using information from $::gMailTo.
#      replyTo -        (string) Return address for message, or "" if none.
#      subject -        (string) Subject line for message.
#-------------------------------------------------------------------------

sub bulkMail($$$$) {
    my ($message, $recipients, $replyTo, $subject) = @_;
    if ($::gMailTo !~ m/.*(\@.*)/) {
        internalError("Couldn't extract mail server name from \"$::gMailTo\"");
        return;
    }
    my $server = $1;
    foreach my $name (@$recipients) {
        sendMail($message, $name . $server, $replyTo, $subject);
    }
}

#-------------------------------------------------------------------------
# xmlQuote
#
#      Quote special characters such as & to generate well-formed XML
#      character data.
#
# Results:
#      The return value is identical to $string except that &, <, and >,
#      have been translated to &amp;, &lt;, and &gt;, respectively.
#
# Side Effects:
#      None.
#
# Arguments:
#      string -        String whose contents should be quoted.
#-------------------------------------------------------------------------

sub xmlQuote($) {
    my ($string) = @_;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s{([\0-\x{08}\x{0b}\x{0c}\x{0e}-\x{1f}])}{
            sprintf("%%%02x", ord($1))}ge;
    return $string;
}

#-------------------------------------------------------------------------
# quantify
#
#      Given a number and a noun such as "error", generate a quantified
#      not a such as "1 error" or "2 errors".  The main value of this
#      function is to figure out whether or not to add an "s" after the
#      noun.
#
# Results:
#      The return value is a string containing both the number and the\
#      noun, such as "2 errors".
#
# Side Effects:
#      None.
#
# Arguments:
#      number -        Integer value.
#      noun -          Singular noun that we may turn into a plural by
#                      adding an "s".
#-------------------------------------------------------------------------

sub quantify($$) {
    my ($number, $noun) = @_;

    if ($number == 1) {
        # Singular form, no need to add an "s".

        return "$number $noun";
    }

    if (substr($noun, -1, 1) eq "s") {
        # If noun already ends in "s", can't add another "s".

        return "$number $noun";
    }

    return "$number $noun" . "s";
}

# ------------------------------------------------------------------------
# getCulprits
#
#      This function scans a file containing information generated by
#      Perforce about recent changes to files, and extracts the names
#      of all of the users who checked in changes.
#
# Results:
#      The return value is an array, each of whose entries is the name
#      of a user who is responsible for one or more changes in
#      $updateFile.
#
# Side Effects:
#      None.
#
# Arguments:
#      updateFile       - (string) Name of a file containing P4 update
#                         information.
# ------------------------------------------------------------------------

sub getCulprits($) {
    my ($updateFile) = @_;
    my %names = ();
    my $line;
    if (!open(UPDATES, "< $updateFile")) {
        internalError("Couldn't open file \"$updateFile\": $!");
        return;
    }
    while ($line = <UPDATES>) {
        if ($line =~m/^Change .* by ([^@]*)@/) {
            $names{$1} = 1;
        }
    }
    close(UPDATES);
    return keys(%names);
}

#-------------------------------------------------------------------------
# collectData
#
#      Process information provided by the ElectricCommander server about a job
#      and collect data that is useful for reporting.
#
# Results:
#      The return value is a string indicating the overall success
#      or failure of the job; it has one of the values "ok",
#      "warning", or "error".
#
# Side Effects:
#      The global variable %::gReportData is modified to hold all of
#      the data we extracted.
#
# Arguments:
#      xpath -       XML::XPath object containing the results of a
#                    <getJobDetails> server request.
#-------------------------------------------------------------------------

sub collectData($) {
    my ($xpath) = @_;
    my $severity = "ok";

    # Note: job steps are nested hierarchically, but the following xpath
    # search flattens the hierarchy to access all of the individual steps.

    my $steps = $xpath->findnodes('//jobStep');
    foreach my $step ($steps->get_nodelist) {
        # First, collect interesting data for this step.  Start off by
        # collecting several of the built-in properties for the step.

        my $stepData = {};
        foreach my $name ("exitCode", "errorCode", "finish", "jobStepId",
                "logFileName", "outcome", "resourceName", "start",
                "status", "stepName") {
            $stepData->{$name} = "" . $xpath->findvalue($name, $step);
        }

        # Next, collect all of the custom properties for the step.

        my $properties = $xpath->findnodes('propertySheet/property',
                $step);
        foreach my $property ($properties->get_nodelist) {
            my $name = $xpath->findvalue('propertyName', $property);

            # Tricky!  The "" concatenation below forces the findvalue
            # result to be converted to a string, which is what we need
            # later (e.g., can't use integer comparison on the raw
            # findvalue result).

            $stepData->{$name} = "" . $xpath->findvalue('value',
                    $property);
        }

        # Now figure out the key under which this information should be
        # recorded.  Use the value of the "logFileName" property, with
        # an additional "unique-ifier" suffix if the name is already
        # in use.

        my $key = $stepData->{"logFileName"};
        if (defined($::gReportData{$key})) {
            # Some other step has already used this key.  Add an
            # extension such as "#2" to the key to make it unique.

            for (my $i = 2; ; $i++) {
                my $newKey = $key . "#$i";
                if (!defined($::gReportData{$newKey})) {
                    $key = $newKey;
                    last;
                }
            }
        }

        # Save the accumulated data.

        $::gReportData{$key} = $stepData;
        if ($xpath->findvalue('command', $step) ne "") {
            push(@::gStepIds, $key);
        }

        # Update the severity level.

        if ($stepData->{outcome} eq "error") {
            $severity = "error";
        } elsif (($stepData->{outcome} eq "warning")
                && ($severity ne "error")) {
            $severity = "warning";
        }
    }
    return $severity;
}

#-------------------------------------------------------------------------
# readDiagFile
#
#      This function reads in log extracts from a diagnostics file and
#      formats it for display in HTML.
#
# Results:
#      The return value is an array with two elements.  The first
#      element is HTML describing the contents of the diagnostics file.
#      The second element is an HTML anchor that can be used to link
#      to the HTML in the first element.
#
# Side Effects:
#      None.
#
# Arguments:
#      fileName -    Name of file containing diagnostic information.
#      stepName -    Name of the step for these diagnostics; used only
#                    in HTML labels.
#      stepId -      Identifier for the job step; used in creating links.
#      logFileName - Name of the log file for $stepName; included in
#                    generated HTML.
#-------------------------------------------------------------------------

sub readDiagFile($$$$) {
    my ($fileName, $stepName, $stepId, $logFileName) = @_;
    my $anchor = "";
    $::gNumDiagFiles++;

    my $data = readFile($fileName);
    if ($data eq "") {
        return ("", "none");
    }
    my $xpath = XML::XPath->new($data);
    my $diagnostics = $xpath->findnodes(
            '/diagnostics/diagnostic');

    # Scan the diagnostics once just to count how many diagnostics there
    # are of each type (error, warning, miscellaneous).

    my %counts = ("Error" => 0, "Warning" => 0, "Miscellaneous" => 0);
    foreach my $diagnostic ($diagnostics->get_nodelist()) {
        my $type = $xpath->findvalue("type", $diagnostic);
        if ($type eq "error") {
            $counts{"Error"}++;
        } elsif ($type eq "warning") {
            $counts{"Warning"}++;
        } else {
            $counts{"Miscellaneous"}++;
        }
    }

    # Second pass: generate HTML for each diagnostic.  Separate the
    # messages into three categories (error, warning, miscellaneous)

    my %current = ("Error" => 0, "Warning" => 0, "Miscellaneous" => 0);
    my %groups = ("Error" => "", "Warning" => "", "Miscellaneous" => "");
    foreach my $diagnostic ($diagnostics->get_nodelist()) {
        my $type = $xpath->findvalue("type", $diagnostic);
        if ($type eq "error") {
            $type = "Error";
        } elsif($type eq "warning") {
            $type = "Warning";
        } else {
            $type = "Miscellaneous";
        }
        my $name = $xpath->findvalue("name", $diagnostic);
        my $module = $xpath->findvalue("module", $diagnostic);
        my $line = $xpath->findvalue("firstLine", $diagnostic);
        my $numLines = $xpath->findvalue("numLines", $diagnostic);

        # Generate a URL for displaying the log extract as part of the full
        # log file.

        my $url = "$::gWebRoot/workspaceFile.php?jobStepId="
                . xmlQuote($stepId) . "&amp;fileName="
                . xmlQuote($logFileName);
        if ($line ne "") {
            $url .= "&amp;firstLine=$line";
            if ($numLines ne "") {
                $url .= "&amp;numLines=$numLines";
            }
        }

        # Generate a string containing the log file name (and line number,
        # if available).

        my $logFile = "$logFileName";
        if ($line ne "") {
            $logFile .= ":$line";
        }

        # Generate a string displaying the module name and particular
        # test name, if available.

        my $modulePlusName = $name;
        if ($module ne "") {
            $modulePlusName = "$module, $name";
        }
        if ($name ne "") {
            $modulePlusName = " ($modulePlusName)";
        } else {
            $modulePlusName = "";
        }

        $current{$type}++;
        $groups{$type} .=
                  "      <tr>\n"
                . "        <td class=\"index$type\">$type #"
                . $current{$type} . " of " . $counts{$type} . "</td>\n"
                . "      </tr>\n"
                . "      <tr>\n"
                . "        <td class=\"logLink\"><a href=\"$url\">"
                . xmlQuote($logFile) . "</a>" . xmlQuote($modulePlusName)
                . "</td>\n"
                . "      </tr>\n"
                . "      <tr>\n"
                . "        <td class=\"logExtract\"><pre>"
                . xmlQuote($xpath->findvalue("message", $diagnostic))
                . "</pre></td>\n"
                . "      </tr>\n";
    }

    # If there is any diagnostic HTML, encapsulate it with appropriate
    # header and trailer information.

    my $html = $groups{"Error"} . $groups{"Warning"}
            . $groups{"Miscellaneous"};
    if ($html ne "") {
        # Generate an anchor that can be used to link to this step's
        # diagnostics.

        $anchor = "diagFile" . $::gNumDiagFiles;

        # Overall summary of messages for this step.

        my $summary = "";
        foreach my $type ("Error", "Warning", "Miscellaneous") {
            if ($counts{$type} > 0) {
                if ($summary ne "") {
                    $summary .= ", ";
                } else {
                    $summary .= " - ";
                }
                $summary .= quantify($counts{$type}, $type);
            }
        }

        $html =
                  "  <!-- Start diagnostic file \"$fileName\" -->\n"
                . "  <div class=\"diagnostics\">\n"
                . "    <a name=\"$anchor\"> </a>\n"
                . "    <table cellspacing=\"0\" width=\"98%\">\n"
                . "      <tr>\n"
                . "        <td class=\"stepHeader\"><span class=\"stepName\">"
                . xmlQuote($stepName) . "</span>"
                . "<span class=\"stepSummary\">" . xmlQuote($summary)
                . "</span></td>\n"
                . "      </tr>\n"
                . $html
                . "    </table>\n"
                . "  </div>\n"
                . "  <!-- End diagnostic file \"$fileName\" -->\n";
    }
    return ($html, $anchor);
}

#-------------------------------------------------------------------------
# printData
#
#      This function is used primarily for testing.  It prints on
#      standard output the contents of the global variable
#      %::gReportData.
#
# Results:
#      None.
#
# Side Effects:
#      Output is generated on standard output.
#
# Arguments:
#      If any arguments are specified, they give the names of properties
#      within each %::gReportData element to print; otherwise all properties
#      are printed.
#-------------------------------------------------------------------------

sub printData(@) {
    foreach my $key (sort(keys(%::gReportData))) {
        print("$key:\n");
        my $stepData = $::gReportData{$key};
        my @names = @_;
        if (!@names) {
            @names = sort(keys(%$stepData));
        }
        foreach my $name (@names) {
            my $data = $stepData->{$name};
            if (!defined($data)) {
                next;
            }
            if ($data eq "") {
                $data = '""';
            }
            printf("    %-12s => %s\n", $name, $data);
        }
    }
}

#-------------------------------------------------------------------------
# formatElapsedTime
#
#      Given a time value measured in seconds, return a string of the
#      form 00:04.6 that separates the minutes from the seconds.
#-------------------------------------------------------------------------

sub formatElapsedTime($) {
    my ($time) = @_;
    my $minutes = int($time/60);
    my $seconds = $time - 60*$minutes;
    return sprintf("%02d:%04.1f", $minutes, $seconds);
}

#-------------------------------------------------------------------------
# summaryLine
#
#      Return a one-line summary to describe the success of the build.
#      This can be used for things such as the page title or an e-mail
#      subject line.
#
# Arguments:
#      xpath -       XML::XPath object containing the results of a
#                    <getJobDetails> server request.
#      severity -    Indicates overall success or failure of the job:
#                    "ok", "warning", or "error".
#-------------------------------------------------------------------------

sub summaryLine($$) {
    my ($xpath, $severity) = @_;

    my $name = $xpath->findvalue('//job/jobName');
    my $errorMessage = $xpath->findvalue('//job/errorMessage');
    if ($name eq "") {
        $name = "unknown job";
    }
    if ($errorMessage =~ m#\[Aborted\]: (.*) has aborted this job#) {
        return "$name aborted by $1";
    }
    if ($severity eq "ok") {
        return "$name is good!";
    }
    if ($severity eq "warning") {
        return "$name has warnings";
    }
    if ($severity eq "error") {
        return "$name has errors";
    }
    return "$name has unknown status \"$severity\"";
}

#-------------------------------------------------------------------------
# stepNotes
#
#      Collect all of the summary information that should be displayed
#      for a given step.
#
# Results:
#      The return value is a list, each of whose elements is a string
#      containing one piece of summary information for the step, such
#      as "exit code 2" or "3 compiles".
#
# Arguments:
#      id -          (string) Identifier for the step (index into
#                    $::gReportData).  Either the name of a step or the
#                    name of its <reportId> property.
#      issuesOnly -  (integer) Nonzero means only collect information
#                    that suggests there was a problem (errors and
#                    warnings).  Skip informational messages such as
#                    "3 compiles".
#-------------------------------------------------------------------------

sub stepNotes($$) {
    my ($id, $issuesOnly) = @_;

    my @notes = ();
    my $data = $::gReportData{$id};
    my @tags = ("errors", "warnings");
    if (!$issuesOnly) {
        unshift(@tags, "compiles", "tests");
    }
    foreach my $name (@tags) {
        if (defined($data->{$name})) {
            push(@notes, xmlQuote($data->{$name} . " $name"));
        }
    }
    my $code = $data->{exitCode};
    if (($code ne "") && ($code != 0)) {
        if (!defined($data->{errors})) {
            push(@notes, xmlQuote("exit code $code"));
        }
    }
    my $errorCode = $data->{errorCode};
    if ($errorCode ne "") {
        push(@notes, xmlQuote($errorCode));
    }
    if (defined($data->{summary})) {
        @notes = ();
        foreach my $note (split(/\n/, $data->{summary})) {
            push(@notes, xmlQuote($note));
        }
    }
    if (!@notes) {
        if ($issuesOnly) {
            if (($data->{outcome} eq "error")
                    || ($data->{outcome} eq "warning")) {
                push(@notes, $data->{outcome});
            }
        } else {
            if ($data->{status} eq "completed") {
                push(@notes, "ok");
            } else {
                push(@notes, $data->{status});
            }
        }
    }
    return @notes;
}

#-------------------------------------------------------------------------
# showHeader
#
#      Generate an XHTML header for the report.
#
# Arguments:
#      title -         Title to display for the page.
#-------------------------------------------------------------------------

sub showHeader($) {
    my ($title) = @_;

    $::gReport .= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML "
            . "1.0 Strict//EN\"\n"
            . "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
            . "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n"
            . "<head>\n"
            . "    <title>$title</title>\n" ;
    $::gReport .= $::gStyleSheet ;
    $::gReport .= "</head>\n<body>\n" ;
}

#-------------------------------------------------------------------------
# showOutcome
#
#      Output HTML for the outcome area at the top of the report, which
#      displays overall job success/failure, a link to the on-line full
#      job details, and any overall job error messages.
#
# Arguments:
#      outcome -       Overall outcome: "ok", "warning", or "error".
#      message -       String containing job name and summary of outcome.
#      xpath -         XML data for the job.
#-------------------------------------------------------------------------

sub showOutcome($$$) {
    my ($outcome, $message, $xpath) = @_;

    my $jobId =  $xpath->findvalue('//job/jobId');
    $::gReport .= "\n"
            . "  <!-- Start outcome -->\n"
            . "  <div class=\"outcome\">\n"
            . "    <table class=\"outcome" . ucfirst($outcome)
            . "\" cellspacing=\"0\" width=\"98%\">\n"
            . "      <tr>\n"
            . "        <td class=\"outcome\">" . xmlQuote($message)
            . "</td>\n"
            . "        <td class=\"viewOnline\" align=\"right\">"
            . "<a href=\"$::gWebRoot/jobDetails.php?jobId=$jobId\">"
            . "View Online</a></td>\n"
            . "      </tr>\n";

    my $errorMessage = $xpath->findvalue('//job/errorMessage');
    if ($errorMessage ne "") {
        $::gReport .=
                  "      <tr>\n"
                . "        <td colspan=\"2\">" . xmlQuote($errorMessage)
                . "</td>\n"
                . "      </tr>\n";
    }
    $::gReport .= "    </table>\n"
            . "  </div>\n"
            . "  <!-- End outcome -->\n";
}

#-------------------------------------------------------------------------
# showTable
#
#      Output HTML for the main summary table and for any log file
#      diagnostics that it refers to.
#
# Results:
#      The return value contains HTML for any log file diagnostics referred
#      to in the table.  Presumably the caller will output this information
#      at an appropriate place.
#
# Arguments:
#      None.
#-------------------------------------------------------------------------

sub showTable() {
    my $diagnostics = "";
    $::gReport .= "\n"
            . "  <!-- Start of summary table -->\n"
            . "  <div class=\"summary\">\n"
            . "    <table cellspacing=\"1\">\n";

    # Generate the first row, containing column headers.

    $::gReport .= "      <tr class=\"header\">\n";
    my $firstRow = $::gTableRows[0];
    foreach my $label (@$firstRow) {
        $::gReport .= "        <td>" . xmlQuote($label) . "</td>\n";
    }
    $::gReport .= "      </tr>\n";

    # Each iteration through the following loop generates one row of the
    # table body.

    my $i;
    for ($i = 1; $i < @::gTableRows; $i++) {
        my $row = $::gTableRows[$i];
        $::gReport .= "      <tr>\n";
        my $first = 1;

        # The following variable counts how many "span" cells we have seen
        # before the current cell.

        my $span = 0;

        foreach my $field (@$row) {
            my $tdAttr = "";
            my $outcome = "";
            my $title = "";
            my $anchor = "";
            my $html = "";
            my $cellContents = "";
            my @notes;

            if ($first) {
                # Leftmost column: just a literal string to label the row.

                $::gReport .= "       <td class=\""
                        . (($i & 1) ? "labelOdd": "labelEven") . "\">"
                        . xmlQuote($field) . "</td>\n";
                $first = 0;
                next;
            }
            if ($field eq "span") {
                # The current cell should be joined together with the next
                # cell(s) after it.  The next cell whose content is
                # something other than "span" determines what is actually
                # displayed.

                $span++;
                next;
            }
            if ($span != 0) {
                $tdAttr = " colspan=\"" . ($span+1) . "\"";
                $span = 0;
            }
            if (ref($field) eq "ARRAY") {
                # This field is not a standard log file name.  Check the type
                # of data to be displayed and set the HTML for the column
                # accordingly.

                my $type = @$field[0];
                if ($type eq "link") {
                    # Display a simple link.

                    $outcome = "noData";
                    $title = @$field[1];
                    my $url = @$field[2];

                    # Replace all occurences of the string '$[jobId]' with the
                    # actual job id.

                    $title =~ s/\$\[jobId\]/$::gJobId/g;
                    $url =~ s/\$\[jobId\]/$::gJobId/g;

                    $cellContents = "<a href=\"$url\">$title</a>";
                }
            } else {
                if ($field eq "") {
                    # No data expected for this cell.

                    $::gReport .= "        <td class=\"success\""
                            . "$tdAttr></td>\n";
                    next;
                }
                $::gStepsReported{$field} = 1;
                my $data = $::gReportData{$field};
                if (!defined($data)) {
                    # Data is expected for this cell, but none is present;
                    # suggests that the step was cancelled or hasn't yet run.

                    $::gReport .= "       <td class=\"noData\"$tdAttr>"
                            . "- no data -</td>\n";
                    next;
                }
                $outcome = $data->{outcome};
                if ($outcome eq "skipped") {
                    # Step was skipped  display the same as "no data"
                    # except indicate that the step was skipped.

                    $::gReport .= "       <td class=\"noData\"$tdAttr>"
                            . "skipped</td>\n";
                    next;
                }

                # If there is a diagnostic file for this cell, read it
                # in, generate appropriate HTML, and save the HTML to
                # output later.

                if (defined($data->{diagFile})) {
                    ($html, $anchor) = readDiagFile($data->{diagFile}, $field,
                            $data->{jobStepId}, $data->{logFileName});
                    $diagnostics .= $html;
                }
                @notes = stepNotes($field, 0);

                # Compute a tooltip string giving the host on which the step
                # ran, and its execution time.

                my $elapsed = "";
                if ($data->{finish} && $data->{start}) {
                    my $time = formatElapsedTime(
                            HTTP::Date::str2time($data->{finish})
                            - HTTP::Date::str2time($data->{start}));
                    $elapsed = sprintf(" Elapsed: %s", $time);
                }
                $title = xmlQuote(sprintf("Resource: %s%s",
                        $data->{resourceName}, $elapsed));

            }
            $html = "<td class=\"$outcome\" title=\"$title\"$tdAttr>";
            if ($cellContents eq "") {
                if ($anchor ne "") {
                    $html .= "<a href=\"#$anchor\">" . join("<br/>", @notes)
                            . "</a>";
                } else {
                    $html .= join("<br/>", @notes);
                }
            } else {
                $html .= $cellContents;
            }
            $::gReport .= "            $html</td>\n";
        }
        $::gReport .= "      </tr>\n";
    }
    $::gReport .= "    </table>\n"
            . "  </div>\n"
            . "  <!-- End of summary table -->\n";

    if ($diagnostics eq "") {
        return "";
    }
    return "    <!-- Start of diagnostics -->\n" . $diagnostics
            . "    <!-- End of diagnostics -->\n";
}

#-------------------------------------------------------------------------
# showHeading
#
#      Generates HTML for a section heading displaying a given title.
#
# Arguments:
#      title -       Title text to display in the heading.
#-------------------------------------------------------------------------

sub showHeading($) {
    my ($title) = @_;

    $::gReport .= "\n"
            . "  <!-- Start heading -->\n"
            . "  <div class=\"heading\">"
            . "<span class=\"headerText\">" . xmlQuote($title)
            . "</span></div>\n"
            . "  <!-- End heading -->\n";
}

#-------------------------------------------------------------------------
# showGeneral
#
#      Generates HTML for the "General Information" section of the
#      report.
#
# Arguments:
#      xpath -       XML::XPath object containing the results of a
#                    <getJobDetails> server request.
#-------------------------------------------------------------------------

sub showGeneral($) {
    my ($xpath) = @_;

    showHeading("General Information");

    my $start = "" . $xpath->findvalue('//job/start');
    my $startTime = HTTP::Date::str2time($start);
    my @time = localtime($startTime);
    my $startString = sprintf("%d/%d/%d %02d:%02d:%02d",
            $time[4]+1, $time[3], $time[5] + 1900, $time[2],
            $time[1], $time[0]);
    my $finish = "" . $xpath->findvalue('//job/finish');
    my $finishTime;
    if ($finish ne "") {
        $finishTime  = HTTP::Date::str2time($finish);
    } else {
        $finishTime = time();
    }
    my $seconds = $finishTime - $startTime;;
    my $minutes = int($seconds/60);
    $seconds -= $minutes*60;
    my $elapsedString = quantify(sprintf("%.1f", $seconds), "second");
    if ($minutes > 0) {
        my $hours = int($minutes/60);
        $minutes -= $hours*60;
        $elapsedString = quantify($minutes, "minute") . ", "
                    . $elapsedString;
        if ($hours > 0) {
            $elapsedString = quantify($hours, "hour") . ", "
                    . $elapsedString;
        }
    }

    $::gReport .= "\n"
            . "  <!-- Start General Information -->\n"
            . "  <div class=\"stripes\">\n"
            . "    <table cellspacing=\"0\" width=\"98%\">\n"
            . "      <tr class=\"odd\">\n"
            . "        <td class=\"label\">Start Time</td>\n"
            . "        <td>" . xmlQuote($startString) . "</td>\n"
            . "      </tr>\n"
            . "      <tr class=\"even\">\n"
            . "        <td class=\"label\">Elapsed Time</td>\n"
            . "        <td>" . xmlQuote($elapsedString) . "</td>\n"
            . "      </tr>\n";

    # Generate information about all of the job's workspaces.  Use
    # the Windows location if available, otherwise the Unix location.

    my $workspaces = $xpath->findnodes('//job/workspace');
    my $rowIndex = 0;
    foreach my $workspace ($workspaces->get_nodelist) {
        my $name = "";
        if ($workspaces->size() > 1) {
            # There is more than one workspace, so identify each
            # by its name.

            $name = " \""
                    . $xpath->findvalue('workspaceName', $workspace)
                    . "\"";
        }
        my $directory = $xpath->findvalue('winUNC', $workspace);
        if ($directory eq "") {
            $directory = $xpath->findvalue('unix', $workspace);
        }
        $rowIndex++;
        $::gReport .=
                  "      <tr class=\""
                . (($rowIndex & 1) ? "odd": "even") . "\">\n"
                . "        <td class=\"label\">Workspace"
                . xmlQuote($name) . "</td>\n"
                . "        <td>" . xmlQuote($directory) . "</td>\n"
                . "      </tr>\n";
    }

    $::gReport .=
              "    </table>\n"
            . "  </div>\n"
            . "  <!-- End General Information -->\n";
}

#-------------------------------------------------------------------------
# showInternalErrors
#
#      Generates HTML for internal errors that occurred while generating
#      this report.
#
# Results:
#      None.
#
# Arguments:
#      None.
#-------------------------------------------------------------------------

sub showInternalErrors() {
    if (@::gInternalErrors == 0) {
        return;
    }
    showHeading("Ecreport Errors");
    $::gReport .= "\n"
            . "  <!-- Start Ecreport Errors -->\n"
            . "  <div class=\"stripes\">\n"
            . "    <table cellspacing=\"0\" width=\"98%\">\n";
    my $rowIndex = 0;
    foreach my $message (@::gInternalErrors) {
        $rowIndex++;
        my $rowClass = ($rowIndex & 1) ? "odd" : "even";
        $::gReport .=
              "      <tr class=\"$rowClass\">\n"
            . "        <td><span class=\"error\">" . xmlQuote($message)
            . "</span></td>\n"
            . "      </tr>\n";
    }
    $::gReport .=
              "    </table>\n"
            . "  </div>\n"
            . "  <!-- End Ecreport Errors -->\n";
}

#-------------------------------------------------------------------------
# showOtherProblems
#
#      Generates HTML for the "Other Steps with Possible Problems" section
#      of the report.
#
# Arguments:
#      None.
#-------------------------------------------------------------------------

sub showOtherProblems() {
    # Go through the steps again, to see if there are any errors or warnings
    # that haven't already been reported.  If so, generate extra HTML to
    # describe just these additional issues.

    my $numProblems = 0;
    foreach my $step (@::gStepIds) {
        if (defined($::gStepsReported{$step})) {
            next;
        }
        my @notes = stepNotes($step, 1);
        if (!@notes) {
            next;
        }
        if ($numProblems == 0) {
            showHeading("Other Steps with Possible Problems");
            $::gReport .= "\n"
                    . "  <!-- Start Other Problems -->\n"
                    . "  <div class=\"stripes\">\n"
                    . "    <table cellspacing=\"0\" width=\"98%\">\n";
        }
        $numProblems++;
        my $data = $::gReportData{$step};
        my $rowClass = ($numProblems & 1) ? "odd" : "even";
        my $message = join(", ", @notes);
        my $messageClass = "warning";
        if ($data->{outcome} eq "error") {
            $messageClass = "error";
        }
        $::gReport .=
                  "      <tr class=\"$rowClass\">\n"
                . "        <td class=\"label\">"
                . xmlQuote($data->{stepName}) . "</td>\n"
                . "        <td class=\"$messageClass\">"
                . xmlQuote($message) . "</td>\n"
                . "      </tr>\n";
    }
    if ($numProblems != 0) {
        $::gReport .=
                  "    </table>\n"
                . "  </div>\n"
                . "  <!-- End Other Problems -->\n";
    }
}

#-------------------------------------------------------------------------
# showFooter
#
#      Generate an XHTML footer for the report.  Assumes that "showHeader"
#      has previously been invoked.
#
# Arguments:
#      None.
#-------------------------------------------------------------------------

sub showFooter() {
    $::gReport .= "</body>\n</html>\n";
}

#-------------------------------------------------------------------------
# includeFile
#
#      Include a single file in the body of the report.
#
# Arguments:
#      file -          The path to the file being included in the report.
#      heading -       A heading to display above the file contents.
#      class -         The CSS class to apply to the <div> element
#                      containing the file contents.
#      pre -           A Boolean which will determine whether or not the
#                      file contents are wrapped in a <pre> tag.
#-------------------------------------------------------------------------

sub includeFile($$$$) {
    my ($file, $heading, $class, $pre) = @_;

    my $contents = readFile($file);
    if ($contents eq "") {
        return;
    }
    $contents = xmlQuote($contents);
    if ($pre) {
        $contents = "<pre>$contents</pre>";
    }

    if ($heading ne "") {
        showHeading($heading);
    }
    $::gReport .= "\n"
            . "  <!-- Start file contents -->\n"
            . "  <div class=\"$class\">\n"
            . "    <table cellspacing=\"0\" width=\"98%\">\n"
            . "      <tr>\n"
            . "        <td>$contents</td>\n"
            . "      </tr>\n"
            . "    </table>\n"
            . "  </div>\n"
            . "  <!-- End file contents -->\n";
}

#-------------------------------------------------------------------------
# buildReport
#
#      Compose the report using the default order.  This function can
#      be overridden (by using the --load option) to change the order
#      and add/remove components.
#
# Arguments:
#      summary -       String containing job name and summary of outcome.
#      severity -      Overall outcome: "ok", "warning", or "error".
#      xpath -         XML::XPath object containing the results of a
#                      <getJobDetails> server request.
#-------------------------------------------------------------------------

sub buildReport($$$) {
    my ($summary, $severity, $xpath) = @_;

    # Generate an XHTML header for the report.

    showHeader($summary);

    # Output HTML for the outcome area at the top of the report, which
    # displays overall job success/failure, a link to the on-line full job
    # details, and any overall job error messages.

    showOutcome($severity, $summary, $xpath);

    # Output HTML for the main summary table and for any log file diagnostics
    # that it refers to.

    my $diagnostics = showTable();

    # Generates HTML for the "General Information" section of the report.

    showGeneral($xpath);

    # Generates HTML for internal errors that occurred while generating this
    # report.

    showInternalErrors();

    # Generates HTML for the "Other Steps with Possible Problems" section of
    # the report.

    showOtherProblems();

    # If there were any diagnostics stored when building the main summary
    # table, then display them here.

    if ($diagnostics ne "") {
        showHeading("Diagnostic Messages");
        $::gReport .= $diagnostics;
    }

    # If we have been given the name the file describing recent updates and
    # that file exists, include its contents in the report.

    if ($::gUpdateFile ne "") {
        includeFile($::gUpdateFile, "Recent Updates", "updates", 1);
    }

    # Generate an XHTML footer for the report.  Assumes that "showHeader"
    # has previously been invoked.

    showFooter();
}

# -----------------------------------------------------------------------
#  loadPluginFiles
#    Load and execute plugin perl files specified by --load option.
#
#  Results:
#    returns nothing
#
#  Side Effects:
#    runs arbitrary perl code and may exit
#
#  Arguments:
#    None
#------------------------------------------------------------------------
sub loadPluginFiles() {

    foreach my $file (@::gLoadFiles) {
        $file = File::Spec->rel2abs($file);
        if (!(do $file)) {
            my $message = $@;
            if (!$message) {
                # If the file isn't found no message is left in $@,
                # but there is a message in $!.
                $message = "Cannot read file \"$file\": "
                    . lcfirst($!);
            }
            die $message;
         }
     }
}

#-------------------------------------------------------------------------
# main
#
#      Main program for the application.
#-------------------------------------------------------------------------

sub main() {
    # Parse command line arguments into global variables.

    if (!GetOptions(%gOptions)) {
        print $::gHelpMessage;
        exit(1);
    }

    loadPluginFiles;

    if ($::gHelp) {
        print $::gHelpMessage;
        exit(0);
    }

    if ($::gVersion) {
        print "$gBanner";
        exit(0);
    }

    if ($::gDirectory) {
        chdir($::gDirectory)
                or die "couldn't change directory to \"$::gDirectory\": $!";
    }

    if (@ARGV >1) {
        shift(@ARGV);
        printf ("Extra arguments: % s\n", join(" ", @ARGV));
        print $::gHelpMessage;
        exit(1);
    }
    if (!$::gJobId && !$::gJobStepId && !$::gDataFile) {
        print "Must either specify --jobId or --data\n";
        exit(1);
    }

    # Retrieve the job data.

    my $jobData;
    my $jobStepData;
    if ($::gDataFile) {
        $jobData = readFile($::gDataFile);
    } else {
	if ($::gServer ne "") {
		$jobData = `ectool --server $::gServer getJobDetails $::gJobId`;
        } else {
		$jobData = `ectool getJobDetails $::gJobId`;
	}
        if ($::gJobStepId ne "") {
		if ($::gServer ne "") {
			$jobStepData = `ectool --server $::gServer getJobStepDetails $::gJobStepId`;
	        } else {
			$jobStepData = `ectool getJobStepDetails $::gJobStepId`;
		}
        }
    }

    my $xpath = XML::XPath->new($jobData);
    my $severity = collectData($xpath);
    if ($::gJobStepId ne "") {
        my $xpathl = XML::XPath->new($jobStepData);
        $severity = collectData($xpathl);
    }
    my $summary = summaryLine($xpath, $severity);

    buildReport($summary, $severity, $xpath);

    print $::gOutHandle $::gReport;

    # Send out e-mail if requested.

    if ($::gMailTo ne "") {
        sendMail($::gReport, $::gMailTo, $::gReplyTo,
                sprintf($::gEmailSubject, $summary));
    }
    if (($severity eq "error") && ($::gCulpritSubject ne "")
            && ($::gUpdateFile ne "")) {
        my @culprits = getCulprits($::gUpdateFile);
        bulkMail($::gReport, [@culprits], $::gReplyTo,
                sprintf($::gCulpritSubject,
                $xpath->findvalue('//job/jobName')));
    }

    # Clean up.

    unlink @::gTempFiles;
}

if ($^O eq "MSWin32") {
    $ENV{PERL5SHELL} = "sh";
}

main();
