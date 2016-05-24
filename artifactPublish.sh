#/bin/sh
ectool login admin changeme
ectool publishArtifactVersion --artifactName cmdr:log --fromDirectory /opt/electriccloud/electriccommander/logs --includePatterns install*.log --version 00.7.4-tek-02
ectool retrieveArtifactVersions --artifactName cmdr:log --cacheDirectory /tmp/tek --versionRange "(,1.8)"
ls /tmp/tek/cmdr/log/00.7.4-tek-02
ectool publishArtifactVersion --artifactName cmdr:log --fromDirectory /opt/electriccloud/electriccommander/logs --includePatterns install*.log --version 1.7.4-tek-02
ectool retrieveArtifactVersions --artifactName cmdr:log --cacheDirectory /tmp/tek --versionRange "(,1.8)"
ls /tmp/tek/cmdr/log/1.7.4-tek-02
ectool --server chronic3 retrieveArtifactVersions --artifactName "com.electriccloud:ECSCM-Perforce" --cacheDirectory "."
ectool --server chronic3 retrieveArtifactVersions --artifactName "com.electriccloud:ECSCM-Mercurial" --cacheDirectory "."
ectool --server chronic3 retrieveArtifactVersions --artifactName "com.electriccloud:EC-vCloudDirector" --cacheDirectory "."