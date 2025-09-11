#!/bin/bash

# set -x

POSITIONAL_ARGS=()
SCRIPT_NAME=$0

DEFAULT_PORT=8080

STOP_FLAG=0
PORT_NUM=${DEFAULT_PORT}

DOCKER_CMD='/usr/bin/docker'
CONTAINER_NAME="open-webui"
CONTAINER_IMAGE="ghcr.io/open-webui/open-webui:main"
OLLAMA_URL="http://192.168.8.1:8080"



function display_help() {
    echo ${SCRIPT_NAME}
    echo "-p/--port <port_number> on which the livebook access be accessed: Default ->" ${DEFAULT_PORT}
    echo "-s/--stop to clean stop and remove any stale livebook instance"
}

function stop_container() {
  echo "Stopping ${CONTAINER_NAME}"
  docker stop ${CONTAINER_NAME}
  echo "Removing ${CONAINER_NAME}"
  sleep 1
  docker rm ${CONTAINER_NAME}
}

function start_browser() {
  (sleep 3;  xdg-open localhost:${PORT_NUM} > /dev/null 2>&1) & > /dev/null 2>&1
}

# parse the arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--stop)
      STOP_FLAG=1
      shift # past argument
      shift # past value
      ;;
    -p|--port)
      PORT_NUM="$2"
      shift # past argument
      shift # past value
      ;;  
    *)
      echo "Unknown option $1"
      display_help
      exit 1
      ;;
  esac
done

if [ ${STOP_FLAG} -eq 1 ]
then
    stop_container
    exit 0
fi

# Check if it already running
if docker ps -a | grep -q "${CONTAINER_NAME}"; then
  start_browser
  echo "Container ${CONTAINER_NAME} is already running."
  exit 1
fi   

# Now do the steps to spawn the container. 

if [ ${PORT_NUM} -lt 1024 ] || [ ${PORT_NUM} -gt 65000 ]
then
    echo "Invalid port number "${PORT_NUM}
    echo ""
    display_help
    exit 1
fi

echo "Spawning ${CONTAINER_NAME} container using the following arguments"
echo "Port number: "${PORT_NUM}

start_browser

${DOCKER_CMD} run --rm -d \
              --name ${CONTAINER_NAME} \
              -p ${PORT_NUM}:${PORT_NUM} \
              -e OLLAMA_BASE_URL="${OLLAMA_URL}"\
              -v open-webui:/app/backend/data \
              ${CONTAINER_IMAGE}