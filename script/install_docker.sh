#!/bin/bash -ex

${DOCKER_VERSION:?You must set the 'DOCKER_VERSION' environment variable}

apt-get remove -y \
  docker \
  docker-engine \
  docker.io \
  containerd \
  runc

apt-get update -y

apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-cache gencaches
apt-get install -y \
  docker-ce=$( apt-cache madison docker-ce | grep -e $DOCKER_VERSION | cut -f 2 -d '|' | head -1 | sed 's/\s//g' )

if [ $? -ne 0 ]; then
  echo "Error: Could not install ${DOCKER_VERSION}"
  echo "Available docker versions:"
  apt-cache madison docker-ce
  exit 1
fi

systemctl start docker

docker swarm init
