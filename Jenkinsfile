pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'DEPLOY_TO_AWS',
            defaultValue: false,
            description: 'Activer uniquement lorsque les instances AWS et l’inventaire Ansible sont prêts'
        )
    }


    environment {
        IMAGE_NAME = 'ic-webapp'
        CONTAINER_NAME = 'test-ic-webapp'
        BUILDX_BUILDER = 'ic-multiarch-local'
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

        stage('Check Buildx') {
            steps {
                sh '''
                    set -eu
                    docker buildx inspect "$BUILDX_BUILDER" >/dev/null
                    docker buildx inspect "$BUILDX_BUILDER"
                '''
            }
        }

        stage('Build image for tests') {
            steps {
                sh '''
                    set -eu

                    docker buildx build \
                      --builder "$BUILDX_BUILDER" \
                      --platform linux/arm64 \
                      --load \
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

        stage('Push multiarchitecture Docker Hub') {
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

                        docker buildx build \
                          --builder "$BUILDX_BUILDER" \
                          --platform linux/amd64,linux/arm64 \
                          --build-arg APP_VERSION="$APP_VERSION" \
                          --build-arg ODOO_URL="$ODOO_URL" \
                          --build-arg PGADMIN_URL="$PGADMIN_URL" \
                          --tag "$DOCKERHUB_USERNAME/$IMAGE_NAME:$APP_VERSION" \
                          --push \
                          .
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            when {
                expression { params.DEPLOY_TO_AWS }
            }
            steps {
                script {
                    def inventory = readFile('ansible/inventory/hosts.ini')

                    if (!inventory.contains(
                        '# AWS_INFRASTRUCTURE_RECREATED_AND_INVENTORY_UPDATED'
                    )) {
                        error(
                            'Déploiement bloqué : recréer AWS, mettre à jour ' +
                            'ansible/inventory/hosts.ini, puis ajouter le marqueur ' +
                            'de validation dans le fichier.'
                        )
                    }

                    if (env.ODOO_URL == 'https://www.odoo.com/' ||
                        env.PGADMIN_URL == 'https://www.pgadmin.org/') {
                        error(
                            'Déploiement bloqué : remplacer les URL de démonstration ' +
                            'par les URL des applications déployées.'
                        )
                    }
                }

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    ),
                    string(
                        credentialsId: 'ansible-vault-password',
                        variable: 'ANSIBLE_VAULT_PASSWORD'
                    ),
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        VAULT_FILE="$(mktemp)"
                        trap 'rm -f "$VAULT_FILE"' EXIT
                        printf '%s' "$ANSIBLE_VAULT_PASSWORD" > "$VAULT_FILE"

                        cd ansible

                        ansible-playbook \
                          -i inventory/hosts.ini \
                          playbooks/site.yml \
                          --private-key "$SSH_KEY" \
                          --vault-password-file "$VAULT_FILE" \
                          --extra-vars \
                          "web_image_name=$DOCKERHUB_USERNAME/ic-webapp web_image_tag=$APP_VERSION odoo_url=$ODOO_URL pgadmin_url=$PGADMIN_URL"
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
            echo "Build, tests et publication réussis pour ${IMAGE_NAME}:${APP_VERSION} (linux/amd64, linux/arm64)"
        }

        failure {
            echo 'Le pipeline a échoué : consulter les logs des étapes.'
        }
    }
}
