node {
    checkout([
        $class: 'GitSCM',
        branches: [[name: '*/jenkins']],
        extensions: [[
            $class: 'SubmoduleOption',
            disableSubmodules: false,
            parentCredentials: false,
            recursiveSubmodules: true,
            reference: '',
            trackingSubmodules: false,
        ]],
        userRemoteConfigs: [[
            credentialsId: 'github-app-bouttier',
            url: 'https://github.com/bouttier/GeoNature',
        ]],
    ])
}

pipeline {
    agent any

    environment {
        GEONATURE_SQLALCHEMY_DATABASE_URI = credentials('geonature-sqlalchemy-database-uri')
    }

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
