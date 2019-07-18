#!/bin/bash

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS="${ID}-${VERSION_ID}"
else
    # We expect RHEL or Centos 7 for now. Lets set something as fallback
    OS="$(uname -s)-$(uname -r)"
fi

echo "checking docker executable"
if ! [ -x "$(command -v docker)" ]; then
  case $OS in
  rhel*)
    extrasrepo=$(cat /etc/yum.repos.d/redhat* | grep -E '^\[.*extras.*\]$' | grep -vE 'debug|source' | tr -d '[|]')
    sudo yum install -y --enablerepo $extrasrepo docker
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo setenforce 0
    ;;
  *)
    echo "installing docker"
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl disable firewalld.service
    sudo systemctl stop firewalld.service
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo setenforce 0
    ;;
  esac
  echo "sleep 30s to let docker become ready"
  sleep 30
fi

echo "checking dockerd connection"
until sudo docker info; do
  echo "docker info returned error"
  if sudo systemctl is-active docker.service >/dev/null; then
    sudo systemctl start docker.service
    sleep 60
    continue
  fi
  echo "docker running but not yet responging. Sleeping 60s..."
  sleep 60
done
echo "docker is running"
