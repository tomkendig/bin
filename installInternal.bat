echo Starting internalInstall
rem echo add electric-cloud domain build account: users/add/"build","ELECTRIC-CLOUD"/Other
echo add local build account: users/Advanced/Users/"build",enter password, select never expires, advanced to added to administrator group
echo log into the network build account to establish the directory
echo run this bat file from the build accout (it will not work from the Adminstrator account)
net use z: \\main\tkendig
mkdir c:\ECworkspace
rem msiexec /i C:\Users\tkendig.ELECTRIC-CLOUD\Desktop\ElectricCommander.msi /qn EC_INSTALL_TYPE=Agent EC_AGENT_LOGIN="electric-cloud\build"
rem msiexec /i "C:\Documents and Settings\Administrator\Desktop\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Agent EC_AGENT_LOGIN="electric-cloud\build"
rem msiexec /i "Z:\installFiles\windows224\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Server EC_SERVER_LOGIN="electric-cloud\build" EC_AGENT_LOGIN="electric-cloud\build" EC_HOST_NAME="cirrus7.electric-cloud.com" EC_UNC_WORKSPACE="c:/ECworkspace" EC_WORKSPACE_DRIVE="c:/ECworkspace" EC_SERVER_PASSWORD="Mbimp,vm" EC_AGENT_PASSWORD="Mbimp,vm"
rem msiexec /i "Z:\installFiles\windows301\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Tools EC_AGENT_LOGIN="electric-cloud\qa" EC_HOST_NAME="sup-wxp-32-cmdr.electric-cloud.com" EC_UNC_WORKSPACE="c:/ECworkspace" EC_WORKSPACE_DRIVE="c:/ECworkspace" EC_AGENT_PASSWORD="qa"
msiexec /i "Z:\installFiles\windows301\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Server EC_SERVER_LOGIN="electric-cloud\build" EC_AGENT_LOGIN="electric-cloud\build" EC_HOST_NAME="cirrus6.electric-cloud.com" EC_UNC_WORKSPACE="c:/ECworkspace" EC_WORKSPACE_DRIVE="c:/ECworkspace" EC_SERVER_PASSWORD="Mbimp,vm" EC_AGENT_PASSWORD="Mbimp,vm"
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" login admin changeme
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" importLicenseData z:\license\electriccloud-cmdr.txt
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ec-perl" z:\bin\CmdrResourceStressTest.pl
