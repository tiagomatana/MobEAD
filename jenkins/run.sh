#!/bin/bash
{
	docker run --name jenkins-blueocean --rm --detach --network jenkins \
	--env DOCKER_HOST=tcp://docker:2376 \
	--env DOCKER_CERT_PATH=/certs/client \
	--env DOCKER_TLS_VERIFY=1 \
	--volume jenkins-data:/var/jenkins_home \
	--volume jenkins-docker-certs:/certs/client:ro \
	--publish 8080:8080 \
	--publish 50000:50000 myjenkins-blueocean:1.1
} || {
	docker rm -f jenkins-blueocean &&
	docker run --name jenkins-blueocean --rm --detach --network jenkins \
        --env DOCKER_HOST=tcp://docker:2376 \
        --env DOCKER_CERT_PATH=/certs/client \
        --env DOCKER_TLS_VERIFY=1 \
        --volume jenkins-data:/var/jenkins_home \
        --volume jenkins-docker-certs:/certs/client:ro \
        --publish 8080:8080 \
        --publish 50000:50000 myjenkins-blueocean:1.1
}
