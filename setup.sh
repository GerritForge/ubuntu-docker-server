#!/bin/bash -e

function title {
  echo $1
  echo $1 | sed -e 's/./-/g'
}

title "Setup DNS"
killall -9 dnsmasq
sed -i -e 's/dns=dnsmasq//g' /etc/NetworkManager/NetworkManager.conf
/etc/init.d/network-manager restart

function isNetworkUp {
  echo "GET /" | nc archive.ubuntu.com 80
}

while !isNetworkUp
do
  echo "Waiting for network to come up ..."
  sleep 1
done

title "Setup OpenSSH Server"
apt-get install -y openssh-server

title "Mount Docker volume"
if [ ! -d /var/lib/docker ]
then
  mkdir /var/lib/docker
  mount /dev/sdb2 /var/lib/docker
fi

title "Install Docker"
apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 \
            --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual docker-engine

title "Configure Docker"
sed -i -e 's/ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/0.0.0.0:2375 -H unix:\/\/\/var\/run\/docker.sock --insecure-registry artifactory.nap:6556/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker.service

title "Enable root login via SSH"
if [ ! -d ~/.ssh ]
then
  ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa < /dev/null
  echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA0R66EoZ7hFp81w9sAJqu34UFyE+w36H/mobUqnT5Lns7PcTOJh3sgMJAlswX2lFAWqvF2gd2PRMpMhbfEU4iq2SfY8x+RDCJ4ZQWESln/587T41BlQjOXzu3W1bqgmtHnRCte3DjyWDvM/fucnUMSwOgP+FVEZCLTrk3thLMWsU= rootkey' >> ~/.ssh/authorized_keys
  echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDvu1P+ALB0dvkHVSAOfAVe+GSNqoBdRNfILP0x2TjGpwipNIaW7dKbACpq4w9JpfakKtOSThv7Ar2clfZeWlu5InMqLL5vX/QX9VB/Du2EhYYehHvEzKVwosfRvcMnv20Axh8obuA7AHPMguvS9ggMDpfpEL9YFXE3JPmpX8cC+9DTumuUnBH/bJWslX/JAuEeAI3bkeEjErCqjnE3um4JGYPv+LF4yNQ7KC3FfkXiY7e9ynCSe3AvAqNPMTHP/Yph8v7iVbKPb3Avs/igIEH2lkKJhq8SWMt/DuCft8yYVybfi3amYUIsjdIAWcc/ct/AhfH4LSkp0dVlL4uEwE1D rootkey1' >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
fi

title "Enable docker socket for all users"
chmod a+rw /var/run/docker.sock

title "Server up-and-running"
IP=$(ip -f inet addr show | grep inet | awk '{print $2}' | grep -v 127.0. | grep -v 172. | cut -d '/' -f 1)
echo "IP: $IP"

title "Ready to serve Docker machine remotely"
echo "Set your DOCKER_HOST to tcp://$IP:2375"
