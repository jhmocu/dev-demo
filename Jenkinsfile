pipeline {
    agent any // 어떤 에이전트에서든 실행 가능

    tools {
        maven 'maven 3.9.8' // Jenkins에 등록된 Maven 3.9.8을 사용
    }

    environment {
        // 배포에 필요한 변수 설정
        DOCKER_IMAGE = "demo-app"                     // 도커 이미지 이름
        CONTAINER_NAME = "springboot-container"       // 도커 컨테이너 이름
        JAR_FILE_NAME = "app.jar"                     // 복사할 JAR 파일 이름
        PORT = "80"                                   // 컨테이너와 연결할 포트
        REMOTE_USER = "ec2-user"                      // 원격 서버 사용자
        REMOTE_HOST = "13.124.44.138"               // 원격 서버 IP (공개 IP)
        REMOTE_DIR = "/home/ec2-user/deploy"          // 원격 서버에 파일을 복사할 경로
        SSH_CREDENTIALS_ID = "c5a72fe1-c4a2-46d4-bf93-2645b2bd4e72" // Jenkins SSH 자격 증명 ID
    }

    stages {
        stage('Git Checkout') {
            steps {
                // Jenkins가 연결된 Git 저장소에서 최신 코드 체크아웃
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                // 테스트는 건너뛰고 Maven으로 빌드
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Prepare WAR and Dockerfile') {
            steps {
                // 빌드 결과물인 JAR 파일을 지정한 이름(app.jar)으로 복사
                sh 'cp target/demo-0.0.1-SNAPSHOT.jar ${JAR_FILE_NAME}'
            }
        }

        stage('Copy to Remote Server') {
            steps {
                // Jenkins가 원격 서버에 SSH 접속할 수 있도록 sshagent 사용
                sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
                    // 원격 서버에 배포 디렉토리 생성 (없으면 새로 만듦)
                    sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} \"mkdir -p ${REMOTE_DIR}\""
                    // JAR 파일과 Dockerfile을 원격 서버에 복사
                    sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${JAR_FILE_NAME} Dockerfile ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
                }
            }
        }

        stage('Remote Docker Build & Deploy') {
            steps {
                sshagent (credentials: [env.SSH_CREDENTIALS_ID]) {
                    // 원격 서버에서 도커 컨테이너를 제거하고 새로 빌드 및 실행
                    sh """
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
    cd ${REMOTE_DIR} || exit 1                          # 복사한 디렉토리로 이동
    docker rm -f ${CONTAINER_NAME} || true             # 이전에 실행 중인 컨테이너 삭제 (없으면 무시)
    docker build -t ${DOCKER_IMAGE} .                  # 현재 디렉토리에서 Docker 이미지 빌드
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${DOCKER_IMAGE} # 새 컨테이너 실행
ENDSSH
                    """
                }
            }
        }
    }

    post {
        always {
            // 작업이 끝나면 워크스페이스 정리
            cleanWs()
        }
    }
}
