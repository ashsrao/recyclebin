#!/bin/bash

#set -x

POSITIONAL_ARGS=()
SCRIPT_NAME=$0

DEFAULT_BOOKDIR=~/opt/livebook/books/
DEFAULT_PORT=8080

STOP_FLAG=0
PORT_NUM=${DEFAULT_PORT}
BOOK_PATH=${DEFAULT_BOOKDIR}

DOCKER_CMD='/usr/bin/docker'
CONTAINER_NAME="livebook"
CONTAINER_IMAGE="ghcr.io/livebook-dev/livebook"

function display_help() {
    echo ${SCRIPT_NAME}
    echo "-b/--book <book_path> where the books are saved : Default ->"${DEFAULT_BOOKDIR}
    echo "-p/--port <port_number> on which the livebook access be accessed: Default ->" ${DEFAULT_PORT}
    echo "-s/--stop to clean stop and remove any stale livebook instance"
}

function stop_container() {
  echo "Stopping ${CONTAINER_NAME}"
  docker stop ${CONTAINER_NAME}
  echo "Removing ${CONAINER_NAME}"
  docker rm ${CONTAINER_NAME}
}

# parse the arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--stop)
      STOP_FLAG=1
      shift # past argument
      shift # past value
      ;;
    -b|--book)
      BOOK_PATH="$2"
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


if [ ! -d ${BOOK_PATH} ]
then
    echo "Error: "${BOOK_PATH}" does not exist"
    echo ""
    display_help
    exit 1
fi

if [ ${PORT_NUM} -lt 1024 ] || [ ${PORT_NUM} -gt 65000 ]
then
    echo "Invalid port number "${PORT_NUM}
    echo ""
    display_help
    exit 1
fi

echo "Spawning livebook container using the following arguments"
echo "Book path  : "${BOOK_PATH}
echo "Port number: "${PORT_NUM}

(sleep 3;  xdg-open localhost:${PORT_NUM} > /dev/null 2>&1) & > /dev/null 2>&1

${DOCKER_CMD} run --rm \
              --name ${CONTAINER_NAME} \
              -e LIVEBOOK_TOKEN_ENABLED=false \
              -u `id -u`:`id -g` \
              -p ${PORT_NUM}:${PORT_NUM} \
              -v ${BOOK_PATH}:/data \
              ${CONTAINER_IMAGE}
