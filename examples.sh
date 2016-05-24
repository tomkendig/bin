#Create project and Acl entry as admin
ectool logout
ectool login admin changeme
ectool createProject checkEveryone
ectool createAclEntry group everyone --projectName checkEveryone --modifyPrivilege allow
ectool logout
#The setProperty will fail if the group everyone in lower case is not recignized as the same as Everyone
ectool login qa qa
ectool getProperty /projects/A/procedures/A1/procedureName #show path works
ectool setProperty /projects/A/procedures/A1/customType '$[/plugins/RunProcedureExample]/CustomRun' #set the customType so plugin is called before the step is executed
ectool getProperty /projects/A/procedures/A1/customType #check the property value
ectool getProperty /projects/A/workflowDefinitions/X/workflowDefinitionName #show the path works
ectool setProperty /projects/A/workflowDefinitions/X/stateDefinitions/Aworkflow/transitionDefinitions/Etarget/customType '$[/plugins/RunProcedureExample]/CustomRun' # set the customType in the definition object
ectool getProperty /projects/A/workflowDefinitions/X/stateDefinitions/Aworkflow/transitionDefinitions/Etarget/transitionDefinitionName # show the path works
ectool getProperty /projects/A/workflowDefinitions/X/stateDefinitions/Aworkflow/transitionDefinitions/Etarget/customType # check the property value
ectool setProperty /myWorkflow/states/Aworkflow/transitions/Etarget/customType '$[/plugins/RunProcedureExample]/CustomRun' # set the customType in the runtime object
ectool logout
./ElectricCommander-3.7.2.35381 --mode silent --parallelInstallName _360 --installAgent --installDirectory "/opt/360/electriccloud/electriccommander/" --dataDirectory "/opt/360/electriccloud/electriccommander/" --agentPort 7814 --unixAgentUser qa --unixAgentGroup qa
for zipfile in `\ls *.zip`; do unzip $zipfile; done #unzip all the compressed files in a directory
cat tom.xml | sed '/<resourceDisabled>0</ s/>0</>1</g' > tom.txt # disable all resources in a ectool export
ectool getProperty /emailConfigs/iris/createTime # retreive a property that can be easily ACL protected
cat /proc/meminfo
sed -i 's/tom/Tom/g' tom.txt # change txt in a file in place
perl -pi'*.bak' -e 's/Tom/tom/g' tom.txt # change txt in a file in place
cat /net/services/licenses/ftp.csv | sed 's/[\r\n]//g' | sed  's/touch.*/&,terminated/' | less
sed 's/^..\/..\/.... ..\:..\:...M - //g' installer.log > tom.log
