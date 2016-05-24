grep cmdr /var/log/ftp.log | grep -v .txt | grep -v .pdf | grep -v "192.168.2.12" | grep cmdr-3.2.0 | grep -v beta | awk '{print $6}' | awk -F"@" '{print $1}' | awk -F"(" '{print $2}' | sort -u #who downloaded a release?
grep cmdr /var/log/ftp.log | grep -v .txt | grep -v .pdf | grep -v Can | grep cmdr-3.2.0 | grep -v beta | awk '{print $6 $8}' | awk -F"/" '{print $1 $5}' | sort -u #a smarter look for release downloads
cat badReportUrl.txt sed /\/projectDetails\?projectName\=/projectDetails\/projects\//
eceditors --username admin --password changeme --type step --project Testing --install /opt/electriccloud/electriccommander/src/customEditors/step/accurevPopNonwkspc.xml
grep scheduleSteps.perform */*.xml | egrep -v "\|"
grep setProperty.perform */*.xml | egrep -v "\|"
zgrep 'cpuMonitor' -h *.zip | grep DEBUG | awk '{print $1 " " $14}' # > /tmp/cpuMonitor.txt; echo 'set term gif'; echo 'set output "cpuMonitor.gif" '; echo 'set timefmt "%Y-%m-$dT%H:%M:%S.%S"'; echo 'set xdata time'; echo 'plot "/tmp/cpuMonitor.txt" using 2:1'; | gnuplot -p

cat cpuMonitor.log | awk -F":" '{print $2 ":" $3 ":" $4}'

ectool setProperty tom --value "$DOLLAR[/javascript Math.floor(Math.random()*2) > 0.0]" --jobId 1
 ectool setProperty tom --value "$DOLLAR[/javascript myJob.jobId]" --jobId 1
ectool getProperty tom  --jobId 1

setProperty tom --value "$DOLLAR[/javascript myWorkflow.workflowName]" --workflowName workflow_1_201102011936 --projectName A --stateName Ystate
ectool getProperty tom --w201102011936 --projectName A --stateName Ystate

DOLLAR="$"
DOUBLE='"'
ectool setProperty "PlacesService Pass Rate" --value "75" --workflowName workflow_1_201102011936 --projectName A --stateName Ystate
ectool setProperty testJavascript --value "$DOLLAR[/javascript myState[${DOUBLE}PlacesService Pass Rate$DOUBLE]>77]" --workflowName workflow_1_201102011936 --projectName A --stateName Ystate
ectool getProperty testJavascript --workflowName workflow_1_201102011936 --projectName A --stateName Ystate
ectool setProperty testJavascript --value "$DOLLAR[/javascript if(myState[${DOUBLE}PlacesService Pass Rate$DOUBLE]>77) true; else false;]" --workflowName workflow_1_201102011936 --projectName A --stateName Ystate

new
