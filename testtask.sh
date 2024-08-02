#!/bin/bash
#
#apt install docker-ce -y
#sudo apt install docker-compose -y
#
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#
chmod +x /usr/local/bin/docker-compose
#
#docker-compose
#
sudo apt install snapd -y
#
sudo snap install cqlsh
#
#systemctl status docker
#
echo 'networks:
  host-network:
    driver: bridge
    ipam:
     config:
       - subnet: 192.168.1.0/24
services:
  cass-db-1:
    image: cassandra:latest
    container_name: cass-db-1
    ports:
      - "9042:9042"
    networks:
      host-network:
        ipv4_address: 192.168.1.200

  cass-db-2:
    container_name: cass-db-2
    image: cassandra:latest
    ports:
      - "9043:9042"
    networks:
      host-network:
        ipv4_address: 192.168.1.201
    depends_on:
      - cass-db-1

  cass-db-3:
    container_name: cass-db-3
    image: cassandra:latest
    ports:
      - "9044:9042"
    networks:
      host-network:
        ipv4_address: 192.168.1.202
    depends_on:
      - cass-db-2' > docker-compose.yml
#
sudo docker-compose up -d
#
echo 'docker-compose up -d
exit 0' | sudo tee /etc/rc.local
#
sudo chmod +x /etc/rc.local
#
sudo systemctl enable rc-local
