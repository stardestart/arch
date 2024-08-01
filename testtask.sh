#!/bin/bash
#
#apt install docker-ce -y
apt install curl software-properties-common ca-certificates apt-transport-https -y
wget -O- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-cache policy docker-ce
apt install docker-ce -y
#
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#
chmod +x /usr/local/bin/docker-compose
#
#docker-compose
#
apt install snapd
#
snap install cqlsh
#
#systemctl status docker
#
echo 'networks:
  host-network:
    name: host-network
    driver: bridge
    ipam:
     config:
       - subnet: 192.168.1.0/24

services:
  cass-db-seed:
    image: cassandra:5
    container_name: cass-db-seed
    ports:
      - 9042:9042 # cqlsh
    networks:
      host-network:
        ipv4_address: 192.168.1.200
    restart: always

  cass-db-1:
    container_name: cass-db-1
    image: cassandra:5
    ports:
      - 9043:9042
    environment:
      - CASSANDRA_SEEDS=cass-db-seed
    networks:
      host-network:
        ipv4_address: 192.168.1.201
    depends_on:
      - cass-db-seed
    restart: always

  cass-db-2:
    container_name: cass-db-2
    image: cassandra:5
    ports:
      - 9044:9042
    environment:
      - CASSANDRA_SEEDS=cass-db-seed
    networks:
      host-network:
        ipv4_address: 192.168.1.202
    depends_on:
      - cass-db-seed
    restart: always' > docker-compose.yml
#
docker-compose up  -d
#
echo '
docker-compose up  -d
exit 0' > /etc/rc.local
#
chmod +x /etc/rc.local
#
systemctl enable rc-local
