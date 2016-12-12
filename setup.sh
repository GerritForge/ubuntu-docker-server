#!/bin/bash

function title {
  echo $1
  echo $1 | sed -e 's/./-/g'
}

title "Setup DNS"
killall -9 dnsmasq
sed -i -e 's/dns=dmsmsaq//g' /etc/NetworkManager/NetworkManager.conf
/etc/init.d/network-manager restart
sleep 5

title "Setup OpenSSH Server"
apt-get install -y openssh-server

title "Mount Docker volume"
mkdir /var/lib/docker
mount /dev/sdb2 /var/lib/docker

title "Install Docker"
apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 \
            --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual docker-engine

title "Configure Docker"
sed -i -e 's/ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/0.0.0.0:2375 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker.service


