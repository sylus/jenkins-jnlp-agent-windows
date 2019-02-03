# escape=`
FROM microsoft/dotnet-framework:4.7.2-sdk-20181211-windowsservercore-1803

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Chocolatey
ENV chocolateyUseWindowsCompression false
RUN iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'));

# Using jre8 would used less space but the installation failed, failing back to jdk8.
RUN choco install -v -y jdk8 `
                        git `
                        nuget.commandline `
                        docker `
                        docker-compose `
                        azurepowershell `
                        groovy `
                        kubernetes-helm `
                        msdeploy3 `
                        nodejs `
                        octopustools `
                        sqlserver-cmdlineutils

# Add Crystal Report assemblies
COPY Windows/ Windows
RUN choco install -v -y crystalreports2010runtime -version 13.0.23.0

# Add WCF Targets
ADD ["BuildTools/", "C:/Program Files (x86)/Microsoft Visual Studio/2017/BuildTools"]

# Add Microsoft.Web.Administration libraries
RUN Add-WindowsFeature Web-Scripting-Tools

# Remoting versions can be found in Remoting sub-project changelog
# https://github.com/jenkinsci/remoting/blob/master/CHANGELOG.md
ENV AGENT_FILENAME=agent.jar `
    REMOTING_VERSION=3.27

ENV AGENT_HASH_FILENAME=$AGENT_FILENAME.sha1

# Get the Agent from the Jenkins Artifacts Repository
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$env:REMOTING_VERSION/remoting-$env:REMOTING_VERSION.jar" -OutFile $env:AGENT_FILENAME -UseBasicParsing; `
    Invoke-WebRequest "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$env:REMOTING_VERSION/remoting-$env:REMOTING_VERSION.jar.sha1" -OutFile $env:AGENT_HASH_FILENAME -UseBasicParsing; `
    if ((Get-FileHash $env:AGENT_FILENAME -Algorithm SHA1).Hash -ne $(Get-Content $env:AGENT_HASH_FILENAME)) {exit 1};

# Copy launch script used by entry point
COPY "agent.ps1" ".\agent.ps1"

ENTRYPOINT .\agent.ps1

# Find Jenkins LTS version https://jenkins.io/changelog-stable/
LABEL application-min-version.jenkins="2.85.0" `
      application-min-version.jenkins-lts="2.89.2" `
      application-version.jenkins-remoting="3.15" `
      application-version.windows="1803" `
      application-version.jdk="1.8" `
      application-version.git="2.15.1.2"
