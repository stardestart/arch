#!/bin/bash

sudo apt install docker-compose -y

sudo apt install snapd
#
sudo snap install cqlsh

echo '---
networks:
  cassandra-net:
    name: cassandra-net
    driver: bridge
    ipam:
     config:
       - subnet: 172.16.0.0/24
         gateway: 172.16.0.254

services:
  cassandra-1:
    image: cassandra:latest
    container_name: cassandra-1
    restart: always
    ports:
      - "9042:9042"
    networks:
      cassandra-net:
        ipv4_address: 172.16.0.200

  cassandra-2:
    image: cassandra:latest
    container_name: cassandra-2
    restart: always
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 172.16.0.201

  cassandra-3
    image: cassandra:latest
    container_name: cassandra-3
    restart: always
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 172.16.0.202' > docker-compose.yml

sudo docker-compose up -d

sudo ip route change 172.16.0.0/24 via 172.16.0.254

sudo iptables -t nat -A POSTROUTING -s 172.16.0.0/24 -o enp0s3 -j MASQUERADE
