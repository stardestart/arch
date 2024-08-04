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

  cassandra-2:
    image: cassandra:latest
    container_name: cassandra-2
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201

  cassandra-3:
    image: cassandra:latest
    container_name: cassandra-3
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202

networks:
  cassandra-net:
    name: cassandra-net
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.197' > docker-compose.yml

sudo docker network create --driver bridge --gateway 192.168.1.197 --subnet 192.168.1.0/24 cassandra-net
#
#sudo docker-compose up
