#!/bin/bash

sudo apt install docker-compose -y

echo '---
services:
  cassandra-1:
    image: cassandra:latest
    restart: always
    ports:
      - "9042:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.200

  cassandra-2:
    image: cassandra:latest
    restart: always
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201

  cassandra-3:
    image: cassandra:latest
    restart: always
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202

networks:
  cassandra-net:
    driver: ipvlan
    driver_opts:
      parent: enp0s3
    ipam:
      driver: default
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.66' > docker-compose.yml

sudo docker-compose up -d
