#!/bin/bash
#
#sudo apt install docker-compose -y
#
#sudo apt install snapd -y
#
#sudo snap install cqlsh
#
echo '---
services:
  cassandra1:
    image: cassandra:latest
    container_name: cassandra1
    ports:
      - "9042:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.200
      - CASSANDRA_SEEDS=192.168.1.200
    networks:
      - cassandra-net

  cassandra2:
    image: cassandra:latest
    container_name: cassandra2
    ports:
      - "9043:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.201
      - CASSANDRA_SEEDS=192.168.1.200,192.168.1.201
    networks:
      - cassandra-net

  cassandra3:
    image: cassandra:latest
    container_name: cassandra3
    ports:
      - "9044:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.202
      - CASSANDRA_SEEDS=192.168.1.200,192.168.1.201,192.168.1.202
    networks:
      - cassandra-net

networks:
  cassandra-net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
        ' > docker-compose.yml

#
#sudo docker-compose up
