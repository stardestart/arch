#!/bin/bash
#
#sudo apt install docker-compose -y
#
#sudo apt install snapd -y
#
#sudo snap install cqlsh
#
echo 'networks:
  cassandra-net:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.1.0/24

services:
  cass-db-1:
    image: cassandra:latest
    container_name: cass-db-1
    ports:
      - "9042:9042" # for cqlsh
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.200

  cass-db-2:
    container_name: cass-db-2
    image: cassandra:latest
    ports:
      - "9043:9042" # for cqlsh
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201
    depends_on:
      - cass-db-1

  cass-db-3:
    container_name: cass-db-3
    image: cassandra:latest
    ports:
      - "9044:9042" # for cqlsh
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202
    depends_on:
      - cass-db-2' > docker-compose.yml
#
#sudo docker-compose up
