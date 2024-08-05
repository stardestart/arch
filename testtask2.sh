#!/bin/bash

sudo apt install docker-compose -y
sudo apt install snapd
#
sudo snap install cqlsh

echo '---
networks:
  host-network:
    name: host-network
    driver: macvlan
    driver_opts:
      parent: enp0s3
    ipam:
     config:
       - subnet: 192.168.0.0/24
         gateway: 192.168.0.1
         ip_range: 192.168.0.192/27
         aux_addresses:
            router: 192.168.0.223

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
sudo ip link add docker-lan link enp0s3 type macvlan  mode bridge
sudo ip addr add 192.168.0.223/32 dev docker-lan
sudo ip link set docker-lan up
sudo ip route add 192.168.0.192/27 dev docker-lan
