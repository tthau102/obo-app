pipeline {
    agent any

    environment {
        // Harbor registry configuration
        HARBOR_REGISTRY = 'harbor.server.thweb.click'
        HARBOR_PROJECT = 'tthau'
        IMAGE_NAME = 'obo-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"

        // Kubernetes configuration
        K8S_NAMESPACE = 'obo-ns'
        K8S_DEPLOYMENT = 'obo-app'

        // Credentials
        HARBOR_CREDS = credentials('jenkins-harbor-credentials')
        GITLAB_CREDS = 'jenkins-gitlab-credentials'
        K8S_CREDS = 'jenkins-k8s-config'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    echo "=== Checking out source code from GitLab ==="
                    checkout scmGit(
                        branches: [[name: '*/main']],
                        extensions: [],
                        userRemoteConfigs: [[
                            credentialsId: "${GITLAB_CREDS}",
                            url: 'https://gitlab.server.thweb.click/tthau/obo-app.git'
                        ]]
                    )

                    // Get commit info for build metadata
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_MSG = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    echo "Commit: ${env.GIT_COMMIT_SHORT} - ${env.GIT_COMMIT_MSG}"
                }
            }
        }

        stage('Maven Build') {
            steps {
                script {
                    echo "=== Building application with Maven ==="
                    sh '''
                        ./mvnw clean package -DskipTests
                        echo "Build artifact: target/obo-stadium-0.0.1-SNAPSHOT.jar"
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "=== Running unit and integration tests ==="
                    sh './mvnw test'
                }
            }
            post {
                always {
                    // Publish test results
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker image: ${FULL_IMAGE_NAME} ==="
                    echo "Using multi-stage Dockerfile for optimized image"

                    app = docker.build(
                        "${FULL_IMAGE_NAME}",
                        "--build-arg BUILD_NUMBER=${BUILD_NUMBER} " +
                        "--build-arg GIT_COMMIT=${env.GIT_COMMIT_SHORT} " +
                        "--no-cache ."
                    )

                    echo "Image built successfully: ${FULL_IMAGE_NAME}"
                }
            }
        }

        stage('Push to Harbor') {
            steps {
                script {
                    echo "=== Pushing to Harbor registry: ${HARBOR_REGISTRY} ==="
                    docker.withRegistry("https://${HARBOR_REGISTRY}", 'jenkins-harbor-credentials') {
                        // Push with build number tag
                        app.push("${IMAGE_TAG}")
                        echo "✅ Pushed: ${FULL_IMAGE_NAME}"

                        // Push with latest tag
                        app.push('latest')
                        echo "✅ Pushed: ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest"

                        // Push with commit hash tag for traceability
                        app.push("${env.GIT_COMMIT_SHORT}")
                        echo "✅ Pushed: ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${env.GIT_COMMIT_SHORT}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "=== Deploying to Kubernetes cluster ==="
                    echo "Namespace: ${K8S_NAMESPACE}"
                    echo "Deployment: ${K8S_DEPLOYMENT}"
                    echo "Image: ${FULL_IMAGE_NAME}"

                    withKubeConfig([credentialsId: "${K8S_CREDS}"]) {
                        // Update deployment with new image
                        sh """
                            kubectl set image deployment/${K8S_DEPLOYMENT} \
                                obo-app=${FULL_IMAGE_NAME} \
                                -n ${K8S_NAMESPACE} \
                                --record

                            echo "Waiting for rollout to complete..."
                            kubectl rollout status deployment/${K8S_DEPLOYMENT} \
                                -n ${K8S_NAMESPACE} \
                                --timeout=5m
                        """
                    }

                    echo "✅ Deployment successful!"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "=== Verifying deployment health ==="

                    withKubeConfig([credentialsId: "${K8S_CREDS}"]) {
                        // Check pod status
                        sh """
                            echo "--- Checking pod status ---"
                            kubectl get pods -n ${K8S_NAMESPACE} -l app=obo-app

                            echo ""
                            echo "--- Checking deployment status ---"
                            kubectl get deployment ${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}

                            echo ""
                            echo "--- Recent events ---"
                            kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -10
                        """

                        // Get pod name and check health endpoint
                        def podName = sh(
                            script: "kubectl get pods -n ${K8S_NAMESPACE} -l app=obo-app -o jsonpath='{.items[0].metadata.name}'",
                            returnStdout: true
                        ).trim()

                        echo "Testing health endpoint on pod: ${podName}"
                        sh """
                            kubectl exec ${podName} -n ${K8S_NAMESPACE} -- \
                                curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/actuator/health || echo "Health check returned: \$?"
                        """
                    }

                    echo "✅ Verification complete!"
                }
            }
        }
    }

    post {
        success {
            script {
                echo "════════════════════════════════════════════════"
                echo "✅ Pipeline completed successfully!"
                echo "════════════════════════════════════════════════"
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                echo "Image: ${env.FULL_IMAGE_NAME}"
                echo "Tags: ${IMAGE_TAG}, latest, ${env.GIT_COMMIT_SHORT}"
                echo "Deployed to: ${K8S_NAMESPACE}/${K8S_DEPLOYMENT}"
                echo "════════════════════════════════════════════════"
            }
        }
        failure {
            script {
                echo "════════════════════════════════════════════════"
                echo "❌ Pipeline failed!"
                echo "════════════════════════════════════════════════"
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Stage: ${env.STAGE_NAME}"
                echo "Check logs above for details"
                echo "════════════════════════════════════════════════"
            }
        }
        always {
            script {
                // Cleanup local images to save disk space
                echo "Cleaning up local Docker images..."
                sh """
                    docker rmi ${env.FULL_IMAGE_NAME} || true
                    docker rmi ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest || true
                    docker rmi ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${env.GIT_COMMIT_SHORT} || true
                """

                // Archive build artifacts
                archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
            }
        }
    }
}
