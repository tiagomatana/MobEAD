#!/bin/bash

docker rm -f jenkins-docker

docker run --name jenkins-docker --rm --detach --privileged \
	--network jenkins --network-alias docker  \
	--env DOCKER_TLS_CERTDIR=/certs \
	--env DOCKER_TLS_VERIFY=1 \
	--volume jenkins-docker-certs:/certs/client \
	--publish 81:81 \
	--publish 82:82 \
	--volume jenkins-data:/var/jenkins_home docker:dind
