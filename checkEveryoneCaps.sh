#Create project and Acl entry as admin
ectool logout
ectool login admin changeme
ectool createProject checkEveryone
ectool createAclEntry group everyone --projectName checkEveryone --modifyPrivilege allow
ectool logout
#The setProperty will fail if the group everyone in lower case is not recignized as the same as Everyone
ectool login qa qa
ectool setProperty /projects/checkEveryone/Check Y
ectool getProperty /projects/checkEveryone/Check
ectool deleteProperty /projects/checkEveryone/Check
ectool logout
#
ectool login admin changeme
ectool deleteAclEntry group everyone --projectName checkEveryone
ectool deleteProject checkEveryone
ectool logout
