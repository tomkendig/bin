echo Starting Caterpiller install
rem msiexec /i C:\Users\tkendig.ELECTRIC-CLOUD\Desktop\ElectricCommander.msi /qn EC_INSTALL_TYPE=Agent EC_AGENT_LOGIN="electric-cloud\build"
rem msiexec /i "C:\Documents and Settings\Administrator\Desktop\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Agent EC_AGENT_LOGIN="electric-cloud\build"
rem msiexec /i "C:\Documents and Settings\Administrator\Desktop\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Server EC_SERVER_LOGIN="electric-cloud\build" EC_AGENT_LOGIN="electric-cloud\build" EC_UNC_WORKSPACE="c:/ECworkspace" EC_WORKSPACE_DRIVE="c:/ECworkspace"
rem msiexec /i "Z:\installFiles\windows222\ElectricCommander.msi" /qn EC_INSTALL_TYPE=Server EC_SERVER_LOGIN="electric-cloud\build" EC_AGENT_LOGIN="electric-cloud\build" EC_UNC_WORKSPACE="c:/ECworkspace" EC_WORKSPACE_DRIVE="c:/ECworkspace"
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" login admin changeme
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" import \\main\tkendig\Customers\Cat\CSW_Library.xml
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" import \\main\tkendig\Customers\Cat\CSW_Project.xml
/opt/electriccloud/electriccommander/bin/ectool import ~tkendig/Customers/Cat/CSW_Library.xml
/opt/electriccloud/electriccommander/bin/ectool import ~tkendig/Customers/Cat/CSW_Project.xml
"c:\Program Files\Electric Cloud\ElectricCommander\bin\ectool" createWorkspace \\main\tkendig\Customers\Cat\CSW_Project.xml
rem "c:\Program Files\Electric Cloud\ElectricCommander\bin\ec-perl.bat" z:\bin\CmdrResourceStressTest.pl
