pipeline {
    agent any
    
    tools {
		maven 'maven 3.9.8'
	}

    environment {
        DOCKER_IMAGE = "demo-app"
        CONTAINER_NAME = "springboot-container"
        JAR_FILE_NAME = "app.jar"
        PORT = "80"
        REMOTE_USER = "ec2-user"
        REMOTE_HOST = "3.38.235.180"
        REMOTE_DIR = "/home/ec2-user/deploy"
        SSH_CREDENTIALS_ID = "c2d76aaa-2449-4a89-ba56-ec2092f3c514" // Jenkins credentials ID for SSH Agent plugin
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Copy to Remote Server') {
            steps {
                sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
                    sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} \"mkdir -p ${REMOTE_DIR}\""
                    sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${JAR_FILE_NAME} Dockerfile ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
                }
            }
        }

        stage('Remote Docker Build & Deploy') {
            steps {
                sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
					sh """
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
    cd ${REMOTE_DIR} || exit 1
    docker rm -f ${CONTAINER_NAME} || true
    docker build -t ${DOCKER_IMAGE} .
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${DOCKER_IMAGE}
ENDSSH
					"""
                }
            }
        }
    }
    
    post {
	    always {
	        cleanWs()
	    }
	}
}