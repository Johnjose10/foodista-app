
pipeline {
    agent any

    environment {
        // Docker configuration
        DOCKER_CREDENTIALS_ID = 'docker-cred'
        DOCKER_IMAGE          = 'docker777john/foodista'

        // SonarQube configuration
        SONAR_SERVER_NAME     = 'sonarqube-env'
        SONAR_SCANNER_TOOL    = 'sonar-scanner'

        // GitHub configuration
        GIT_CREDENTIALS_ID    = 'github-cred'
        MANIFEST_REPO         = 'https://github.com/Johnjose10/foodista-app.git'
        MANIFEST_BRANCH       = 'main'
        MANIFEST_FILE         = 'foodista/manifests/deployment.yaml'
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo 'Foodista source code checked out successfully'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool "${SONAR_SCANNER_TOOL}"

                    withSonarQubeEnv("${SONAR_SERVER_NAME}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=foodista-key \
                            -Dsonar.projectName=foodista-project \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions=.git/**,**/.DS_Store,**/node_modules/**
                        """
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS_ID}",
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            set -eu

                            echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" --password-stdin

                            docker build \
                            -t "$DOCKER_IMAGE:$BUILD_NUMBER" \
                            -t "$DOCKER_IMAGE:latest" \
                            -f Dockerfile .

                            docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                            docker push "$DOCKER_IMAGE:latest"

                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Update Manifest Repo') {
            steps {
                dir('manifest-workspace') {

                    git branch: "${MANIFEST_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS_ID}",
                        url: "${MANIFEST_REPO}"

                    sh """
                        set -eu

                        if [ ! -f "${MANIFEST_FILE}" ]; then
                            echo "Manifest file not found!"
                            exit 1
                        fi

                        sed -i -E '/^[[:space:]]*name: foodista[[:space:]]*$/,/^[[:space:]]*image:/ s|^([[:space:]]*image:).*|\\1 ${DOCKER_IMAGE}:${BUILD_NUMBER}|' "${MANIFEST_FILE}"

                        git config user.name "Johnjose10"
                        git config user.email "jhon123jose@gmail.com"

                        git add "${MANIFEST_FILE}"

                        if ! git diff --cached --quiet; then
                            git commit -m "Update Foodista image to ${BUILD_NUMBER} [skip ci]"
                        else
                            echo "No manifest changes detected"
                        fi
                    """

                    withCredentials([
                        gitUsernamePassword(
                            credentialsId: "${GIT_CREDENTIALS_ID}",
                            gitToolName: 'Default'
                        )
                    ]) {
                        sh 'git push origin "$MANIFEST_BRANCH"'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Foodista pipeline executed successfully!'
            echo 'Docker image pushed and manifest repository updated.'
        }

        failure {
            echo 'Pipeline failed. Please check the stage logs.'
        }

        always {
            echo 'Foodista CI/CD pipeline finished.'
        }
    }
}
