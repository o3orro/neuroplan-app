pipeline {
    agent any

    environment {
        // Docker Hub 이미지
        IMAGE_NAME = 'yerinnn/neuroplan-ci-test'

        // GitOps Repository
        GITOPS_REPO = 'git@github.com:o3orro/neuroplan-gitops.git'
        GITOPS_BRANCH = 'main'
        GITOPS_MANIFEST = 'manifests/deployment.yaml'
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

                        echo "===== Prepare SSH ====="

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

                        echo "===== Update Kubernetes Image Tag ====="

                        sed -i -E \
                          "s#image:[[:space:]]*${IMAGE_NAME}:[^[:space:]]+#image: ${IMAGE_NAME}:${BUILD_NUMBER}#" \
                          ${GITOPS_MANIFEST}

                        echo "===== New Image ====="

                        grep "image:" ${GITOPS_MANIFEST}

                        echo "===== Commit GitOps Change ====="

                        if git diff --quiet; then
                            echo "No GitOps change required."
                        else
                            git add ${GITOPS_MANIFEST}

                            git commit \
                              -m "deploy: update neuroplan image to ${BUILD_NUMBER}"

                            git push origin ${GITOPS_BRANCH}
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline succeeded.'
        }

        failure {
            echo 'CI/CD pipeline failed.'
        }
    }
}
