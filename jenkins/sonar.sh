#!/bin/bash
docker run -d --name sonarqube -p 9000:9000 --network jenkins sonarqube:8.9.2-community
wget -O scanner.zip https://s3.amazonaws.com/caelum-online-public/1110-jenkins/05/sonar-scanner-cli-3.3.0.1492-linux.zip
unzip scanner.zip
docker cp scanner.zip jenkins-blueocean:/var/jenkins_home/
