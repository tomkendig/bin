/net/f2home/tkendig/bin/log-keywords.pl commander*.log* > log-keywords.txt & # look for default errors this script catches
echo '################################ server version info from "ElectricCommander Server|_stop_runner|_start_runner|LicenseExceeded|license limit"'
zegrep "ElectricCommander\ Server|LicenseExceeded|license\ limit|Upgrading\ ElectricCommander\ schema|upgradeData.perform" commander*.log* | sort -u #server version info on start or server starts
echo '################################ what is the server OS and version info"'
zegrep "WRAPPER_|\.version=|os\." commander*.log* | sort -u #what is the OS and version info
echo '################################ search for specific errors, execeptions and server start "OutOfMemory|SQLException|AppStart"'
zegrep -A 3 "Memory threshold exceeded|OutOfMemory|SQLException|SocketException|AppStart" commander*.log* #when Java fails or when Sql fails or when server starts
echo '################################ search for java errors and hanging steps "java.*Exception|No contex"'
zegrep -A 3 "java.*Exception|No context" commander*.log* #when Java fails and hanging steps
echo '################################ search for Exhausted database retries and memory problems'
zegrep "Exhausted database retries|low-memory event|\| scheduleSteps.perform  |\| messageProcessor.lockDelay |\| messageTrigger.perform " commander*.log* #when there are database or memory problems
echo '################################ search for ERRORs in the logs'
zegrep "\| ERROR \|" commander*.log* #when there are ERRORs in the logs
echo '################################ search for WARNs in the logs'
zegrep "\| WARN \|" commander*.log* #when there are WARNs in the logs
echo '################################ email Notifier failed'
zegrep -B 3 "Send email failed" commander*.log* #email Notifier failed
echo '################################ server version info from "_stop_runner|_start_runner"'
zegrep "_stop_runner|_start_runner|upgradeData.perform" commander*.log* | sort -u #server version info on start or server start
echo '################################ server version info from "_stop_runner|_start_runner" and Too many open files'
zegrep "ORA-|Too many open files|SQLIntegrityConstraintViolationException" commander*.log* | sort -u #oracle errors, Too many open files
echo '################################ when did an agent time out AGENT_TIMEOUT'
zegrep "AGENT_TIMEOUT|<jobId>|<details>|<errorMessage>|agent timed out" commander*.log* | grep -A 2 AGENT_TIMEOUT
echo '################################ any AGENT_IO_CONNECTION_RESETS'
zegrep "AGENT_IO_CONNECTION_RESET|<jobId>|<details>|<errorMessage>" commander*.log* | grep -A 2 AGENT_IO_CONNECTION_RESET
echo '################################ any "Connection with agent was closed"'
zgrep "Connection with agent was closed" commander*.log* | grep "on resource"  | awk -F"|" '{print $6 "[" $1}' | awk -F"[" '{print $3 "=" $4}' | awk -F"=" '{print $3 "," $8}' | awk -F"," '{print $1 "  " $3}' | sort -u
echo '################################ count the number of agents'
zgrep -h 'agentResponse req="ping-' commander*.log* | sort | uniq | sed s/'<agentResponse req="ping-'//g | awk -F"-" '{print $2}' | sort | uniq | wc # count the number of agents
echo '################################ find the version number of the agents as recorded in the server log'
zgrep -h "</version>" commander*.log* | awk -F" " '{print $1}' | sort | uniq #find the versions of agents and server
echo '################################ count the users over what time period'
for whichlog in `\ls commander*.log*`; do head -1 $whichlog | awk -F" " '{print $1}'; echo -n "login users "; grep -A 1 "<login>" $whichlog | grep "<userName>" | sort | uniq | wc -l | awk '{printf $1}'; echo -n " Credential logins "; grep -B 2 "</runCommand>" $whichlog | grep "<userName>" | sort | uniq | wc -l; tail -1000 $whichlog | egrep "2009|2010" | tail -1 | awk -F" " '{print $1}'; done #count users over what time period
echo '################################ show long elapsed times catching extermely long database accesses over 1 day'
zegrep "elapsed\ time.*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]|elapsed\ time.*[0-9][0-9][0-9],[0-9][0-9][0-9],[0-9][0-9][0-9]" commander*.log* #long elapsed times over 1 day
echo '################################ show long elapsed times catching extermely long database accesses over 2 hours'
zegrep "elapsed\ time.*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]|elapsed\ time.*[0-9][0-9],[0-9][0-9][0-9],[0-9][0-9][0-9]" commander*.log* #long elapsed times over 2 hours
echo '################################ show long elapsed times catching extermely long database accesses over 16 minutes'
zegrep "elapsed\ time.*[0-9][0-9][0-9][0-9][0-9][0-9][0-9]|elapsed\ time.*[0-9],[0-9][0-9][0-9],[0-9][0-9][0-9]" commander*.log* #long elapsed times over 16 minutes
echo '################################ show long elapsed times catching extermely long database accesses over 99 seconds'
zegrep "elapsed\ time.*[0-9][0-9][0-9][0-9][0-9][0-9]|elapsed\ time.*[0-9][0-9][0-9],[0-9][0-9][0-9]" commander*.log* #long elapsed times over 99 seconds
echo '################################ show long elapsed times catching long database accesses over 9 seconds'
zegrep "elapsed\ time.*[0-9][0-9][0-9][0-9][0-9]|elapsed\ time.*[0-9][0-9],[0-9][0-9][0-9]" commander*.log* #long elapsed times over 9 seconds
echo '################################ watch heap'
#zegrep "Old Gen" commander*.log* | grep usage #watch heap
zegrep "ExportOperation|Memory threshold exceeded|ConcurrentMarkSweep|Old Gen.*usage" commander*.log* #The first number in ConcurrentMarkSweep is count, the second the number of miliseconds. When the seconds per count goes over say 5sec is when the not good garbage collection time starts. on Old Gen show the current and top heap allocation.
echo '################################ search for exceptions, caught and placed in the log'
zegrep ".exception|Exception|\-connector\.|Full\ thread\ dump" commander*.log* | grep -v "does not exist" | grep -v "Session has expired" | grep -v OperationException | grep -v AgentTimeoutException | grep -v ConnectException #search for exceptions
#zgrep onError commander*.log* | grep -v Cancel #look for agent connection problems
#zegrep -B 5 "procedureName>Wrapper" *.zip | grep XmlR #find the incoming XML requests from the Web Server
#
echo '################################ agent versions from agent log'
zegrep -h "</version|started\ with" agent*.*log* | sort | uniq #find the commander agent versions in agent log file
echo '################################ what is the agent OS and version info"'
zegrep "OS=|PATH=" agent.*log* | sort -u #what is the OS and version info
echo '################################ show socket communications exceptions'
zegrep "system\ error\ message|unexpected\ exception" agent*.*log* | grep -v "operation completed successfully" | grep -v Success #find socket communications exceptions
echo '################################ show agent errors'
zegrep -A 5 "INVALID_MESSAGE" agent*.*log* #when agent errors
echo '################################ show when agent fails or has a problem'
zegrep -B 5 "Reporting error code|Unexpected|Encountered" agent*.*log* #when agent has a problem
echo '################################ diagnostics sanity check'
zegrep "scheduleSteps.perform|messageProcessor.lockDelay|messageTrigger.perform" *iag*.*log* #diagnostics sanity check
#grep -h pingAgent.perform */* | grep -v "|" | grep -v "                                       "; #look at the diagnostics for stats
#echo '################################	check for too many IP (Commander servers) talking to agent'
#zegrep -B 3 "pingToken=|About\ to\ send\ request\ on\ connection"  agent*.*log* | egrep "Received\ the\ following\ post\ data\ from|About\ to\ send\ request\ on\ connection" | awk -F"|" '{print $4}' | sed s/'About to send request on connection '//g | sed s/'Received the following post data from '//g | sort -u
#zegrep "post data|ping message" agent*.*log* > ping.txt #generate file where pings from commander server should line up
echo '################################ pages that take more than 16 seconds to server'
#zegrep "\ 200\ .\ .*[0-9][0-9][0-9][0-9][0-9][0-9][0-9]" access*.log #long access times over 16 seconds
#zegrep "\ 500\ .\ .*[0-9][0-9][0-9][0-9][0-9][0-9][0-9]" access*.log #long access times over 16 seconds
zegrep "\ *[0-9]{9}\ [\+\-]" access*.log* #long access times over 16 minutes
zegrep "\ *[0-9]{8}\ [\+\-]" access*.log* #long access times over 1.6 minutes
zegrep "\ *[0-9]{7}\ [\+\-]" access*.log* #long access times over 10 seconds
echo '################################ Too many open files as shown in service.log'
zegrep "Too many open files" service.log* #Too many open files as show in service.log
