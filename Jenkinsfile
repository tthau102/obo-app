// git repository info
def gitRepository = 'https://github.com/trantrunghau0102/Obo-SpringBoot-Java.git'
def gitBranch = 'master'

// gitlab credentials
def gitlabCredential = 'jenkin_github'	

//docker hub credentials
def harborCredential = "jenkins-harbor-credentials"
def IMAGE_NAME = "harbor.server.thweb.click/tthau/obo-app"
def IMAGE_TAG = "${BUILD_NUMBER}"

def CICD_IP = "10.33.10.20"

pipeline {
	agent any
			
    stages {
        stage("Checkout SCM") {
            steps {
                script {
                    checkout scmGit(branches: [[name: '*/' + gitBranch]], extensions: [], userRemoteConfigs: [[credentialsId: gitlabCredential, url: gitRepository]])
                }
            }
        }

		stage('Build Docker Image') {
			steps {
				script {
                    app = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
				}
			}
		}

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://harbor.server.thweb.click', ${harborCredential}) {
                    app.push()
                    }
                }
            }
        }
    }
}	
