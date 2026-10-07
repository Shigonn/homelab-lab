pipeline {
  agent any
  stages {
    stage('YAML lint') {
      steps {
        sh 'yamllint -d relaxed ansible'
      }
    }
    stage('Ansible syntax check') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook --syntax-check k8s-prep.yml node-exporter.yml monitoring.yml grafana.yml jenkins.yml jenkins-tools.yml'
        }
      }
    }
  }
}
