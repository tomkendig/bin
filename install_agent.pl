#!/usr/local/bin/perl
use strict;
use Getopt::Long;

my %options = ( port => 0, install => 0, debug => 0 );

GetOptions( \%options, 'port=i', 'install!', 'debug' ) || die 'Wrong Options';

# Installs an EC agent on  a port keeping everything separate
# Relies on the installation on /opt
# Captured contents of important files in the DATA section, hack, but working for now.

my $port = $options{port};
defined($port) || die "usage: $0 PORT";
my $debug   = $options{debug};
my $install = $options{install};

print 'Running in ' . ( $debug ? 'DEBUG' : 'PRODUCTION' ) . " mode\n";

if ( $port >= 20 ) {
  die "port must be numeric and less than 20";
}

$port = 7800 + int($port);
print ""
  . ( $install ? 'Installing' : 'Removing' )
  . " agent on port $port !!!\n";

my @rcd_old_list = (
  '/etc/rc0.d/K01commanderAgent', '/etc/rc2.d/S99commanderAgent',
  '/etc/rc3.d/S99commanderAgent', '/etc/rc5.d/S99commanderAgent',
  '/etc/rc6.d/K01commanderAgent', '/etc/init.d/commanderAgent'
);

my @rcd_new_list = map {"$_$port"} @rcd_old_list;
my $a_template;
my $run_template;
my $conf_template;

my $code;
{
  local $/;
  $code = <DATA>
}

eval $code;

my $a_targ       = "/etc/init.d/commanderAgent$port";

# Stop standard agent just in case
my $cmd = ( $debug ? 'echo ' : '' ) . "/etc/init.d/commanderAgent stop";
system($cmd);

# Remove traces of standard install
foreach (@rcd_old_list) {
  if ( -e "$_" ) {
    if ($debug) {
      print "unlink $_\n";
    }
    else {
      unlink $_;
    }
  }
}

# create/remove a new commanderAgent
if ($install) {
  if ( -e $a_targ ) {
    print "Cannot install over existing agent, uninstall first\n";
    exit 1;
  }
  my @cont = split("\n", $a_template);
  my $ok;

  foreach (@cont) {
    if (s/^PORT=.*/PORT=$port/) {
      $ok = 1;
      last;
    }
  }

  if ( !$ok ) {
    print "$a_template is not suitable for multiple agent install!!!\n";
    exit 1;
  }

  if ( !$debug ) {
    open( FILE, ">$a_targ" ) || die "open >$a_targ:$!";
    print FILE join("\n", @cont);
    close FILE;
    chmod 0755, $a_targ;
  }
  else {
    print "create $a_targ\n";
  }
}
else {
  if ( !-e $a_targ ) {
    print "Nothing to unistall, install first\n";
    exit 1;
  }

  # Stop it first
  if ( !$debug ) {
    system("$a_targ stop");
    unlink $a_targ;
  }
  else {
    print "$a_targ stop\n";
    print "unlink $a_targ\n";
  }
}

# Create a new runAgent
my $run_targ = "/opt/electriccloud/electriccommander/bin/runAgent$port.sh";

if ($install) {
  my @cont = split("\n", $run_template);
  my $ok;
  foreach (@cont) {
    if (s/^PORT=.*/PORT=$port/) {
      $ok = 1;
      last;
    }
  }

  if ( !$ok ) {
    print "$run_template is not suitable for multiple agent install!!!\n";
    exit 1;
  }

  if ( !$debug ) {
    open( FILE, ">$run_targ" ) || die "open >$run_targ:$!";
    print FILE join("\n", @cont);
    close FILE;
    chmod 0755, $run_targ;
  }
  else {
    print "create $run_targ\n";
  }
}
else {
  if ($debug) {
    print "unlink $run_targ\n";
  }
  else {
    unlink $run_targ;
  }
}

# create a new conf file
my $conf_targ = "/opt/electriccloud/electriccommander/conf/agent$port.conf";

chdir("/opt/electriccloud/electriccommander/bin");
if ($install) {
  my @cont = split("\n", $conf_template);
  my $ok;
  foreach (@cont) {
    if (s/^port\s*=.*/port = $port/) {
      $ok = 1;
    }

    if (s!logFile = /opt/electriccloud/electriccommander/logs/agent/agent.*!logFile = /opt/electriccloud/electriccommander/logs/agent/agent$port.log!) {
      last;
    }
  }

  if ( !$ok ) {
    print "$conf_template is not suitable for multiple agent install!!!\n";
    exit 1;
  }

  if ( !$debug ) {
    open( FILE, ">$conf_targ" ) || die "open >$conf_targ:$!";
    print FILE join("\n", @cont);
    close FILE;

    # Create symlink to the agent executable
    symlink( 'ecmdrAgent', "ecmdrAgent$port" );
  }
  else {
    print "Updated $conf_targ\n";
    print "symlink ecmdrAgent, ecmdrAgent$port\n";
  }
}
else {
  if ($debug) {
    print "unlink /opt/electriccloud/electriccommander/bin/ecmdrAgent$port\n";
  }
  else {
    unlink "/opt/electriccloud/electriccommander/bin/ecmdrAgent$port";
  }
}

# Create symlinks
if ($install) {
  foreach (@rcd_new_list) {
    if ($debug) {
      print "symlink $a_targ, $_\n";
    }
    else {
      symlink( $a_targ, $_ );
    }
  }

  # Start it
  if ($debug) {
    system("echo $a_targ start");
  }
  else {
    system("$a_targ start");
  }
}
else {
  foreach (@rcd_new_list) {
    if ($debug) {
      print "unlink $_\n";
    }
    else {
      unlink $_;
    }
  }
}

__END__

#/etc/init.d/commanderAgent
$a_template = <<'EOF';
#!/bin/sh

# chkconfig: 235 99 01
# description: ElectricCommander Agent

# commanderAgent
#
# Copyright (c) 2006-2010 Electric Cloud, Inc.
# All rights reserved

# Substituted during installation:
VERSION=3.6.2.33030
INSTALLDIR=/opt/electriccloud/electriccommander
DATADIR=/opt/electriccloud/electriccommander

PORT=

if [ -z "$PORT" ] ; then
    echo Cannot run it directly
    exit 1
fi

# Set the process umask to a known safe value.

PATH=/usr/xpg4/bin:$PATH:/sbin:/usr/sbin:/usr/bin

cd /var/run
ulimit -c unlimited
umask 022

WHAT="Electric Cloud ElectricCommander Agent-${PORT}"

# Set up shorthand references for important locations.

AGENTBINDIR=$INSTALLDIR/bin                  ;# Absolute path to agent binaries
AGENTEXE=$AGENTBINDIR/ecmdrAgent${PORT}      ;# Absolute path to the ecmdrAgent
                                              # binary
ACCOUNT=sdkrel                  ;# If the value is something
                                              # other than 'root' (typically
                                              # set by an install script)
                                              # then the agent runs under
                                              # this account.
COLUMNS=250; export COLUMNS                  ;# some PS commands only return
                                              # $CLOMNS characters, and so
                                              # our 'stop' script would not work
#------------------------------------------------------------------------
# checkProcess
#
#       Checks whether any instances of the named processes are running.
#       Returns 0 if so, 1 if none are running.
#------------------------------------------------------------------------

checkProcess() {
    while [ "$1" ]; do
       if UNIX95=1 ps -ef | grep $1 | grep -v grep > /dev/null; then
           return 0
       fi
       shift
    done
    return 1
}

#------------------------------------------------------------------------
# killproc
#
#       Kill a process by name.
#
# Arguments:
#       sig     Signal to send to process.
#       name    Name of process to match against.
#------------------------------------------------------------------------

killproc() {
    if test -x /usr/bin/pkill ; then
        /usr/bin/pkill "$1" -P 1 -f "$2"
    else
        typeset p pp rest
        UNIX95=1 ps -ef -o pid,ppid,args | grep "$2" | (
            while read p pp rest ; do
                if [ "x$pp" = "x1" ]; then
                    kill "$1" "$p"
                fi
            done
        )
    fi
}

#------------------------------------------------------------------------
# startAgent
#
#       Start the agent.
#------------------------------------------------------------------------

startAgent() {
    if [ "$ACCOUNT" != "root" -a "$ACCOUNT" != "$(id -nu)" ]; then
        su - $ACCOUNT -c "$AGENTBINDIR/runAgent${PORT}.sh $INSTALLDIR $DATADIR $ACCOUNT"
    else
        ${AGENTBINDIR}/runAgent${PORT}.sh $INSTALLDIR $DATADIR
    fi

    if [ -d /var/lock/subsys ]; then
        /bin/touch /var/lock/subsys/commanderAgent${PORT}
    fi
}

#------------------------------------------------------------------------
# stopAgent
#
#       Attempt to terminate the agent process by sending a SIGTERM to the
#       process whose full path is $AGENTEXE.
#------------------------------------------------------------------------

stopAgent() {
    if [ -f /var/lock/subsys/commanderAgent${PORT} ]; then
        /bin/rm /var/lock/subsys/commanderAgent${PORT}
    fi

    if checkProcess $AGENTEXE 2>&1; then
        # Try TERM first, then KILL
        killproc -TERM "$AGENTEXE"

        # Check that the process no longer exists.  Unfortunately,
        # Solaris doesn't have a usleep command, or else we
        # could have slept for a millisecond and done one check.  Instead
        # we just do five checks in a row (hoping that if the process
        # was going to terminate, it would do so sometime during those
        # five checks.)  If the process is still alive, sleep for a
        # second and check again.  If it's still alive, sleep for three
        # seconds and check again.  If it's still alive, kill -KILL.

        if checkProcess $AGENTEXE && checkProcess $AGENTEXE \
                && checkProcess $AGENTEXE && checkProcess $AGENTEXE \
                && checkProcess $AGENTEXE && /bin/sleep 1 \
                && checkProcess $AGENTEXE &&  /bin/sleep 3 \
                && checkProcess $AGENTEXE ; then
            # Ok, the process is still alive.  Now it must feel the wrath
            # of the KILL signal!!

            echo "`/bin/date` Killing agent process with SIGKILL" \
                    >> /var/log/ecagent${PORT}.log

            killproc -KILL "$AGENTEXE"

            # Ok, this really should've worked.

            if checkProcess $AGENTEXE && checkProcess $AGENTEXE \
                    && checkProcess $AGENTEXE && checkProcess $AGENTEXE \
                    && checkProcess $AGENTEXE && /bin/sleep 1 \
                    && checkProcess $AGENTEXE ; then
                echo "Unable to kill ElectricCommander Agent${PORT}"
                RETVAL=1
            fi
        fi
    fi
}

# Unset DISPLAY; it can cause problems if the user has ssh'ed in with
# X connectioning turned on.

unset DISPLAY

# Parse the command line argument.
RETVAL=0
case "$1" in
    'start')
        # Start the agent.

    startAgent
    ;;

    'stop')
        # Stop the agent.

    stopAgent
    ;;

    'restart')
        # Stop, then start the agent.

    stopAgent
    startAgent
    ;;

    'start_msg')
        echo "Starting $WHAT"
        ;;
    'stop_msg')
        echo "Stopping $WHAT"
        ;;

    *)
        # Not a recognized option; just print a simple help message.

    echo "Usage: $0 { start | stop | restart }"
    ;;

esac

exit $RETVAL
EOF

#/opt/electriccloud/electriccommander/bin/runAgent.sh
$run_template = <<'EOF';
#!/bin/sh

######################################################################
#
# runAgent.sh
#
# Starts up the ElectricCommander Agent.
#
# Arguments:
#     INSTALLDIR -- The install directory
#     DATADIR    -- The data directory
#     ACCOUNT    -- Username that agent is to run as.  NOTE: This script
#                   does not change the uid.  This script is assumed to
#                   be running under the desired user's credentials
#                   (likely via 'su -').
######################################################################
PORT=

if [ -z "$PORT" ] ; then
    echo Cannot run it directly
    exit 1
fi

if [ $# -lt 2 -o $# -gt 3 ] ; then
    echo "Usage: $0 <installDir> <dataDir> [userName]"
    exit 2
fi

INSTALLDIR=$1
DATADIR=$2

# If the USER environment variable isn't set, and the user account was
# specified, set USER to that.

if [ -z "$USER" -a -n "$3" ] ; then
    USER=$3
    export USER
fi

# Unset DISPLAY -- nothing good can come of leaving it around (if it's set).
unset DISPLAY

# Now start the agent.
"${INSTALLDIR}/bin/ecmdrAgent${PORT}" --daemon --config "${DATADIR}/conf/agent${PORT}.conf"
EOF

#/opt/electriccloud/electriccommander/conf/agent.conf
$conf_template = <<'EOF';
# This file is used to provide configuration information to the
# ElectricCommander agent.  Some values set here may be overridden by
# command-line arguments to the ecmdrAgent binary.

# port -- Port that ElectricCommander Agent listens on. Defaults to 7800.
port = 7800

# Protocol of communication between the Agent and ElectricCommander server.
# Valid values are http and https.  Defaults to https.
proto=http

# Directory containing installed plugins.
pluginsPath = /opt/electriccloud/electriccommander/plugins

## Log settings ##

# Path where log file should be written.
logFile = /opt/electriccloud/electriccommander/logs/agent/agent.log

# Log messages of a particular severity and greater.  Valid values are
# TRACE, DEBUG, INFO, WARN, ERROR.  Defaults to DEBUG.
#logLevel = DEBUG

# Max size of the log file; the log rolls over after reaching this limit.
# The value may be suffixed with a unit: MB, KB, B.  Without a unit, the
# value is interpreted as bytes.  Defaults to 25MB.
logMaxSize = 25MB

# Maximum number of log files to accrue before deleting the oldest to make room
# for a new one.  A value of 0 means never delete old log files.
# Defaults to 40.
logMaxFiles = 40

# Size of the list of recently seen requests used in duplicate request
# detection.  Defaults to 200.
#duplicateDetectionListSize = 200

# Windows-only: ordinarily, the agent creates script-files with CRLF line
# termination.  But some shells on Windows require script files to be LF
# line-terminated, like Unix.  This option sets a regular expression pattern
# for such shells.  Defaults to a pattern that matches sh and bash, which
# in modern versions of Cygwin require LF-terminated script files.
unixShellPattern = (.*[/\])?(sh|bash)(\.exe)?

## Outbound request settings ##

# Socket connection timeout for outbound requests to a server.  Defaults
# to 10 seconds.
#serverConnectTimeout = 10

# Socket read timeout for responses from a server.  Defaults
# to 30 seconds.
#serverReadTimeout = 30

# Initial delay between retries for sending outbound requests to a server.
# Defaults to 5 seconds.
#outboundRequestInitialRetryInterval = 5

# Maximum delay between retries for sending outbound requests to a server.
# Defaults to 30 seconds.
#outboundRequestMaxRetryInterval = 30

# Timeout after which the agent gives up trying to send a request to a
# server.  Defaults to 24 hours.
#outboundRequestTimeout = 24

## Idle resource settings ##

# Idle time after which a Worker thread is terminated.  Defaults to 120
# seconds.
#idleWorkerTimeout = 120

# Idle time after which a PostRunner thread is terminated.  Defaults to 120
# seconds.
#idlePostRunnerTimeout = 120

# Idle time after which a ServerRequestWorker thread is terminated.  Defaults
# to 30 seconds.
#idleServerRequestWorkerTimeout = 30

# Idle time after which an outbound connection is closed.  Defaults
# to 30 seconds.
#idleOutboundConnectionTimeout = 30

## SSL settings ##

# Location of certificate and key files used by the agent to support
# SSL connections from the server.
keyFile = /opt/electriccloud/electriccommander/conf/agent.key
certFile = /opt/electriccloud/electriccommander/conf/agent.crt

# Whether or not to verify the certificate presented by the Commander server
# when it connects.  Defaults to false.
verifyPeer = false

# Path to trusted certificate authorities.  There are two ways to set this
# up:
#
# 1. a single file containing all of the CA certificates.
# 2. a directory containing a file for every CA, where each file's name is the 
#    CA subject name hash value.
#
# NOTE: Specifying a CA-file or CA-path is only needed if verifyPeer is true.
#       Also, these options are not mutually exclusive -- one can specify
#       a CA-file and CA-path.

caFile = 
caPath = 
EOF

