#/bin/sh
(cd ~tkendig/cgiScripts/helloWorld; rm helloWorld.jar; zip -r helloWorld.jar .; cp -p helloWorld.jar /tmp)
(cd ~tkendig/cgiScripts/viewJobs; rm viewJobs.jar; zip -r viewJobs.jar .; cp -p viewJobs.jar /tmp)
ectool login admin changeme
ectool uninstallPlugin "Hello World-1.0"
ectool installPlugin /tmp/helloWorld.jar
ectool promotePlugin "Hello World-1.0"
ectool uninstallPlugin "ViewJobs-1.0"
ectool installPlugin /tmp/viewJobs.jar
ectool promotePlugin "ViewJobs-1.0"
#https://192.168.24.188/commander/plugins/ViewJobs-1.0/cgi-bin/viewJobs.cgi
ectool getPlugins | grep -i manager
ectool uninstallPlugin EC-PluginManager-1.1.2.39214
ectool installPlugin ~/pluginsCurrent/EC-PluginManager.jar
ectool promotePlugin EC-PluginManager-1.1.1.34201
#starting from scratch, get the Plugin Manager working
ectool deletePlugin EC-PluginManager
ectool getPlugins | grep PluginManager
ectool installPlugin /opt/electriccloud/electriccommander/src/plugins/EC-PluginManager.jar 
ectool promotePlugin EC-PluginManager-1.2.1.48734
