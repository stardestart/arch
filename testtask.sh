#!/bin/bash

sudo apt install docker-compose -y
# Установка docker-compose с помощью apt, флаг -y указывает на автоматическое подтверждение установки

echo '---
networks:
  host-network:
    name: host-network
    driver: bridge
    ipam:
     config:
       - subnet: 192.168.1.0/24
# Определение сети host-network с диапазоном адресов 192.168.1.0/24

services:
  cass-db-seed:
    image: cassandra:5
    container_name: cass-db-seed
    ports:
      - 9042:9042
    networks:
      host-network:
        ipv4_address: 192.168.1.200
    restart: always
# Определение сервиса cass-db-seed, который будет использовать образ cassandra:5, порт 9042 и адрес 192.168.1.200

  cass-db-1:
    container_name: cass-db-1
    image: cassandra:5
    ports:
      - 9043:9042
    environment:
      - CASSANDRA_SEEDS=cass-db-seed
    networks:
      host-network:
        ipv4_address: 192.168.1.201
    depends_on:
      - cass-db-seed
    restart: always
# Определение сервиса cass-db-1, который будет использовать образ cassandra:5, порт 9043, адрес 192.168.1.201 и зависеть от сервиса cass-db-seed

  cass-db-2:
    container_name: cass-db-2
    image: cassandra:5
    ports:
      - 9044:9042
    environment:
      - CASSANDRA_SEEDS=cass-db-seed
    networks:
      host-network:
        ipv4_address: 192.168.1.202
    depends_on:
      - cass-db-seed
    restart: always
# Определение сервиса cass-db-2, который будет использовать образ cassandra:5, порт 9044, адрес 192.168.1.202 и зависеть от сервиса cass-db-seed
' > docker-compose.yml

sudo docker-compose up -d
# Запуск docker-compose в фоновом режиме
