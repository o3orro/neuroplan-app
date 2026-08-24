pipeline {
    agent any

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
    }
}
