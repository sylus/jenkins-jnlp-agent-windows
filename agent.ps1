# Agent Entrypoint

do {
  Write-Host "waiting for connection..."
  sleep 5
} until(Test-NetConnection $env:JENKINS_URL -Port 80 | ? { $_.TcpTestSucceeded } )

. java -cp .\agent.jar hudson.remoting.jnlp.Main -url $env:JENKINS_URL -tunnel $env:JENKINS_TUNNEL $env:JENKINS_SECRET $env:JENKINS_AGENT_NAME
