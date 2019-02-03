# Jenkinsfile

The following is largely a fully complete `Jenkinsfile` tailored to work with Windows nodes inside a Kubernetes cluster.

Simply replace the values below with your own configuration.

> Note: We makes use of the Kubernetes plugin where you can specify the specific cluster you wish to run CI tests against.

```sh
def label = "jnlp-win-${UUID.randomUUID().toString()}"

podTemplate(
  cloud: '<k8s-cluster>',
  serviceAccount: 'jenkins-jenkins
  label: label,
  yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    ci: windows-vs2017
spec:
  containers:
    - name: jnlp
      image: <docker-registry>/jenkins/jenkins-ext:jnlp-windows
      env:
        - name: JENKINS_URL
          value: 'https://<domain>'
        - name: DOCKER_HOST
          value: 'tcp://<ipaddress>:2375'
      tty: true
      working: 'C:\\workspace\\'
  tolerations:
    - effect: NoSchedule
      key: os
      operator: Equal
      value: windows
  nodeSelector:
    agentpool: ciwinpool1
"""
) {
    node (label) {
      // Update the gitlab status to pending
      // https://jenkins.io/doc/pipeline/steps/gitlab-plugin
      updateGitlabCommitStatus name: 'build', state: 'pending'

      bat 'powershell.exe mkdir C:\\repo'
        dir('C:\\repo\\') {
            checkout scm

            withCredentials([usernamePassword(credentialsId: 'docker-pull', passwordVariable: 'pass', usernameVariable: 'user')]) {
                bat "docker login -u ${user} -p ${pass} <docker-registry>"
                bat "docker build . -t <docker-registry>/<repo-name> --no-cache"
                bat "docker push <docker-registry>/<repo-name>"
            }
        }
      bat 'powershell.exe remove-item C:\\repo -recurse -force'

      // Update the gitlab status to success
      updateGitlabCommitStatus name: 'build', state: 'success'
    }
}
```
