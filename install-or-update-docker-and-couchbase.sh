#!/bin/bash

# Note: the terminal which runs this script needs to have root access!!
#sudo REQUIRED_DOCKER_VERSION=18.09.5 REQUIRED_COUCHBASE_VERSION=6.0.0 DEBUG=true ./install-or-update-docker-and-couchbase.sh
# TODO: Add a .sh file that lists a bunch of environment variables that can be swapped out:
# https://stackoverflow.com/a/28489593/8132430

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# HELPER FUNCTIONS
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

updateDockerToOrInstall() {
	if [ -z "$1" ]; then
		echo "Argument \$1 is required in function updateDockerToOrInstall(version).";
		exit 1;
	else
		echo "Executing docker-install.sh";
		chmod a+rx docker-install.sh;
		VERSION=$1 ./docker-install.sh;
	fi
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# INSTALL OR UPDATE DOCKER
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

DOCKER_IS_INSTALLED=false;
REQUIRED_DOCKER_VERSION=${REQUIRED_DOCKER_VERSION};
if [ -z "${REQUIRED_DOCKER_VERSION}" ]; then
	echo "REQUIRED_DOCKER_VERSION argument is required.";
	exit 1;
fi

#https://stackoverflow.com/questions/23658744/egrep-match-version-number-using-grep
INSTALLED_DOCKER_VERSION=$(docker --version | egrep -o '([0-9]{1,}\.)+[0-9]{1,}');

if [ -x "$(command -v docker)" ]; then
	DOCKER_IS_INSTALLED=true;
fi

if [ DOCKER_IS_INSTALLED ]
then
	echo "Docker version ${REQUIRED_DOCKER_VERSION} is required."
  echo "Docker version ${INSTALLED_DOCKER_VERSION} is installed.";

	if [ "${INSTALLED_DOCKER_VERSION}" != "${REQUIRED_DOCKER_VERSION}" ]
	then
    echo "Updating docker to ${REQUIRED_DOCKER_VERSION}...";
		updateDockerToOrInstall $REQUIRED_DOCKER_VERSION;

	else
		echo "Skipping ahead...";
	fi
else
		echo "Docker not installed.";
		echo "Installing docker ${REQUIRED_DOCKER_VERSION}...";
		updateDockerToOrInstall $REQUIRED_DOCKER_VERSION;
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# INSTALL, RUN, AND CONFIGURE COUCHBASE
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

echo "Installing & running couchbase...";
REQUIRED_COUCHBASE_VERSION=${REQUIRED_COUCHBASE_VERSION:-"latest"}
COUCHBASE_ADMINISTRATOR_USERNAME=${COUCHBASE_ADMINISTRATOR_USERNAME:-"Administrator"};
COUCHBASE_ADMINISTRATOR_PASSWORD=${COUCHBASE_ADMINISTRATOR_PASSWORD:-"password"};
# NEW_COUCHBASE_ADMIN_USERNAME=${NEW_COUCHBASE_ADMIN_USERNAME:-"tester"};
# NEW_COUCHBASE_ADMIN_PASSWORD=${NEW_COUCHBASE_ADMIN_PASSWORD:-"password"};
# TODO: Add support for multiple buckets
COUCHBASE_BUCKET_NAME=${COUCHBASE_BUCKET_NAME:-"testbucket"};
COUCHBASE_BUCKET_PASSWORD=${COUCHBASE_BUCKET_PASSWORD:-"bucketpassword"};
COUCHBASE_IMAGE_NAME=${COUCHBASE_IMAGE_NAME:-"couchbase-install-image"};
COUCHBASE_CONTAINER_NAME=${COUCHBASE_CONTAINER_NAME:-"agc-couchbase"};
COUCHBASE_DOCKERFILE_NAME=${COUCHBASE_DOCKERFILE_NAME:-"couchbase-install.Dockerfile"};
COUCHBASE_HOST_LOCATION=${COUCHBASE_HOST_LOCATION:-"127.0.0.1"};
CLUSTER_RAMSIZE=${CLUSTER_RAMSIZE:-8401};

echo "Stopping running '${COUCHBASE_CONTAINER_NAME}' container and deleting '${COUCHBASE_IMAGE_NAME}' image.";
docker stop ${COUCHBASE_CONTAINER_NAME} && \
	docker rm ${COUCHBASE_CONTAINER_NAME} && \
	docker rmi ${COUCHBASE_IMAGE_NAME};

docker build \
	--build-arg REQUIRED_COUCHBASE_VERSION \
	-t ${COUCHBASE_IMAGE_NAME} \
	-f ${COUCHBASE_DOCKERFILE_NAME} \
	.;

docker run \
	-d --name ${COUCHBASE_CONTAINER_NAME} \
	-p 8091-8094:8091-8094 \
	-p 11210:11210 \
	-e CLUSTER_RAMSIZE=${CLUSTER_RAMSIZE} \
	-e COUCHBASE_HOST_LOCATION=${COUCHBASE_HOST_LOCATION} \
	-e COUCHBASE_ADMINISTRATOR_USERNAME=${COUCHBASE_ADMINISTRATOR_USERNAME} \
	-e COUCHBASE_ADMINISTRATOR_PASSWORD=${COUCHBASE_ADMINISTRATOR_PASSWORD} \
	-e COUCHBASE_BUCKET_NAME=${COUCHBASE_BUCKET_NAME} \
	-e COUCHBASE_BUCKET_PASSWORD=${COUCHBASE_BUCKET_PASSWORD} \
	-e NEW_COUCHBASE_ADMIN_USERNAME=${NEW_COUCHBASE_ADMIN_USERNAME} \
	-e NEW_COUCHBASE_ADMIN_PASSWORD=${NEW_COUCHBASE_ADMIN_PASSWORD} \
	${COUCHBASE_IMAGE_NAME};

DEBUG=${DEBUG:-false};
if ${DEBUG}; then
	LOGGING_TIME=${LOGGING_TIME:-30s};
	echo "Logging Docker for ${LOGGING_TIME}:";
	docker logs -f ${COUCHBASE_CONTAINER_NAME};
fi
