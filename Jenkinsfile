pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ic-webapp'
        CONTAINER_NAME = 'test-ic-webapp'
    }

    stages {
        stage('Read releases.txt') {
            steps {
                script {
                    env.APP_VERSION = sh(
                        script: "awk '\$1 == \"VERSION\" {print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    env.ODOO_URL = sh(
                        script: "awk '\$1 == \"ODOO_URL\" {print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    env.PGADMIN_URL = sh(
                        script: "awk '\$1 == \"PGADMIN_URL\" {print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    if (!env.APP_VERSION || !env.ODOO_URL || !env.PGADMIN_URL) {
                        error('Une valeur manque dans releases.txt')
                    }

                    echo "Version : ${env.APP_VERSION}"
                    echo "ODOO_URL : ${env.ODOO_URL}"
                    echo "PGADMIN_URL : ${env.PGADMIN_URL}"
                }
            }
        }

        stage('Build image') {
            steps {
                sh '''
                    docker build \
                      --build-arg APP_VERSION="$APP_VERSION" \
                      --build-arg ODOO_URL="$ODOO_URL" \
                      --build-arg PGADMIN_URL="$PGADMIN_URL" \
                      -t "$IMAGE_NAME:$APP_VERSION" .
                '''
            }
        }

        
        
        stage('Test image') {
            steps {
                sh '''
                    set -eu

                    NETWORK_NAME="ic-test-network"

                    docker network inspect "$NETWORK_NAME" >/dev/null 2>&1 || \
                      docker network create "$NETWORK_NAME"

                    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
                    rm -f /tmp/ic-webapp-test.html

                    trap 'docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true; rm -f /tmp/ic-webapp-test.html' EXIT

                    docker run -d \
                      --name "$CONTAINER_NAME" \
                      --network "$NETWORK_NAME" \
                      "$IMAGE_NAME:$APP_VERSION"

                    for i in $(seq 1 15); do
                      if docker run --rm \
                        --network "$NETWORK_NAME" \
                        curlimages/curl:latest \
                        -fsS --max-time 5 \
                        http://test-ic-webapp:8080/ \
                        > /tmp/ic-webapp-test.html; then
                        break
                      fi
                      sleep 2
                    done

            

                    test -s /tmp/ic-webapp-test.html
                    grep -q 'Odoo' /tmp/ic-webapp-test.html
                    grep -q 'Postgres' /tmp/ic-webapp-test.html

                    echo "Test HTTP et contenu : OK"
                '''
            }
        }


        stage('Push Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set -eu

                        echo "$DOCKERHUB_TOKEN" | docker login \
                          -u "$DOCKERHUB_USERNAME" --password-stdin

                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        docker tag "$IMAGE_NAME:$APP_VERSION" \
                          "$DOCKERHUB_USERNAME/$IMAGE_NAME:$APP_VERSION"

                        docker push \
                          "$DOCKERHUB_USERNAME/$IMAGE_NAME:$APP_VERSION"
                    '''
                }
            }
        }
    }
    post {
        always {
            sh 'docker rm -f test-ic-webapp 2>/dev/null || true'
        }
        success {
            echo "Build et tests réussis pour ic-webapp:${APP_VERSION}"
        }
        failure {
            echo 'Le pipeline a échoué : consulter les logs des étapes.'
        }
    }
}
