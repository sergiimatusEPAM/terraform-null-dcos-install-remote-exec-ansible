#!/bin/bash

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS="${ID}-${VERSION_ID}"
else
    # We expect RHEL or Centos 7 for now. Lets set something as fallback
    OS="$(uname -s)-$(uname -r)"
fi

if ! [ -x "$(command -v docker)" ]; then
  echo "installing docker"
  case $OS in
  rhel*)
    extrasrepo=$(cat /etc/yum.repos.d/redhat* | grep -E '^\[.*extras.*\]$' | grep -vE 'debug|source' | tr -d '[|]')
    if ! [ -z ${extrasrepo} ]; then
      sudo yum install -y --enablerepo $extrasrepo docker
    else
      sudo yum install -y docker
    fi
    sudo systemctl daemon-reload
    sudo systemctl disable firewalld.service
    sudo systemctl stop firewalld.service
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo setenforce 0
    ;;
  *)
    which yum-config-manager || sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl daemon-reload
    sudo systemctl disable firewalld.service
    sudo systemctl stop firewalld.service
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo setenforce 0
    ;;
  esac
fi

until sudo docker info >/dev/null 2>&1; do
  if sudo systemctl is-active docker.service >/dev/null; then
    sudo systemctl start docker.service
    continue
  fi
  echo "docker running but not yet responding. Sleeping 10s..."
  sleep 10
done
echo "docker is running"
