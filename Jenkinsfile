pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'tox'
                junit '**/*.xml'
            }
        }
    }
}
