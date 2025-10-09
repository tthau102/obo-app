pipeline {
    agent any
    
    environment {
        // Harbor registry
        HARBOR_REGISTRY = 'harbor.server.thweb.click'
        HARBOR_PROJECT = 'tthau'
        IMAGE_NAME = 'obo-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
        
        // Credentials
        HARBOR_CREDS = credentials('jenkins-harbor-credentials')
        GITLAB_CREDS = 'jenkins-gitlab-credentials'
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    checkout scmGit(
                        branches: [[name: '*/main']], 
                        extensions: [], 
                        userRemoteConfigs: [[
                            credentialsId: "${GITLAB_CREDS}", 
                            url: 'https://gitlab.server.thweb.click/tthau/obo-app.git'
                        ]]
                    )
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker image: ${FULL_IMAGE_NAME} ==="
                    app = docker.build("${FULL_IMAGE_NAME}")
                }
            }
        }
        
        stage('Push to Harbor') {
            steps {
                script {
                    echo "=== Pushing to Harbor registry ==="
                    docker.withRegistry("https://${HARBOR_REGISTRY}", 'jenkins-harbor-credentials') {
                        app.push()
                        app.push('latest')  // Tag latest
                    }
                }
            }
        }
        
        // stage('Deploy to K8s') {
        //     steps {
        //         script {
        //             echo "=== Deploying to Kubernetes ==="
        //             sh """
        //                 kubectl set image deployment/obo-app \
        //                     obo-app=${FULL_IMAGE_NAME} \
        //                     -n obo-ns \
        //                     --kubeconfig=/var/lib/jenkins/.kube/config
        //             """
        //         }
        //     }
        // }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Image: ${env.FULL_IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed. Check logs above."
        }
        always {
            script {
                // Cleanup local images để tiết kiệm disk
                sh "docker rmi ${env.FULL_IMAGE_NAME} || true"
            }
        }
    }
}