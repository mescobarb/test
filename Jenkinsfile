#!groovy

pipeline {
    agent {
        docker {
            image 'python:3.8'
            args '--network ci'
        }
    }

    environment {
        ORG_NAME = "CITTAVARAS"
        APP_NAME = "python-pipeline"
        APP_VERSION = "1.0"
        APP_CONTEXT_ROOT = "/"
        TEST_CONTAINER_NAME = "ci-${APP_NAME}-${BUILD_NUMBER}"
        DOCKER_HUB = credentials("${ORG_NAME}-docker-hub")
    }

    stages {
        stage('Environment preparation') {
            steps {
                echo "-=- preparing project environment -=-"
                sh "pip install -r requirements.txt"
            }
        }
        stage('Compile') {
            steps {
                echo "-=- compiling project -=-"
                sh "python -m compileall ."
            }
        }

        stage('Unit tests') {
            steps {
                echo "-=- execute unit tests -=-"
                sh "nosetests -v test"
            }
        }

        stage('Mutation tests') {
            steps {
                echo "-=- execute mutation tests -=-"
                sh "cosmic-ray init config.toml jenkins_session && cosmic-ray exec jenkins_session && cr-report jenkins_session"
            }
        }

        stage('Package') {
            steps {
                echo "-=- packaging project -=-"
                echo "No packaging phase for python projects ..."
            }
        }

        stage('Build Docker image') {
            steps {
                echo "-=- build Docker image -=-"
                sh "docker build -t ${ORG_NAME}/${APP_NAME}:${APP_VERSION} -t ${ORG_NAME}/${APP_NAME}:latest ."
            }
        }

        stage('Run Docker image') {
            steps {
                echo "-=- run Docker image -=-"
                sh "docker run --name ${TEST_CONTAINER_NAME} --detach --rm --network ci --expose 5000 ${ORG_NAME}/${APP_NAME}:latest"
            }
        }

        stage('Integration tests') {
            steps {
                echo "-=- execute integration tests -=-"
                sh "nosetests -v int_test"
            }
        }

        stage('Performance tests') {
            steps {
                echo "-=- execute performance tests -=-"
                sh "locust -f ./perf_test/locustfile.py --no-web -c 1000 -r 100 --run-time 1m -H http://${TEST_CONTAINER_NAME}:5000/${APP_CONTEXT_ROOT}"
            }
        }

        stage('Dependency vulnerability tests') {
            steps {
                echo "-=- run dependency vulnerability tests -=-"
                sh "safety check"
            }
        }

        stage('Code inspection & quality gate') {
            steps {
                echo "-=- run code inspection & quality gate -=-"
                sh "pylama"
            }
        }

        stage('Push Docker image') {
            steps {
                echo "-=- push Docker image -=-"
                withDockerRegistry([ credentialsId: "${ORG_NAME}-docker-hub", url: "" ]) {
                    sh "docker push ${ORG_NAME}/${APP_NAME}:${APP_VERSION}"
                    sh "docker tag ${ORG_NAME}/${APP_NAME}:${APP_VERSION} ${ORG_NAME}/${APP_NAME}:latest"
                }
            }
        }
    }

    post {
        always {
            echo "-=- remove deployment -=-"
            sh "docker stop ${TEST_CONTAINER_NAME}"
        }
    }
}
