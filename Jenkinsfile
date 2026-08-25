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


        stage('Detect Changes') {
            steps {
                script {

                    echo "===== Detect Changes ====="

                    // 현재 최신 커밋에서 변경된 파일 목록 확인
                    def changedFilesText = sh(
                        script: '''
                            git -c color.ui=false show \
                              --name-only \
                              --pretty="" \
                              HEAD | sed '/^[[:space:]]*$/d'
                        ''',
                        returnStdout: true
                    ).trim()


                    echo "===== Changed Files ====="

                    if (changedFilesText) {
                        echo "${changedFilesText}"
                    } else {
                        echo "No changed files detected."
                    }


                    // frontend/ 디렉터리 변경 확인
                    def frontendStatus = sh(
                        script: '''
                            git -c color.ui=false show \
                              --name-only \
                              --pretty="" \
                              HEAD \
                            | sed '/^[[:space:]]*$/d' \
                            | grep -q '^frontend/'
                        ''',
                        returnStatus: true
                    )


                    // backend/ 디렉터리 변경 확인
                    def backendStatus = sh(
                        script: '''
                            git -c color.ui=false show \
                              --name-only \
                              --pretty="" \
                              HEAD \
                            | sed '/^[[:space:]]*$/d' \
                            | grep -q '^backend/'
                        ''',
                        returnStatus: true
                    )


                    if (frontendStatus == 0) {
                        env.FRONTEND_CHANGED = 'true'
                    } else {
                        env.FRONTEND_CHANGED = 'false'
                    }


                    if (backendStatus == 0) {
                        env.BACKEND_CHANGED = 'true'
                    } else {
                        env.BACKEND_CHANGED = 'false'
                    }


                    echo "===== Change Detection Result ====="
                    echo "Frontend changed: ${env.FRONTEND_CHANGED}"
                    echo "Backend changed : ${env.BACKEND_CHANGED}"
                }
            }
        }


        stage('Backend Maven Build') {
            when {
                expression {
                    env.BACKEND_CHANGED == 'true'
                }
            }

            steps {
                dir('backend') {
                    sh '''
                        echo "===== Backend Maven Build ====="

                        mvn clean package -DskipTests
                    '''
                }
            }
        }


        stage('Frontend Docker Build') {
            when {
                expression {
                    env.FRONTEND_CHANGED == 'true'
                }
            }

            steps {
                sh '''
                    echo "===== Frontend Docker Build ====="

                    docker build \
                      -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} \
                      -t ${FRONTEND_IMAGE}:latest \
                      ./frontend
                '''
            }
        }


        stage('Backend Docker Build') {
            when {
                expression {
                    env.BACKEND_CHANGED == 'true'
                }
            }

            steps {
                sh '''
                    echo "===== Backend Docker Build ====="

                    docker build \
                      -t ${BACKEND_IMAGE}:${BUILD_NUMBER} \
                      -t ${BACKEND_IMAGE}:latest \
                      ./backend
                '''
            }
        }


        stage('Docker Hub Login & Push') {
            when {
                expression {
                    env.FRONTEND_CHANGED == 'true' ||
                    env.BACKEND_CHANGED == 'true'
                }
            }

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

                        echo "===== Docker Hub Login ====="

                        echo "$DOCKERHUB_TOKEN" | \
                        docker login \
                          -u "$DOCKERHUB_USER" \
                          --password-stdin


                        if [ "$FRONTEND_CHANGED" = "true" ]; then

                            echo "===== Push Frontend ====="

                            docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                            docker push ${FRONTEND_IMAGE}:latest

                        else

                            echo "Frontend unchanged - skip push."

                        fi


                        if [ "$BACKEND_CHANGED" = "true" ]; then

                            echo "===== Push Backend ====="

                            docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                            docker push ${BACKEND_IMAGE}:latest

                        else

                            echo "Backend unchanged - skip push."

                        fi


                        docker logout
                    '''
                }
            }
        }


        stage('Update GitOps') {
            when {
                expression {
                    env.FRONTEND_CHANGED == 'true' ||
                    env.BACKEND_CHANGED == 'true'
                }
            }

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


                        if [ "$FRONTEND_CHANGED" = "true" ]; then

                            echo "===== Update Frontend Image ====="

                            sed -i -E \
                              "s#image:[[:space:]]*${FRONTEND_IMAGE}:[^[:space:]]+#image: ${FRONTEND_IMAGE}:${BUILD_NUMBER}#" \
                              ${FRONTEND_MANIFEST}

                            git add ${FRONTEND_MANIFEST}

                        else

                            echo "Frontend unchanged - skip GitOps update."

                        fi


                        if [ "$BACKEND_CHANGED" = "true" ]; then

                            echo "===== Update Backend Image ====="

                            sed -i -E \
                              "s#image:[[:space:]]*${BACKEND_IMAGE}:[^[:space:]]+#image: ${BACKEND_IMAGE}:${BUILD_NUMBER}#" \
                              ${BACKEND_MANIFEST}

                            git add ${BACKEND_MANIFEST}

                        else

                            echo "Backend unchanged - skip GitOps update."

                        fi


                        echo "===== GitOps Changes ====="

                        git diff --cached


                        if git diff --cached --quiet; then

                            echo "No GitOps change required."

                        else

                            git commit \
                              -m "deploy: update changed application images to ${BUILD_NUMBER}"

                            git push origin ${GITOPS_BRANCH}

                        fi
                    '''
                }
            }
        }
    }


    post {

        success {
            echo """
            CI/CD pipeline succeeded.

            Frontend changed: ${env.FRONTEND_CHANGED}
            Backend changed : ${env.BACKEND_CHANGED}
            """
        }

        failure {
            echo 'CI/CD pipeline failed.'
        }
    }
}
