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
ping -c3 192.168.1.200
ping -c3 192.168.1.201
ping -c3 192.168.1.202
#sudo ip link add br0 type bridge
#sudo ip addr add 192.168.1.100/24 brd 192.168.1.255 dev br0
#sudo ip link set br0 up
#sudo systemctl restart docker

#sudo ip link add cassandra-net type macvlan
#sudo ip addr add 172.16.1.200/24 brd 172.16.1.255 dev cassandra-net
#sudo ip addr add 172.16.1.201/24 brd 172.16.1.255 dev cassandra-net
#sudo ip addr add 172.16.1.202/24 brd 172.16.1.255 dev cassandra-net
#sudo ip link set cassandra-net up
# Запуск docker-compose в фоновом режиме
