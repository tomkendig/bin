echo Commander partial list of Intrinsic properties for version `ectool --version | head -1 | awk '{print $6}'`
echo "***Intrinsic static Properties"
echo Intrinsic Procedure
ectool getProcedure "Electric Cloud" runSentry | grep "</" | awk -F">" '{print $1}' | grep -v "</" | awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Project
ectool getProject "Electric Cloud"  | grep "</" | awk -F">" '{print $1}' | grep -v "</" |  awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Resource
ectool getResource local | grep "</" | awk -F">" '{print $1}' | grep -v "</" |  awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Step
ectool getStep "Electric Cloud" runSentry Setup | grep "</" | awk -F">" '{print $1}' | grep -v "</" |  awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic User
ectool getUser admin | grep "</" | awk -F">" '{print $1}' | grep -v "</" |  awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Workspace
ectool getWorkspace default | grep "</" | awk -F">" '{print $1}' | grep -v "</" |  awk -F"<" '{print "- ",$2}' | sort -u
echo 
echo -n "***Intrinsic runtime Properties (for JobId "
lastJob=`ectool getJobs | grep jobId | tail -1 |  awk -F">" '{print $2}' | awk -F"<" '{print $1}'`
echo -n $lastJob ", StepID "
lastJobStep=`ectool getJobDetails $lastJob | grep jobStepId | tail -1 |  awk -F">" '{print $2}' | awk -F"<" '{print $1}'`
echo $lastJobStep ")"
echo Intrinsic Job Info
ectool getJobInfo $lastJob | grep "</" | awk -F">" '{print $1}' | grep -v "</" | awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Job Details
ectool getJobDetails $lastJob | grep "</" | awk -F">" '{print $1}' | grep -v "</" | awk -F"<" '{print "- ",$2}' | sort -u
echo Intrinsic Job Step Details
ectool getJobStepDetails $lastJobStep | grep "</" | awk -F">" '{print $1}' | grep -v "</" | awk -F"<" '{print "- ",$2}' | sort -u
ectool export jobs$lastJobStep.xml --path /jobs/$lastJobStep
ectool export projectsElectricCloud.xml --path "/projects/Electric Cloud"
ectool export procedureRunReports.xml --path "/projects/Electric Cloud/procedures/runReports"
ectool export resourcesLocal.xml --path /resources/local
ectool export usersAdmin.xml --path /users/admin
ectool export workspaceDefault.xml --path /workspaces/default
ectool getProperty /jobs/7875/actualParameters/product #give actualParameters, find the value by property reference
ectool getActualParameter MaxStepDuration  --jobStepId 79116 #given a jobStepID, find the value of a parameter
