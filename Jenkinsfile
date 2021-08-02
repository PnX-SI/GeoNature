pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'tox -e py37-ci'
                junit '**/*.xml'
            }
        }
    }
}
