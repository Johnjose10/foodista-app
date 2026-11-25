
pipeline {
    agent any

    environment {
        // Docker configuration
        DOCKER_CREDENTIALS_ID = 'docker-cred'
        DOCKER_IMAGE = 'docker777john/foodista'

        // SonarQube configuration
        SONAR_SERVER_NAME = 'sonarqube-env'
        SONAR_SCANNER_TOOL = 'sonar-scanner'

        // GitHub configuration
        GIT_CREDENTIALS_ID = 'github-cred'

        // Manifest repository configuration
        MANIFEST_REPO = 'https://github.com/Johnjose10/foodista-app.git'
        MANIFEST_BRANCH = 'main'
        MANIFEST_FILE = 'manifests/deployment.yaml'
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                echo 'Checking out Foodista source code...'
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'

                script {
                    def scannerHome = tool "${SONAR_SCANNER_TOOL}"

                    withSonarQubeEnv("${SONAR_SERVER_NAME}") {
                        sh """
                            "${scannerHome}/bin/sonar-scanner" \
                            -Dsonar.projectKey=foodista \
                            -Dsonar.projectName=Foodista \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions=**/node_modules/**,**/.git/**,**/images/**,**/fonts/**
                        """
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                echo 'Building and pushing Foodista Docker image...'

                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin

                        docker build -t "$DOCKER_IMAGE:$BUILD_NUMBER" .
                        docker tag "$DOCKER_IMAGE:$BUILD_NUMBER" "$DOCKER_IMAGE:latest"

                        docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                        docker push "$DOCKER_IMAGE:latest"

                        docker logout
                    '''
                }
            }
        }

        stage('Update Manifest Repository') {
            steps {
                echo 'Updating Kubernetes deployment manifest...'

                dir('manifest-workspace') {

                    git branch: "${MANIFEST_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS_ID}",
                        url: "${MANIFEST_REPO}"

                    withEnv([
                        "IMAGE_NAME=${DOCKER_IMAGE}",
                        "IMAGE_TAG=${BUILD_NUMBER}",
                        "MANIFEST_PATH=${MANIFEST_FILE}"
                    ]) {

                        sh '''
                            set -eu

                            if [ ! -f "$MANIFEST_PATH" ]; then
                                echo "ERROR: Manifest file not found: $MANIFEST_PATH"
                                exit 1
                            fi

                            # Update the image of the Foodista container
                            sed -i -E \
                            '/^[[:space:]]*name: foodista[[:space:]]*$/,/^[[:space:]]*image:/ s|^([[:space:]]*image:).*|\\1 '"$IMAGE_NAME:$IMAGE_TAG"'|' \
                            "$MANIFEST_PATH"

                            echo "Updated image:"
                            grep -A 2 'name: foodista' "$MANIFEST_PATH"

                            git config user.name "Johnjose10"
                            git config user.email "jhon123jose@gmail.com"

                            git add "$MANIFEST_PATH"

                            if ! git diff --cached --quiet; then
                                git commit -m "Update Foodista image to $IMAGE_TAG [skip ci]"
                            else
                                echo "No manifest changes detected."
                            fi
                        '''

                        withCredentials([
                            gitUsernamePassword(
                                credentialsId: "${GIT_CREDENTIALS_ID}",
                                gitToolName: 'Default'
                            )
                        ]) {
                            sh '''
                                git push origin "$MANIFEST_BRANCH"
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Foodista pipeline completed successfully!'
            echo 'Docker image pushed and Kubernetes manifest updated.'
        }

        failure {
            echo 'Foodista pipeline failed. Please check the Jenkins console output.'
        }

        always {
            echo 'Foodista pipeline execution finished.'
        }
    }
}
