pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_USER          = 'votre_username_dockerhub'
    }

    stages {
        stage('1. Extraction des Variables') {
            steps {
                script {
                    env.APP_VERSION = sh(script: "awk '/VERSION/ {print \$2}' releases.txt", returnStdout: true).trim()
                    env.ODOO_URL    = sh(script: "awk '/ODOO_URL/ {print \$2}' releases.txt", returnStdout: true).trim()
                    env.PGADMIN_URL = sh(script: "awk '/PGADMIN_URL/ {print \$2}' releases.txt", returnStdout: true).trim()
                }
            }
        }

        stage('2. Build de l\'Image') {
            steps {
                sh '''
                docker build \
                  --build-arg APP_VERSION=${APP_VERSION} \
                  --build-arg ODOO_URL=${ODOO_URL} \
                  --build-arg PGADMIN_URL=${PGADMIN_URL} \
                  -t ic-webapp:${APP_VERSION} .
                '''
            }
        }

        stage('3. Tests de Validation') {
            steps {
                script {
                    sh "docker run -d -p 8080:8080 --name test-ic-webapp-ci ic-webapp:${APP_VERSION}"
                    sh "sleep 5"
                    sh "curl -s -f http://localhost:8080 > /dev/null"
                    sh "docker exec test-ic-webapp-ci env | grep ODOO_URL"
                    sh "docker exec test-ic-webapp-ci env | grep PGADMIN_URL"
                }
            }
            post {
                always {
                    sh "docker rm -f test-ic-webapp-ci || true"
                }
            }
        }

        stage('4. Push sur Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                    echo "$PASS" | docker login -u "$USER" --password-stdin
                    docker tag ic-webapp:${APP_VERSION} ${DOCKER_USER}/ic-webapp:${APP_VERSION}
                    docker push ${DOCKER_USER}/ic-webapp:${APP_VERSION}
                    '''
                }
            }
        }

        stage('5. Déploiement via Ansible') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbooks/deploy.yml',
                    inventory: 'ansible/inventory.ini',
                    extraVars: [
                        app_version: "${env.APP_VERSION}",
                        docker_user: "${env.DOCKER_USER}"
                    ]
                )
            }
        }
    }
}