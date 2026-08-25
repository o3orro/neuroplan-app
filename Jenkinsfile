pipeline {
    agent any

    environment {
        // Docker Hub Images
        FRONTEND_IMAGE = 'yerinnn/neuroplan-frontend'
        BACKEND_IMAGE  = 'yerinnn/neuroplan-backend'

        // GitOps Repository
        GITOPS_REPO   = 'git@github.com:o3orro/neuroplan-gitops.git'
        GITOPS_BRANCH = 'main'

        // GitOps Manifests
        FRONTEND_MANIFEST = 'manifests/frontend-deployment.yaml'
        BACKEND_MANIFEST  = 'manifests/backend-deployment.yaml'
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
                        set -e

                        echo "$DOCKERHUB_TOKEN" | \
                        docker login \
                          -u "$DOCKERHUB_USER" \
                          --password-stdin

                        echo "===== Push Frontend ====="

                        docker push \
                          ${FRONTEND_IMAGE}:${BUILD_NUMBER}

                        docker push \
                          ${FRONTEND_IMAGE}:latest


                        echo "===== Push Backend ====="

                        docker push \
                          ${BACKEND_IMAGE}:${BUILD_NUMBER}

                        docker push \
                          ${BACKEND_IMAGE}:latest


                        docker logout
                    '''
                }
            }
        }


        stage('Update GitOps') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'gitops-ssh-credentials',
                        keyFileVariable: 'GITOPS_SSH_KEY',
                        usernameVariable: 'GITOPS_SSH_USER'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "===== Prepare GitHub SSH ====="

                        mkdir -p "$HOME/.ssh"
                        chmod 700 "$HOME/.ssh"

                        export GIT_SSH_COMMAND="ssh \
                          -i $GITOPS_SSH_KEY \
                          -o IdentitiesOnly=yes \
                          -o StrictHostKeyChecking=accept-new"


                        echo "===== Clone GitOps Repository ====="

                        rm -rf gitops-repo

                        git clone \
                          --branch ${GITOPS_BRANCH} \
                          ${GITOPS_REPO} \
                          gitops-repo

                        cd gitops-repo


                        echo "===== Configure Git ====="

                        git config user.name "Jenkins"
                        git config user.email "jenkins@nplan.local"


                        echo "===== Update Frontend Image ====="

                        sed -i -E \
                          "s#image:[[:space:]]*${FRONTEND_IMAGE}:[^[:space:]]+#image: ${FRONTEND_IMAGE}:${BUILD_NUMBER}#" \
                          ${FRONTEND_MANIFEST}


                        echo "===== Update Backend Image ====="

                        sed -i -E \
                          "s#image:[[:space:]]*${BACKEND_IMAGE}:[^[:space:]]+#image: ${BACKEND_IMAGE}:${BUILD_NUMBER}#" \
                          ${BACKEND_MANIFEST}


                        echo "===== Updated Images ====="

                        grep "image:" ${FRONTEND_MANIFEST}
                        grep "image:" ${BACKEND_MANIFEST}


                        echo "===== Commit GitOps Change ====="

                        if git diff --quiet; then

                            echo "No GitOps change required."

                        else

                            git add \
                              ${FRONTEND_MANIFEST} \
                              ${BACKEND_MANIFEST}

                            git commit \
                              -m "deploy: update frontend and backend to ${BUILD_NUMBER}"

                            git push origin ${GITOPS_BRANCH}

                        fi
                    '''
                }
            }
        }
    }


    post {

        success {
            echo 'Frontend/Backend CI/CD pipeline succeeded.'
        }

        failure {
            echo 'Frontend/Backend CI/CD pipeline failed.'
        }
    }
}
