#Create project and Acl entry as admin
#ectool logout
#ectool login admin changeme
ectool createProject Test
#first the pass import test
ectool deleteProcedure Test importTest
ectool import /tmp/importTestF.xml --path /projects/Test/procedures/importTest
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName
ectool deleteStep Test importTest clearjob
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName #expect to show error
ectool import /tmp/importTestF.xml --path /projects/Test/procedures/importTest --force 1
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName #expect to return step - unexpected error is show!
#second the fail import test
ectool deleteProcedure Test importTest
ectool import /tmp/importTestP.xml --path /projects/Test/procedures/importTest
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName
ectool deleteStep Test importTest clearjob
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName #expect to show error
ectool import /tmp/importTestP.xml --path /projects/Test/procedures/importTest --force 1
ectool getProperty /projects/Test/procedures/importTest/steps/clearjob/stepName #expect to return step - unexpected error is show!
#ectool logout
