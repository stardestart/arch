#!/bin/bash
#
#sudo apt install docker-compose -y
#
#sudo apt install snapd -y
#
#sudo snap install cqlsh
#
echo '---
version: '3'

services:
  cassandra-1:
    image: cassandra:3.11
    container_name: cassandra-1
    ports:
      - "192.168.1.200:9042:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.200
      - CASSANDRA_LISTEN_ADDRESS=192.168.1.200
      - CASSANDRA_RPC_ADDRESS=192.168.1.200
    volumes:
      -./cassandra-1.yaml:/etc/cassandra/cassandra.yaml:ro

  cassandra-2:
    image: cassandra:3.11
    container_name: cassandra-2
    ports:
      - "192.168.1.201:9042:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.201
      - CASSANDRA_LISTEN_ADDRESS=192.168.1.201
      - CASSANDRA_RPC_ADDRESS=192.168.1.201
    volumes:
      -./cassandra-2.yaml:/etc/cassandra/cassandra.yaml:ro

  cassandra-3:
    image: cassandra:3.11
    container_name: cassandra-3
    ports:
      - "192.168.1.202:9042:9042"
    environment:
      - CASSANDRA_BROADCAST_ADDRESS=192.168.1.202
      - CASSANDRA_LISTEN_ADDRESS=192.168.1.202
      - CASSANDRA_RPC_ADDRESS=192.168.1.202
    volumes:
      -./cassandra-3.yaml:/etc/cassandra/cassandra.yaml:ro' > docker-compose.yml
echo '---
cluster_name: my_cluster
seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "192.168.1.200,192.168.1.201,192.168.1.202"
listen_address: ${CASSANDRA_LISTEN_ADDRESS}
rpc_address: ${CASSANDRA_RPC_ADDRESS}
endpoint_snitch: SimpleSnitch
data_file_directories:
  - /var/lib/cassandra/data
commitlog_directory: /var/lib/cassandra/commitlog
saved_caches_directory: /var/lib/cassandra/saved_caches' > cassandra-1.yaml
cp cassandra-1.yaml cassandra-2.yaml
cp cassandra-1.yaml cassandra-3.yaml

#
#sudo docker-compose up
