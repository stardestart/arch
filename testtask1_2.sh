#!/bin/bash


sudo apt install docker-compose -y


#sudo apt install snapd

#

#sudo snap install cqlsh

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


#sudo ip route add 192.168.1.0/24 via 192.168.1.254 dev br0


#sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
