#!/opt/electriccloud/electriccommander/bin/ec-perl
#=============================================================================
# Name: test_any.pl 
#
# Original Author: Gregory Bergschneider(gbergsch)
#
# Date Created: March 10, 2011
#
# Purpose: Interacts with tests via the validat test API which performs the
#          coordinating of general test action with executable specific actions
#
# ChangeList: 
#
# Copyright
#
#=============================================================================

use strict;
use warnings;

$| = 1; # autoflush (only buffer a single print statement's worth of text to before printing/flushing stdout)

#===================================Globals===================================

# import the utility functions.
#use ValLibImport;
#use vutils;
#use dcl_globals;
#use logimg_proc;
#use errnum;
#use JSON::XS;
#use ValDB;
#use Switch;
#use File::Copy 'cp';
#use Sys::Hostname;
#use File::Path qw(rmtree mkpath);
#use Archive::Tar;
#use Time::HiRes;
use ElectricCommander;
#use Data::Dumper;
#use debugger;
#use Carp;
#use Cwd 'abs_path';

# ElectricCommander instance 
our $ec = ElectricCommander->new();
# Location to use for running tests and reading & writing log files (value gets updated in setupTarget())
our $executionDir = "";

# Logging Verbosity level (higher => more logs)
#our $debug = new debugger;
#$debug->setVerbose(2);
#$debug->print(1,"pwd=" . `pwd`);

our $softwareOSRegex    = '(SEM|HLM)';
#our $config             = decode_json(getStringParameter('ConfigJSON', \$ec));
#our $os                 = $config->{'OS'};
#our $osVersion          = $config->{'OSVersion'};
#our $osSubVersion       = $config->{'OSSubVersion'};
#our $appCode            = $config->{'AppCode'};
#our $appLoc             = $config->{'AppLoc'};
#our $mdmCode            = $config->{'MdmCode'};
#our $mdmLoc             = $config->{'MdmLoc'};
#our $userSystemBuild    = $config->{'UserSysBuild'};
#our $deviceInfo         = $config->{'Device'};
#    $deviceInfo         = decode_json(getStringParameter('DeviceJSON', \$ec)) if not $deviceInfo;
#our $buildJobID         = $config->{'BuildJobID'};
#our $standalone         = $config->{'Standalone'};
#    $standalone         = 0 if !defined($standalone);
#our $deviceID           = $deviceInfo->{'DeviceID'};
#our $targetID           = $deviceInfo->{'TargetID'};
#our $targetName         = $deviceInfo->{'TargetName'};
#our $targetType         = $deviceInfo->{'TargetType'};
#our $stepName           = getStringParameter('StepName', \$ec);
#our $driverDir          = "driver";

#our $testInfo           = $config->{'TestInfo'};
#our $intraBundles       = $testInfo->{'IntraBundles'};
    
#our %statusDecoder = (
#                $errnum{'ETESTFAIL'} => 'FAILED',
#                $errnum{'ETESTPASS'} => 'PASSED',
#                $errnum{'ETESTCOMPLETE'} => 'COMPLETED',
#                $errnum{'ETESTMAL'} => 'MALFUNCTIONED',
#                $errnum{'ETESTTO'} => 'TIMEDOUT'
#        );

our $resolution;
our $gpu;
our $agentID;

#our $success = $DCL_RETURN_STATUS{'SUCCESS'};
our $jobId   = $ENV{'COMMANDER_JOBID'};
    
our $status;
our $result;

our $sharedAPI;
our $intraBundle;
our $testModuleInput;
our $dcl;
our $dclLib;
#================================Routines=====================================
# main 
{
    $Carp::Verbose = 1; # force full stack trace on exit
#    $debug->print(1, "config = ".Dumper($config));
    
    my $setStatuses;
    if(not $standalone)
    {
        foreach my $bun (@$intraBundles)
        {
            foreach my $test (values(%{$bun->{Tests}}))
            {
                if(defined($test->{ValJobID}))
                {
                    push @$setStatuses, {JobID=>$test->{ValJobID},State=>'RUNNING'};
                }
            }
        }
        setStatus(\$ec,'RUNNING',$setStatuses) if ($setStatuses);
    }

    $setStatuses = undef;

    my $ret;
    eval
    {
        $ret = doWork();
    };
    $ret = -1 if !defined($ret);
    print "$@\n" if defined($@);
    foreach my $bun (@$intraBundles)
    {
        foreach my $test (keys(%{$bun->{Tests}}))
        {
            if(!defined($bun->{Tests}->{$test}->{Completed}) || 
                        $bun->{Tests}->{$test}->{Completed} != 1)
            {
                my $status = $bun->{Tests}->{$test}->{Status};
                my $valJobID = $bun->{Tests}->{$test}->{ValJobID};

                print "Status for $bun->{Name} test:$test :$status\n";
                print "JobID not defined for $test\n" if(!defined($valJobID));

                push @$setStatuses, {JobID=>$valJobID,State=>$status} if defined($valJobID);
            }
        }
    }
    setStatus(\$ec,'',$setStatuses) if(!$standalone && $setStatuses);

    exit($ret);
}

#-----------------------------------------------------------------------------
# Function: doWork 
#   - container for execution steps performed once an EC session has started
#-----------------------------------------------------------------------------
sub doWork
{
    my $ret;
    
    setupState();
    my $valJobIDs;
    foreach my $bun (@$intraBundles)
    {
        foreach my $test (values(%{$bun->{Tests}}))
        {
            push @$valJobIDs, $test->{ValJobID} if defined($test->{ValJobID});
        }
    }
    if(defined($valJobIDs))
    {
        ($status) = VALDB_updateJobs({ValJobID=>$valJobIDs, 
                                      ECJobID =>$jobId, 
                                      LogLoc  =>shortenPath(abs_path()),
                                      DeviceID=>$deviceID,
                                      AgentID =>$agentID
                                      });
    }

    $executionDir = '.';
    mkpath($executionDir);
    $executionDir = abs_path($executionDir);

    #Create all the results directories
    my $resultsDirs;
    foreach my $bun (@$intraBundles)
    {
        foreach my $test (values(%{$bun->{Tests}}))
        {
            push @$resultsDirs, "$executionDir/".$test->{ResultsDir};
        }
    }
    mkpath($resultsDirs);
    
    $ret = setupDCL();
    return $ret if(defined($ret) && $ret<0);
    
    $ret = setupTarget($config);
    return $ret if(defined($ret) && $ret<0);

    $ret = setupTestModules();
    return $ret if(defined($ret) && $ret<0);

    $ret = performTest($config);
    return $ret if(defined($ret) && $ret<0);
#    return $errnum{'EOK'};
}

#-----------------------------------------------------------------------------
# Function: setupState 
#   - Perform some nasty logic and bad practice to load globals with variables
#       we'll end up using again and again
#-----------------------------------------------------------------------------
sub setupState
{
    my %targetinfo;
    my %gpuinfo;

    if(defined($userSystemBuild) && (!-d $userSystemBuild))
    {
        print "ERROR: Could not locate user system build $userSystemBuild\n";
        $userSystemBuild    = undef;
    }

    if(!defined($deviceID))
    {
#        ($status, $result) = VALDB_getDeviceID({AgentName=>hostname,TargetID=>$targetID});
        return $status if $status < 0;
        $result = [keys(%{decode_json($result)})];
        #Pick a random attached device, all are of the same target so the device can be any
        $deviceID = $result->[int(rand(scalar(@$result)))];
        print "Failed to find device id, aborting\n" and return -1 if !defined($deviceID);
    }

    ($status, $result)  = VALDB_getTargetResolution({DeviceID=>$deviceID});
    return $status if ($status < 0);
    %targetinfo         = %{decode_json($result)->{$deviceID}};
    $resolution         = $targetinfo{TargetResX}."x".$targetinfo{TargetResY};

    ($status, $result)  = VALDB_getGPU({DeviceID=>$deviceID});
    return $status if ($status < 0);
    %gpuinfo            = %{decode_json($result)->{$deviceID}};
    $gpu                = $gpuinfo{'GPUName'};
    $gpu               .= '.'.$gpuinfo{'GPUVersion'} if (defined $gpuinfo{'GPUVersion'});

#    ($status, $result)  = VALDB_agents({AgentName=>hostname});
    return $status if ($status < 0);
    $agentID            = [keys(%{decode_json($result)})]->[0];
    
    $appLoc = $userSystemBuild if(defined($userSystemBuild));

    if(!defined($appLoc))
    {
        ($status, $result) = VALDB_getAppBuildLocation({AppCode=>$appCode});
        return $status if($status < 0);
        $appLoc = $result;
    }

    @INC = grep {not m|\.\.\/|} @INC;
    # Make sure we can find adb and fastboot utilities; these might be called in VT_SetConfig
    my $pathDelim = isWindows()?';':':';
    $ENV{'PATH'}  = $ENV{'PATH'}.$pathDelim."$main::valSourceRoot/common";

}

#-----------------------------------------------------------------------------
# Function: setupDCL
#   - Gather the information required and initialize the dcl object to be used
#       to interact with the target
#-----------------------------------------------------------------------------
sub setupDCL
{
    my $ret;
    my $jtagName;
    my $ppsName;     
    my $jtagOutlet;
    my $targetOutlet;
    my $usbOutlet;
    if ($standalone)
    {
        $jtagName        = "10.226.44.109";
        $ppsName         = "pps-vdev";
        $jtagOutlet      = 1;
        $targetOutlet    = 2;
        $usbOutlet       = 3;
    }
    else
    {
        ($status, $result)   = VALDB_getDeviceInfo({DeviceID=>$deviceID});
        $result              = decode_json($result)->{$deviceID};
        if(defined($result))
        {
            $jtagName        = $result->{DeviceJTAGName};
            $ppsName         = $result->{DevicePPSName};
            $jtagOutlet      = $result->{DeviceJTAGPPSOutlet};
            $targetOutlet    = $result->{DeviceTargetPPSOutlet};
            $usbOutlet       = $result->{DeviceUSBPPSOutlet};
        }
    }
    
    eval
    {
        #TODO: Find a better way to know DCL to use
        my $name = lc($os);
        $name = 'lsf' if($targetName=~/lsf/i);
        my $package = "dcl_$name";
        require "$package.pm";
        $dcl    = $package->new();
        if($targetName=~/lsf/i)
        {
            $name = "WIN_LSF" if($targetName=~/win/i);
            $name = "LNX_LSF" if($targetName=~/lnx/i);
        }
        elsif($targetName=~/hlm/i)
        {
            $name = "WIN_SEM" if($targetName=~/win/i);
            $name = "LNX_SEM" if($targetName=~/lnx/i);
        }
        $dclLib = uc($name);
    };
    if(!defined($dcl))
    {
        print "Failed to load DCL: $@\n";
        return -1;
    }
#    if(!defined($dclLibs{$dclLib}))
#    {
#        print "DCL loaded: $dclLib, is not in dclLibs for sharedAPI to know about\n";
#        return -1;
#    }
    $ret = $dcl->InitDevice({OS=>$os,
                             OSVersion=>$osVersion,
                             OSSubVersion=>$osSubVersion,
                             TargetName=>$targetName,
                             TargetType=>$targetType,
                             Modem=>{Location=>$mdmLoc,ID=>$mdmCode},
                             AppsImgLocation=>$appLoc,  #Always a full Android build for now
                             JobRoot=>$executionDir,
                             JTAGName=>$jtagName,
                             PPSName=>$ppsName,
                             JTAGOutlet=>$jtagOutlet,
                             TargetOutlet=>$targetOutlet,
                             USBOutlet=>$usbOutlet});
#    if(defined($ret) && $ret != $success)
#    {
#        print "ERROR:Init Device Failed\n";
#        return $errnum{'EUNKNOWN'};
#    }
    return 0;
}

#-----------------------------------------------------------------------------
# Function: setupTestModules
#   - Import all sharedAPI objects and instantiate them
#-----------------------------------------------------------------------------
sub setupTestModules
{
    #Import the test modules so I can start driving their behavior
    my $fetched;
    foreach my $bun(@$intraBundles)
    {
        my $bundleLocation = "";
        my $sharedAPI;
        my $ret;
        my $bVerID = $bun->{BundleVersionID};
        if(!defined($fetched->{$bVerID}))
        {
            ($status, $result) = VALDB_getBundleVersionInfo({BundleVersionID=>$bVerID});
            return $status if($status < 0);
            $fetched->{$bVerID}->{TestRoot} = decode_json($result)->{$bVerID}
                                                ->{BundleVersionLocation};
            $fetched->{$bVerID}->{TestRoot} = "$main::valLibRoot/".
                                            shortenPath($fetched->{$bVerID}->{TestRoot});
            push(@INC, $fetched->{$bVerID}->{TestRoot});
            #Only needs required once even if there are multiple interbundles for it
            eval
            {
                require $fetched->{$bVerID}->{TestRoot}."/sharedAPI.pm";
            };
            print "ERROR:$@\nDid you perhaps provide the wrong location when".
                   " adding your bundle?\n" and return -1 if($@);
        }
        my $testRoot = $fetched->{$bVerID}->{TestRoot};
        
        $testModuleInput = {Tests=>getSAPITests($bun->{Tests}),
                            JobRoot=>$executionDir,
                            TestRoot=>$testRoot,
                            DriverDir=>$driverDir,
                            OS=>$os,
                            OSVersion=>$osVersion,
                            OSSubVersion=>$osSubVersion,
                            TargetName=>$targetName,
                            TargetType=>$targetType,
                            DCLObject=>\$dcl,
                            DCLLib=>$dclLib
                        };
        eval
        {
            $sharedAPI = sharedAPI->new($testModuleInput);
        };
        print "ERROR:$@\n" and return -1 if($@);
        if(!defined($sharedAPI))
        {
            print "ERROR: Failed to create sharedAPI object\n";
            return -1;
        }
        eval
        {
            $ret = $sharedAPI->VT_SetConfig($testModuleInput);
        };
        print "ERROR:$@\n" and return -1 if($@);
        return $ret if(defined($ret) && $ret<0);
        $bun->{SharedAPI} = \$sharedAPI;
    }
}

#-----------------------------------------------------------------------------
# Function: setupTarget
#   - Performs the interaction with the target to ensure it's ready to perform
#       the test.
#-----------------------------------------------------------------------------
sub setupTarget
{
    my $ret    = 1;
    my $loaded = {};
    my $toLoad = {};
    my $buildID;

    if ($standalone)
    {
        if ($os eq "HLM")
        {
            $ret = loadDriver({
                    #Driver location relative to $main::valLibRoot
                DriverLoc => "driver_store/12210/"
            });
        }
        else
        {
            my $undefinedVal;
            $ret = loadModem({LoadedRef=>$undefinedVal});
#            return $ret if($ret != $success);

#            $ret = loadOS({LoadedRef=>$loaded});
#            return $ret if($ret != $success);
        }
    }
    else
    {
#        ($status, $result) = VALDB_getDeviceBuilds({DeviceID=>$deviceID});
#        return $status if $status < 0;
#        $result = decode_json($result);
#        $loaded = [values(%$result)]->[0] if(scalar(values(%$result))>0);

#        #NOTE: All jobs given to test_any in a batch should have the same BuildID
#        my $tempJobID =  [values(%{$intraBundles->[0]->{Tests}})]->[0]->{ValJobID};
#        print "Fetching buildID for job $tempJobID\n"; 
#        ($status, $buildID) = VALDB_getJobBuildID({JobID=>$tempJobID});
#        return $status if $status < 0;
#        print "ERROR: Invalid buildID\n" and return -1 if !defined($buildID);

#        ($status, $result) = VALDB_getBuilds({BuildID=>$buildID});
#        return $status if $status < 0;
#        $toLoad = decode_json($result)->{$buildID};
#        $toLoad = {{}} if(!defined($toLoad));

#        #Execution option No Load System
#        my $noLoadSys = $testInfo->{ExecCtrl}->{NoLoadSys};
#        if(!defined($noLoadSys) || (defined($noLoadSys) && $noLoadSys == 0))
#        {
#            $ret = loadModem({LoadedRef=>$loaded});
#            return $ret if($ret != $success);

#            $ret = loadOS({LoadedRef=>$loaded});
#            return $ret if($ret != $success);
#        }
        
#        #Execution option No Load Driver
#        my $noLoadDrvr = $testInfo->{ExecCtrl}->{NoLoadDvr};
#        if(!defined($noLoadDrvr) || (defined($noLoadDrvr) && $noLoadDrvr == 0))
#        {
#            $ret = loadDriver({ToLoad=>$toLoad,Loaded=>$loaded});
#            return $ret if($ret != $success);
#        }

        #Must load both to accurately determine what's on the device, need to clear if not.
#        if((defined($noLoadDrvr) && $noLoadDrvr != 0) ||
#           (defined($noLoadSys) && $noLoadSys != 0))
#        {
#            $buildID = undef;
#        }
        #Update the build reference in the database so I can query later what's preloaded
#        ($status) = VALDB_setDeviceBuildID({BuildID=>$buildID, DeviceID=>$deviceID});
#        return $status if($status < 0);
    }

#    return $errnum{'EOK'};
}

#-----------------------------------------------------------------------------
# Function: loadModem 
#   - Given the possible MdmCode and MdmLoc as well as a hash reference to the
#       info of what's loaded in the device already, LoadedRef, program the
#       modem if necessary.
#-----------------------------------------------------------------------------
sub loadModem
{
    my ($args) = @_;
    my $loaded  = $args->{LoadedRef};
    foreach(keys(%$loaded))
    {
        my $name = $loaded->{$_}->{ComponentName};
        $loaded = $loaded->{$_} if(defined($name) && $name eq 'ModemBuild');
    }

    $loaded->{ComponentCode} = undef if(defined($userSystemBuild));

    if (
        (!defined($loaded->{ComponentCode}) && (defined($mdmCode) || defined($mdmLoc))) ||
        (defined($mdmCode) && ($mdmCode ne $loaded->{ComponentCode})) ||
        (defined($mdmLoc)  && ($mdmLoc  ne $loaded->{ComponentLocation})))
    {
        print "\n***Loading Modem***\n";
        my $retval = $dcl->LoadModem();
#        if($retval != $success)
#        {
#            print "ERROR:Load Modem Failed\n";
#            return $errnum{'EUNKNOWN'};
#        }
    }
#    return $success;
}

#-----------------------------------------------------------------------------
# Function: loadOS 
#   - Given the possible AppCode and AppLoc as well as a hash reference to the
#       info of what's loaded in the device already, LoadedRef, program the
#       apps processor if necessary.
#-----------------------------------------------------------------------------
sub loadOS
{
    my ($args) = @_;
    my $loaded  = $args->{LoadedRef};
    foreach(keys(%$loaded))
    {
        my $name = $loaded->{$_}->{ComponentName};
        $loaded = $loaded->{$_} if(defined($name) && $name eq 'ApplicationBuild');
    }

    $loaded->{ComponentCode} = undef if(defined($userSystemBuild));

    if(!defined($loaded->{ComponentLocation}) || $appLoc ne $loaded->{ComponentLocation})
    {
        print "\n***Loading OS***\n";
        my $retval = $dcl->LoadOS();
#        if($retval != $success)
#        {
#            print "ERROR:Load OS Failed\n";
#            return $errnum{'EUNKNOWN'};
#        }
    }
#    return $success;
}

#-----------------------------------------------------------------------------
# Function: loadDriver
#   - Perform the actions necessary to fetch the driver binary from storage,
#       determine its contents, and instruct the DCL to load the binary on the
#       target.
#-----------------------------------------------------------------------------
sub loadDriver
{
    my ($args) = @_;
    print "\n***Fetching Driver Binaries***\n";
   
    my $toLoad = [values(%{$args->{ToLoad}})]->[0];
    my $loaded = [values(%{$args->{Loaded}})]->[0];
    my $driverLocation = $toLoad->{DriverLocation};

    $driverLocation = "{OS}" if($toLoad->{DriverType} eq 'BUILD');
    if(!defined($driverLocation))
    {
        print "ERROR: Could not find the driver for this test\n";
#        return $errnum{'EIO'};
    }

    if($driverLocation!~/{OS}/)
    {
        my $file = "driver.tgz";
        $driverLocation = "$main::valLibRoot/".shortenPath($driverLocation);
        if($driverLocation!~/(\.tgz)$/)
        {
            $driverLocation = "$driverLocation/$file";
        }
        else
        {
            $driverLocation=~/(\/\w+\.tgz)$/;
            $file = $1 if defined($1);
        }

        chdir($executionDir);
        if(!cp($driverLocation,'.'))
        {
            print "ERROR:Copy of driver tarball failed\n";
#            return $errnum{'EIO'};
        }
        #Archive::Tar is known to have performance limitations so it may need reverted
        my $tarball = Archive::Tar->new();
        $tarball->read($file);
        if(!defined $tarball)
        {
            print "Failed to make perl object of tarball\n";
#            return $errnum{'EIO'};
        }
        my @files = $tarball->extract();
#        print "Tarball extraction failed\n" and return $errnum{'EIO'} if(@files == 0);
        rmtree($file);

        #$driverDir = $files[0]->prefix; #Always driver if Validat makes the tarball
                                        #could be different or empty if from user
        $driverDir = "" if !defined($driverDir);
        $driverDir = "$executionDir/$driverDir";

        print "\n***Driver used for this test can be found in $driverLocation ***\n";

        chdir('..');

        if($toLoad->{DriverID} != $loaded->{DriverID} || $os =~ /$softwareOSRegex/i)
        {
            print "\n***Loading Driver***\n";
    
            my $driverInfo = readBuildFiles($driverDir);

            my $retval = $dcl->LoadDriver({DrvSrcDir=>$driverDir,
                                           FwSrcDir=>$driverDir,
                                           DrvDstDir=>$driverInfo->{DriverDst},
                                           FwDstDir=>$driverInfo->{FirmwareDst},
                                           DrvFilesListR=>$driverInfo->{DriverFiles},
                                           FwFilesListR=>$driverInfo->{FirmwareFiles}
                                           });
#            if($retval != $success)
#            {
#                print "ERROR:Load Driver Failed\n";
#                return $errnum{'EUNKNOWN'};
#            }
        }
    }
#    return $success;
}

#-----------------------------------------------------------------------------
# Function: removeWSDriver
#   - Delete the local driver directory made available to the test, no longer
#       needed
#-----------------------------------------------------------------------------
sub removeWSDriver
{
    rmtree("$driverDir") if(defined($executionDir));
}

#-----------------------------------------------------------------------------
# Function: performTest 
#   - Perform the steps in order that a test is expected to execute 
#-----------------------------------------------------------------------------
sub performTest
{
    my $ret;
    my $start;
    foreach my $bun (@$intraBundles)
    {
        $sharedAPI = $bun->{SharedAPI};
        $intraBundle = $bun;
        my @testNames = keys(%{$bun->{Tests}});
        my $statuses;
        eval {$ret = $$sharedAPI -> VT_DebugSetCallback("callbackTo");};
        print "ERROR:$@\n" if($@);
        
        $statuses->{$_} = {String=>"Loading"}foreach(@testNames);
        callbackTo({Action=>"UpdateStatus",Statuses=>$statuses});

        print "\n***Loading***\n";
        eval {$ret = $$sharedAPI -> VT_Load(\@testNames);};
        print "ERROR:$@\n" and $ret = -1 if($@);
#        $debug->print(1, "VT_Load returns $ret\n");
        print "***Loading Failed***\n" and return $ret      if(defined($ret) && $ret<0);
        
        $statuses->{$_} = {String=>"Executing"}foreach(@testNames);
        callbackTo({Action=>"UpdateStatus",Statuses=>$statuses});

        print "\n***Executing***\n";
#        $start = Time::HiRes::time;
        eval {$ret = $$sharedAPI -> VT_Execute(\@testNames);};
        print "ERROR:$@\n" if($@);
#        my $exeTime = Time::HiRes::time - $start;
#        print "***Executed in $exeTime seconds***\n";
        print "***Execution Failed***\n" and return -1      if(!defined($ret));
        
        $statuses->{$_} = {String=>"Execution Complete"}foreach(@testNames);
        callbackTo({Action=>"UpdateStatus",Statuses=>$statuses});

        $ret = processFinished($ret);
        print "***Processing failed but there may have not been".
                             " any results to process***\n" if(defined($ret) && $ret<0);

        
        print "\n***Unloading***\n";
        eval {$ret = $$sharedAPI -> VT_Unload(\@testNames);};
        print "ERROR:$@\n" if($@);
        print "***Unloading Failed***\ncontinuing\n"        if(defined($ret) && $ret<0);

        print "\n***Cleaning Up***\n";
        eval{ $ret = $$sharedAPI -> VT_Clean(\@testNames);};
        print "ERROR:$@\n" if($@);
        print "***Clean Up Failed***\ncontinuing\n"         if(defined($ret) && $ret<0);
        
        $statuses->{$_} = {String=>"Cleanup Complete"}foreach(@testNames);
        callbackTo({Action=>"UpdateStatus",Statuses=>$statuses});
    } 
    removeWSDriver();

    return 0;
}

#-----------------------------------------------------------------------------
# Function: processFinished 
#   - Given the result of a test from either the callback or from VT_Execute,
#       process results and seek out images and KPIs for the finished tests.
#-----------------------------------------------------------------------------
sub processFinished
{
    my ($statuses) = @_;
    my $ret;
    my $images;
    my $kpis;
    my $jobIDs;
    my $setStatuses;
    print Dumper($statuses)."\n" and return -1 if(ref($statuses) ne 'HASH');
    foreach(keys(%$statuses))
    {
        next if (!defined($_) || $_ eq '');
        my $valJobID = $intraBundle->{Tests}->{$_}->{ValJobID};
        print "JobID not defined for $_\n" and next if(!defined($valJobID));
        my $outcome = $statuses->{$_}->{Result};
#        if(defined($outcome)&& defined($statusDecoder{$outcome}))
#        {
#            $intraBundle->{Tests}->{$_}->{Completed} = 1;
#            $intraBundle->{Tests}->{$_}->{Status} = $statusDecoder{$outcome};
#        }
#        else
#        {
#            print "Invalid result for $_, ".Dumper($statuses->{$_})."\n";
#            $intraBundle->{Tests}->{$_}->{Status} = 'UNKNOWN';
#        }
        
        callbackTo({Action=>"UpdateStatus",Statuses=>{$_=>{String=>"Execution Complete"}}});
        
        if(defined($statuses->{$_}->{Time}) && defined($valJobID))
        {
            VALDB_setJobExecTime({Time=>$statuses->{$_}->{Time},
                                  JobID=>$valJobID,
                                  TestID=>$intraBundle->{Tests}->{$_}->{TestID},
                                  TargetID=>$targetID,
                                  OS=>$os,
                                  OSVersion=>$osVersion,
                                  OSSubVersion=>$osSubVersion}) if not $standalone;
        }
        print "\n***Receiving Images for $_***\n";
        eval {$images = $$sharedAPI -> VT_ImageUpload([$_])->{$_};};
        print "ERROR:$@\n" if($@);
        print "***Received No images for $_***\n"       if(!defined($images) || scalar(@$images)==0);

        print "\n***Receiving KPIs for $_***\n";
        eval {$kpis = $$sharedAPI -> VT_KPIUpload([$_])->{$_};};
        print "ERROR:$@\n" if($@);
        print "***Received No KPIs for $_***\n"         if(!defined($kpis) || scalar(@$kpis) == 0);

        if ((not $standalone) and defined($images) and (scalar(@$images)>0))
        {
            print "\n***Comparing Images for $_***\n";
            $ret = imageDiff($images,$_);
            print "***Image Compare Failed for $_***\n" if(defined($ret) && $ret<0);
        }
        
        if(defined($kpis) and scalar(@$kpis) > 0)
        {
            print "\n***KPI Processing for $_***\n";
            $ret = processKPI($kpis,$_);
            print "***Processing Failed for $_***\n"    if(defined($ret) && $ret<0);
        }
        my $status = $intraBundle->{Tests}->{$_}->{Status};
        print "Status for $intraBundle->{Name} test:$_ :$status\n";
        push @$setStatuses, {JobID=>$valJobID,State=>$status};
    }
    
    setStatus(\$ec,'',$setStatuses) if(!$standalone && $setStatuses);
    return 0;
}

#-----------------------------------------------------------------------------
# Function: processKPI 
#   - Given a list reference containing hash references of KPI information to
#       be printed and inserted in the database
#-----------------------------------------------------------------------------
sub processKPI
{
    my ($kpis,$testName) = @_;
    return -1 if(ref($kpis) ne 'ARRAY');
    my $test = $intraBundle->{Tests}->{$testName};
    foreach (@$kpis)
    {
        print "ERROR: Unformated KPI:$_\n" and next if(ref($_) ne "HASH");
        my $kpiName   = $_->{Name};
        my $kpiVal    = $_->{Value};
        my $kpiGoal   = $_->{Goal};
        my $kpiResult = $_->{Result};
        my $kpiComment= $_->{Comment};
        my $kpiPercent= 0;
        if(!defined($kpiName) || !defined($kpiResult))
        {
            print "ERROR: Poorly Formatted KPI:",Dumper($_);
            next;
        }
        if (defined($kpiVal) and defined($kpiGoal) and $kpiGoal > 0)
        {
            $kpiPercent = $kpiVal/$kpiGoal*100;
        }

        #Fill out optional values if not present
        $kpiVal      = "" if !defined($kpiVal);
        $kpiGoal     = "" if !defined($kpiGoal);
        $kpiComment  = "" if !defined($kpiComment);

        VALDB_insertKPI({JobID=>$test->{ValJobID},
                         Used=>$test->{KPI},
                         Name=>$kpiName,
                         Val=>$kpiVal,
                         Goal=>$kpiGoal,
                         Result=>$kpiResult,
                         Percent=>$kpiPercent,
                         Comment=>$kpiComment
        }) if not $standalone and defined($test->{ValJobID});

        #pad results so prints look pretty
        $testName   = spacePad(40,$testName);
        $kpiName    = spacePad(12,$kpiName);
        $kpiVal     = spacePad(8, $kpiVal);
        $kpiGoal    = spacePad(8, $kpiGoal);
        $kpiPercent = spacePad(4, $kpiPercent);
        $kpiResult  = spacePad(16,$kpiResult);
        $kpiComment = spacePad(43,$kpiComment);

        print "$intraBundle->{Name} $testName: [$kpiResult] | Name:$kpiName | Value:$kpiVal ".
              "| Goal:$kpiGoal | Percent:$kpiPercent | Comment:$kpiComment\n";
    }
    return 0;
}

#-----------------------------------------------------------------------------
# Function: imageDiff 
#   - Collect the information required and execute the image compare tool
#       logging the results of the image compare for display in the UI.
#   - Results expected to be relative paths to the test's ResultDir
#-----------------------------------------------------------------------------
sub imageDiff
{
    my ($resultsList,$testName) = @_;
    my $imageExts   = 'png|tga';#Formats compatible with the diff tool
    my $goldenPaths;
    my $goldenIDs;
    my $albumVersion;
    my $existsAlbum = 0;
    #$intraBundle should be initialized before calling this function
    my $albumID     = $intraBundle->{AlbumID};
    my $valJobID    = $intraBundle->{Tests}->{$testName}->{ValJobID};
    my $resultsDir  = $intraBundle->{Tests}->{$testName}->{ResultsDir};
    #$sharedAPI should be initialized before calling this function
    my $cmpParams   = $$sharedAPI -> VT_GetImgCmpParams([$testName])->{$testName};
    my $filter      = (defined($cmpParams->{Filter})   ?$cmpParams->{Filter}   :1);
    my $threshold   = (defined($cmpParams->{Threshold})?$cmpParams->{Threshold}:1);
    my $behavior    = (defined($cmpParams->{Behavior}) ?$cmpParams->{Behavior} :
                                                             1);
#                                                             $errnum{'ETESTFAIL'});
    my $comparesPassed = 1;
    #Add to path the location of imace
    my $pathDelim = isWindows()?';':':';
    $ENV{'PATH'}  = $ENV{'PATH'}.$pathDelim."$main::valSourceRoot/common";

    foreach(0..@$resultsList-1)
    {
        $resultsList->[$_] = normalizeImagePath($resultsList->[$_],$resultsDir);
    }

    convertImages($resultsList);

    if(defined($albumID))
    {
        ($status,$goldenPaths,$goldenIDs) = findImgsPath($resultsList,$testName);
        if($status >= 0)
        {
            $existsAlbum = 1;
            ($status, $result) = VALDB_getAlbumInfo({AlbumID=>$albumID});
            return $status if ($status < 0);
            $albumVersion = decode_json($result)->{$albumID}->{AlbumVersion};
        }
    }
    
    for(my $i=0;$i<@$resultsList;$i++)
    {
        my $rimage = $resultsList->[$i];
        my $gimage = $goldenPaths->[$i];
#        my $match  = $LOGIMG_IMG_MATCH{'mismatch'};
        my $failed = 1;
        my $error  = 1;
        my $status;
        my $totDiff;
        my $firstDiff;
        my $xDiff;
        my $yDiff;

        if($rimage!~/($imageExts)$/i)
        {
            $comparesPassed = 0;
            print "ERROR: File ext of $rimage is not comparable by validat\n";
        }
        elsif(!-e $rimage)
        {
            $comparesPassed = 0;
            print "ERROR: Failed to find expected image: $rimage\n";
        }
        elsif(!$existsAlbum)
        {
            $comparesPassed = 0;
            print "ERROR: Have no album with which to diff against $rimage.\n";
        }
        elsif(!defined $goldenPaths->[$i])
        {
            $comparesPassed = 0;
            print "Golden Image not found to compare.\n";
        }
        else
        {
            my @parts = split('/',$rimage);
            $parts[-1] = 'diff_'.$parts[-1];
            my $dimage = join('/',@parts);
            print "Found image $rimage.\tComparing to golden now...";
#            ($status, $match, $totDiff, $xDiff, $yDiff) = 
#                LOGIMG_img_cmp($rimage,$gimage,$filter,$threshold,$dimage);
#            if($status == $LOGIMG_IMG_STATUS{'SUCCESS'})
#            {
#                if($match == $LOGIMG_IMG_MATCH{'match'})
#                {
#                    print "match!\n";
#                    $failed= 0;
#                    $error = 0;
#                }
#                elsif($match == $LOGIMG_IMG_MATCH{'mismatch'})
#                {
#                    print "mismatch.\nERROR: Images don't match.\n";
#                    $error  = 0;
#                }
#                else
#                {
#                    print "error.\nERROR: System error in comparing\n";
#                    print "Input: $rimage, $gimage, $filter, $threshold, diff_$rimage\n";
#                }
#            }
#            else
#            {
#                print "\nERROR: Status '$status' returned from the diff tool\n";
#                print "Input: $rimage, $gimage, $filter, $threshold, diff_$rimage\n";
#            }
            $comparesPassed = 0 if($failed || $error);
        } 
        if(defined($xDiff) && defined($yDiff))
        {
            $firstDiff = encode_json({x=>"$xDiff",y=>"$yDiff"});
        }
        $rimage=~s/\\/\//;#change backslashes to forwardslashes
        $rimage=~s/$executionDir//;#remove execution dir which is the storage expectation
        ($status) = VALDB_logImageCompare({Threshold    =>$threshold, 
                                            Filter      =>$filter, 
                                            Result      =>$rimage, 
                                            AlbumVersion=>$albumVersion,
                                            GoldPath    =>shortenPath($gimage),
                                            GoldID      =>$goldenIDs->[$i],
                                            ValJobID    =>$valJobID,
                                            Match       =>($failed>0?0:1),
                                            TotDiff     =>$totDiff,
                                            FirstDiff   =>$firstDiff,
                                            Error       =>$error}) if defined($valJobID);
    }
    print "\n";
#    my $exeResult = $intraBundle->{Tests}->{$_}->{Status};
#    if(($exeResult eq $statusDecoder{$errnum{'ETESTPASS'}}
#            || $exeResult eq $statusDecoder{$errnum{'ETESTCOMPLETE'}})
#        && $comparesPassed==0 
#        && $behavior != $errnum{'ETESTIGN'})
#    {
#        $intraBundle->{Tests}->{$_}->{Status} = $statusDecoder{$behavior};
#    }
    return ($comparesPassed>0?0:-1);
}

#-----------------------------------------------------------------------------
# Function: findImgsPath 
#   - Searches for matching golden images in the album to those result images
#       produced using the algorithm determined for placement priority of 
#       golden images within the album
#-----------------------------------------------------------------------------
sub findImgsPath
{
    my ($imgsRef,$testName) = @_;
    my @imgs;
    return if(scalar(@$imgsRef) == 0);
    foreach(@$imgsRef)
    {
        my @parts = split('/',$_);
        push @imgs, $parts[-1];
    }
    my @goldenPaths;
    my @goldenVers;
    my @goldenIDsOut;
    my $albumID = $intraBundle->{AlbumID};
    my ($status, $result) = VALDB_getAlbum({AlbumID=>$albumID});
    return $status if $status < 0;
    my @album = @{decode_json($result)};
    return -1 if scalar(@album) < 1;
    my $albumPath = "$main::valLibRoot/".shortenPath($album[0]->{AlbumPath});
    my $inSandbox = $album[0]->{AlbumInSandbox};
       $inSandbox = 0 if !defined($inSandbox);

    my ($goldenImagesRef, $versionsRef, $idsref) = getImagesFromAlbum(\@album);
    my @goldenImages = @$goldenImagesRef;
    my @goldenVersion= @$versionsRef;
    my @goldenIDs    = @$idsref;

    my @pos;
#    push @pos, "$testName/$os/$targetName/$targetType/$resolution" if (defined($targetType));
#    push @pos, "/$os/$targetName/$targetType/$resolution" if (defined($targetType));
#    push @pos, "$testName/$os/$targetName/$resolution";
#    push @pos, "/$os/$targetName/$resolution";
#    push @pos, "$testName/$os/$targetName";
#    push @pos, "/$os/$targetName";
#    push @pos, "$testName/$os";
#    push @pos, "/$os";
#    push @pos, "$testName/$targetName/$targetType/$resolution" if (defined($targetType));
#    push @pos, "/$targetName/$targetType/$resolution" if (defined($targetType));
#    push @pos, "$testName/$targetName/$resolution";
#    push @pos, "/$targetName/$resolution";
#    push @pos, "$testName/$targetName";
#    push @pos, "/$targetName";
#    push @pos, "$testName/$targetType/$resolution" if (defined($targetType));
#    push @pos, "/$targetType/$resolution" if (defined($targetType));
#    push @pos, "$testName/$resolution";
#    push @pos, "/$resolution";
#    push @pos, "$testName";
#    push @pos, "";

#    foreach my $loc (@pos)
#    {
#        for(my $j=0;$j<@goldenImages;$j++)
#        {
#            for(my $i=0;$i<@imgs;$i++)
#            {
#                if($goldenImages[$j] eq "$loc/$imgs[$i]" && !defined($goldenPaths[$i]))
#                {
#                    my $imageName = ($inSandbox==0?"$goldenVersion[$j]_":"")."$imgs[$i]";
#                    if(!-e "$albumPath/$loc/$imageName")
#                    {
#                        print "Image at $albumPath/$loc/$imageName was not found. ".
#                              "DB inconsistent with file system\n";
#                        if(!$inSandbox)
#                        {
#                            print "Please forward this job to ".
#                                    "graphics.sw.vdev.validat.support\n";
#                        }
#                        next;
#                    }
#                    $goldenPaths[$i] = "$albumPath/$loc/$imageName";
#                    $goldenIDsOut[$i]= $goldenIDs[$j];
#                }
#            }
#        }
#    }

    return (0,\@goldenPaths,\@goldenIDsOut);
}

#-----------------------------------------------------------------------------
# Function: getImagesFromAlbum 
#   - Composes the paths and versions of all the images in the provided album
#       array and returns two references to the arrays holding the two datums
#-----------------------------------------------------------------------------
sub getImagesFromAlbum
{
    my ($albumRef) = @_;
    my @images = ();
    my @imageVersions = ();
    my @ids = ();
    foreach (@$albumRef)
    {
        my %image = %$_;
        push @images, $image{ImagePath}.'/'.$image{ImageFileBaseName};
        push @imageVersions, $image{ImageVersion};
        push @ids, $image{ImageID};
    }
    return (\@images,\@imageVersions,\@ids);
}

#-----------------------------------------------------------------------------
# Function: convertImages 
#   - convert images received from the test to png which can be displayed in browsers
#-----------------------------------------------------------------------------
sub convertImages
{
    my ($resultsList) = @_;
    my @imageExtensions = ('tga');#Formats compatible with the convert tool
    my $convert = "convert";
    #Add to path the location of convert for windows, Unix should have it in path already
    if(isWindows())
    {
        $convert = "$main::valLibRoot/tools/ImageMagick/$convert";
    }
    for(my $i=0;$i<@$resultsList;$i++)
    {
        for my $ext (@imageExtensions)
        {
            if($resultsList->[$i]=~/$ext$/ && -e $resultsList->[$i])
            {
                #Convert
                if($ext ne 'png')
                {
                    my $oldname = $resultsList->[$i];
                    #Name w/o extension which could be 3 to 4 characters after a period
                    $oldname=~/(.*)\.\w{3,4}$/;
                    my $newname = "$1.png";
                    my $convOut = `$convert $ext:$oldname $newname 2>&1`;
                    if($convOut ne '')
                    {
                        print "ERROR: conversion of $oldname to $newname".
                                " failed: $convOut\n";
                    }
                    elsif(-e $newname)
                    {
                        system("rm $oldname"); 
                        $resultsList->[$i] = $newname;
                    }
                }
            }
        }
    }
}

#-----------------------------------------------------------------------------
# Function: normalizeImagePath 
#   - Given an image from the sharedAPI and the resultsDirectory form the full
#       path to the image irrelevant of the current directory.
#-----------------------------------------------------------------------------
sub normalizeImagePath
{
    my ($rimage,$rdir) = @_;
    $rdir=~s/\\/\//g;
    $rdir=~s/\/\//\//g;
    $rimage=~s/\\/\//g;
    $rimage=~s/\/\//\//g;
    $rdir=~s/\/+$//;
    my $edir = $executionDir;
    $edir=~s/\/+$//;
    $rimage=~/$rdir\/(.*)/;
    return "$edir/$rdir/".(defined($1)?$1:$rimage);
}

#-----------------------------------------------------------------------------
# Function: spacePad 
#   - Add spaces to the end of $val so it's a string of length $len
#-----------------------------------------------------------------------------
sub spacePad
{
    my ($len, $val) = @_;
    my $needed = $len-length($val);
    $needed = 0 if $needed < 0;
    return $val.(' 'x$needed);
}

#-----------------------------------------------------------------------------
# Function: callbackTo 
#   - Handler for VTAPI callbacks 
#-----------------------------------------------------------------------------
sub callbackTo
{
    my ($hashRef) = @_;
    my $action = $hashRef->{Action};
    use Switch;
    switch($action)
    {
        case "UpdateStatus" 
        {
            my $statuses = $hashRef->{Statuses};
            foreach(keys(%$statuses))
            {
                my $percent = $statuses->{$_}->{Percent};
                my $status  = $statuses->{$_}->{String};
                my $jobID = $intraBundle->{Tests}->{$_}->{ValJobID};
                if ($standalone) 
                {
#                    $debug->print(1, "$intraBundle->{Name} $_ Status: ".
#                                     "Percent=$percent, Status=$status\n");
                }
                elsif(defined($jobID))
                {
                    #Sanitize, perhaps a little too strongly, but can't be too careful
                    $status =~ s/[\~\`\#\$\%\^\&\*\(\)\{\}\[\]\\\/\n\t]/_/g;
                    VALDB_setJobStatusString({JobID=>$jobID, 
                                              Status=>(defined($percent)?"[$percent%] "
                                                                       :"").$status});
                }
            }
        }
        case "TestFinished" 
        {
            processFinished($hashRef->{Statuses});
        }
        else
        {
            print "Yet unknown action $action.\n";
            print "Please provide your needs for this action to the vdev team.\n";
            print "We use JIRA at ";
            print "https://jira.qualcomm.com/jira/secure/CreateIssue.jspa?pid=10793&issuetype=3\n";
            print "Please use Component: Validat:FeatureRequest\n";
        }
    }
}

#-----------------------------------------------------------------------------
# Function: readBuildFiles
#   - Read the files.txt file if available in the directory for the driver, else
#       read in all the files as driver files.
#-----------------------------------------------------------------------------
sub readBuildFiles
{
    my ($directory) = @_;
    my $driverFiles;
    my $driverDst;
    my $firmwareFiles;
    my $firmwareDst;
    if(-e "$directory/files.txt")
    {
        open(FILE, '<', "$directory/files.txt");
        my $line;
        my $size;
        while(defined($line=<FILE>))
        {
            if($line=~/\[driver\]/i)
            {
                $size = <FILE>;
                chomp($size);
                $driverDst = <FILE>;
                chomp($driverDst);
                for(my $i=0;$i<$size;$i++)
                {
                    $line = <FILE>;
                    chomp($line);
                    $line=~s/driver//;
                    push @$driverFiles, $line;
                }
            }
            elsif($line=~/\[firmware\]/i)
            {
                $size = <FILE>;
                chomp($size);
                $firmwareDst = <FILE>;
                chomp($firmwareDst);
                for(my $i=0;$i<$size;$i++)
                {
                    $line = <FILE>;
                    chomp($line);
                    $line=~s/driver//;
                    push @$firmwareFiles, $line;
                }
            }
        }
        close(FILE);
    }
    else
    {
        tree("$directory",$driverFiles,0);
    }
    return {DriverFiles     =>$driverFiles,
            DriverDst       =>$driverDst,
            FirmwareFiles   =>$firmwareFiles,
            FirmwareDst     =>$firmwareDst};
}

#-----------------------------------------------------------------------------
# Function: getSAPITests 
#   - Create a new hash reference from the parameter for SAPI to have and possibly
#       modify (which is why we want to create a new one)
#-----------------------------------------------------------------------------
sub getSAPITests
{
    my ($tests) = @_;
    my $sapiTests;
    foreach(keys(%$tests))
    {
        my $info;
        $info->{TestName}   = $_;
        $info->{TestConfig} = $tests->{$_}->{TestConfig};
        $info->{ResultsDir} = $tests->{$_}->{ResultsDir};
        $info->{Ord}        = $tests->{$_}->{Ord};
        push @$sapiTests, $info;
    }

    my @ret = sort {$a->{Ord} <=> $b->{Ord}} @$sapiTests;
    return \@ret;
}
