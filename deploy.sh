#!/bin/bash

# Docker 관련 환경 변수 설정
IMAGE_NAME=${IMAGE_NAME:-"alkaline2018/danana"}
APP_NAME="danana"
# 버전 번호를 2 번째 인자로 받음 (예: ./docker_build.sh run 0.0.1)
VERSION=$2

# 버전 번호가 제공되지 않았을 경우 기본값 설정
if [ -z "$VERSION" ]; then
  echo "버전 번호를 지정하지 않았습니다. 기본값 latest 을 사용합니다."
  VERSION="latest"
fi
TAG=${VERSION}

# 서버 관련 설정
REMOTE_USER="root"
REMOTE_HOST="106.10.39.129"
REMOTE_SSH_PORT=3809

# 로그 출력 함수
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 에러 처리 함수
error_exit() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Error: $1"
    sleep 10
    exit 1
}

# Docker 이미지 빌드
build() {
    log "Building Docker image..."
    docker build -t $IMAGE_NAME:$TAG . || error_exit "Docker build failed."
    log "Docker image built successfully."
}

# Docker 이미지 푸시
push() {
    log "Pushing Docker image to repository..."
    docker push $IMAGE_NAME:$TAG || error_exit "Docker push failed."
    log "Docker image pushed successfully."
}

# 서버에서 Docker 이미지 풀
server_pull() {
    log "Pulling Docker image on server..."
    ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "docker pull $IMAGE_NAME:$TAG" || error_exit "Docker pull on server failed."
    log "Docker image pulled on server successfully."
}

# 서버에서 Docker 컨테이너 실행
server_run() {
    log "Running Docker container on server..."
    ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "docker stop $APP_NAME || true && docker rm $APP_NAME || true && docker run -d -p 8010:8000 --name $APP_NAME $IMAGE_NAME:$TAG" || error_exit "Docker run on server failed."
    log "Docker container is running on server."
}

# 로컬에서 Docker 컨테이너 실행
run() {
    log "Running Docker container locally..."
    docker stop $APP_NAME || true && docker rm $APP_NAME || true && docker run -d -p 8010:8000 --name $APP_NAME $IMAGE_NAME:$TAG || error_exit "Docker run locally failed."
    log "Docker container is running locally."
}

# Docker 컨테이너 종료 및 삭제 (로컬)
clean() {
    log "Cleaning up Docker container locally..."
    docker rm -f $APP_NAME || error_exit "Failed to remove Docker container locally."
    log "Docker container removed locally."
}

# 서버에서 Docker 컨테이너 종료 및 삭제
server_clean() {
    log "Cleaning up Docker container on server..."
    ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "docker rm -f $APP_NAME" || error_exit "Failed to remove Docker container on server."
    log "Docker container removed on server."
}

# Usage 설명 출력
usage() {
    echo "Usage: $0 {build|push|pull|run|server_pull|server_run|clean|server_clean|all|server_all}"
    echo
    echo "Options:"
    echo "  build          Build the Docker image locally"
    echo "  push           Push the Docker image to the repository"
    echo "  pull           Pull the Docker image locally"
    echo "  run            Run the Docker container locally"
    echo "  server_pull    Pull the Docker image on the remote server"
    echo "  server_run     Run the Docker container on the remote server"
    echo "  clean          Remove the Docker container locally"
    echo "  server_clean   Remove the Docker container on the remote server"
    echo "  all            Build, push, pull and run locally"
    echo "  server_all     Build, push, pull and run on the remote server"
#    exit 1
}


# 명령어 옵션 처리
case "$1" in
    build)
        build
        ;;
    push)
        build
        push
        ;;
    pull)
        pull
        ;;
    run)
        run
        ;;
    server_pull)
        server_pull
        ;;
    server_run)
        server_run
        ;;
    clean)
        clean
        ;;
    server_clean)
        server_clean
        ;;
    all)
        build
        push
        pull
        run
        ;;
    server_all)
        build
        push
        server_pull
        server_run
        ;;
    *)
        usage
        ;;
esac

sleep 10