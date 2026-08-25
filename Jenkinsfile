pipeline {
    agent any

    environment {
        FRONTEND_IMAGE = 'yerinnn/neuroplan-frontend'
        BACKEND_IMAGE  = 'yerinnn/neuroplan-backend'
    }

    stages {
        stage('Environment Check') {
            steps {
                sh '''
                    echo "===== Java ====="
                    java -version

                    echo "===== Maven ====="
                    mvn -version

                    echo "===== Git ====="
                    git --version

                    echo "===== Docker ====="
                    docker --version
                '''
            }
        }

        stage('Backend Maven Build') {
            steps {
                dir('backend') {
                    sh '''
                        mvn clean package -DskipTests
                    '''
                }
            }
        }

        stage('Frontend Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} \
                      -t ${FRONTEND_IMAGE}:latest \
                      ./frontend
                '''
            }
        }

        stage('Backend Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${BACKEND_IMAGE}:${BUILD_NUMBER} \
                      -t ${BACKEND_IMAGE}:latest \
                      ./backend
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

                        echo "===== Push Frontend ====="
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest

                        echo "===== Push Backend ====="
                        docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${BACKEND_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Frontend and Backend image build/push succeeded.'
        }

        failure {
            echo 'Frontend/Backend CI pipeline failed.'
        }
    }
}
