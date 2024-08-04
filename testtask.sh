#!/bin/bash
#
sudo apt install docker-compose -y
#
#sudo apt install snapd -y
#
#sudo snap install cqlsh
#
echo '---
services:
  cassandra-1:
    image: cassandra:latest
    container_name: cassandra-1
    ports:
      - "9042:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.200
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.200
      - CASSANDRA_SEEDS=192.168.1.200,192.168.1.201,192.168.1.202

  cassandra-2:
    image: cassandra:latest
    container_name: cassandra-2
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.201
      - CASSANDRA_SEEDS=192.168.1.200,192.168.1.201,192.168.1.202

  cassandra-3:
    image: cassandra:latest
    container_name: cassandra-3
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.202
      - CASSANDRA_SEEDS=192.168.1.200,192.168.1.201,192.168.1.202

networks:
  cassandra-net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1' > docker-compose.yml
sudo mkdir /etc/docker/
echo '{
  "bip": "192.168.1.1/24"
}' | sudo tee /etc/docker/daemon.json
#
sudo systemctl restart docker
sudo docker-compose up -d
