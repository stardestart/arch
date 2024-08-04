#!/bin/bash
#
sudo apt install docker-compose -y
#
sudo apt install snapd -y
#
sudo snap install cqlsh
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
        ipv4_address: 10.10.10.200
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=10.10.10.200
      - CASSANDRA_SEEDS=10.10.10.200,10.10.10.201,10.10.10.202

  cassandra-2:
    image: cassandra:latest
    container_name: cassandra-2
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 10.10.10.201
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=10.10.10.201
      - CASSANDRA_SEEDS=10.10.10.200,10.10.10.201,10.10.10.202

  cassandra-3:
    image: cassandra:latest
    container_name: cassandra-3
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 10.10.10.202
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=10.10.10.202
      - CASSANDRA_SEEDS=10.10.10.200,10.10.10.201,10.10.10.202

networks:
  cassandra-net:
    driver: bridge
    name: cassandra-net
    ipam:
      driver: default
      config:
        - subnet: 10.10.10.0/24
          gateway: 10.10.10.1' > docker-compose.yml
sudo docker-compose up -d
sudo mkdir /etc/cassandra/
echo '[connection]
hostname = 10.10.10.200
port = 9042' | sudo tee /etc/cassandra/cqlshrc
sudo docker-compose exec cassandra-1 cqlsh -f /etc/cassandra/cqlshrc
#
