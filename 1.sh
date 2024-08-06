#!/bin/bash


# Установка docker-compose, если он еще не установлен

sudo apt install docker-compose -y


# Создание файла docker-compose.yml с конфигурацией для развертки кластера Cassandra

echo '---
# Описание сервисов, которые будут развернуты
services:

  # Первый экземпляр Cassandra
  cassandra-1:

    # Используемый образ Cassandra
    image: cassandra:latest

    # Перезапуск контейнера в случае его падения
    restart: always

    # Порт, на котором будет доступен контейнер (9042 - стандартный порт Cassandra)
    ports:
      - "9042:9042"

    # Сеть, в которой будет работать контейнер
    networks:
      cassandra-net:

        # IP-адрес, который будет присвоен контейнеру
        ipv4_address: 192.168.1.200

    # SSH доступ
    ssh:

      # Порт SSH
      port: 22

      # Имя пользователя и пароль для SSH
      username: cassandra
      password: cassandra

  # Второй экземпляр Cassandra
  cassandra-2:
    image: cassandra:latest
    restart: always
    ports:
      - "9043:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201
    ssh:
      port: 22
      username: cassandra
      password: cassandra

  # Третий экземпляр Cassandra
  cassandra-3:
    image: cassandra:latest
    restart: always
    ports:
      - "9044:9042"
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202
    ssh:
      port: 22
      username: cassandra
      password: cassandra

# Описание сетей, которые будут использоваться
networks:

  # Сеть для кластера Cassandra
  cassandra-net:

    # Драйвер сети (в данном случае - ipvlan)
    driver: ipvlan

    # Опции драйвера (в данном случае - родительский интерфейс enp0s3)
    driver_opts:
      parent: enp0s3

    # Настройки IP-адресов для сети
    ipam:

      # Драйвер настройки IP-адресов (в данном случае - default)
      driver: default

      # Конфигурация настройки IP-адресов
      config:

        # Подсеть и шлюз для сети
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.66' > docker-compose.yml


# Запуск контейнеров в фоновом режиме

sudo docker-compose up -d
