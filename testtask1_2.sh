#!/bin/bash

sudo apt install docker-compose -y

sudo apt install snapd
#
sudo snap install cqlsh

echo '---
networks:
  cassandra-net:
    name: cassandra-net
    driver: macvlan
    driver_opts:
      parent: eth0.01
    ipam:
     config:
       - subnet: 192.168.1.0/24
         gateway: 192.168.1.254

services:
  cassandra-1:
    image: cassandra:latest
    container_name: cassandra-1
    restart: always
    ports:
      - "9042:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.200

  cassandra-2:
    image: cassandra:latest
    container_name: cassandra-2
    restart: always
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201

  cassandra-3:
    image: cassandra:latest
    container_name: cassandra-3
    restart: always
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202' > docker-compose.yml

sudo docker-compose up -d

sudo ip route change 192.168.1.0/24 via 192.168.1.254

sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE

sudo brctl addbr br0

sudo brctl addif br0 enp0s3

sudo brctl addif br0 eth0.01

sudo ip link up br0
