pipeline {
    agent any

    environment {
        IMAGE_NAME = 'yerinnn/neuroplan-ci-test'
    }

    stages {
        stage('Environment Check') {
            steps {
                sh '''
                    echo "===== Java ====="
                    java -version

                    echo "===== Maven ====="
                    mvn -version

                    echo "===== Node.js ====="
                    node --version

                    echo "===== npm ====="
                    npm --version

                    echo "===== Git ====="
                    git --version

                    echo "===== Docker ====="
                    docker --version
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                      -t ${IMAGE_NAME}:latest \
                      .
                '''
            }
        }

        stage('Docker Hub Login & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | \
                        docker login -u "$DOCKERHUB_USER" --password-stdin

                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${IMAGE_NAME}:latest

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Docker image build and push succeeded.'
        }

        failure {
            echo 'CI pipeline failed.'
        }
    }
}
