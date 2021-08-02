pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                echo 'Testing..'
                tox
                junit '**/*.xml'
            }
        }
    }
}
