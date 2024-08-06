#!/bin/bash


# Установка docker-compose, если он еще не установлен

sudo apt install docker-compose -y

echo -e "\033[47m\033[30mВведите имя пользователя cassandra-1:\033[0m\033[32m";read -p ">" username1
echo -e "\033[47m\033[30mВведите пароль для "$username1" cassandra-1:\033[0m\033[32m";read -p ">" passuser1
echo -e "\033[47m\033[30mВведите имя пользователя cassandra-2:\033[0m\033[32m";read -p ">" username2
echo -e "\033[47m\033[30mВведите пароль для "$username2" cassandra-2:\033[0m\033[32m";read -p ">" passuser2
echo -e "\033[47m\033[30mВведите имя пользователя cassandra-3:\033[0m\033[32m";read -p ">" username3
echo -e "\033[47m\033[30mВведите пароль для "$username3" cassandra-3:\033[0m\033[32m";read -p ">" passuser3

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
      username: '$username1'
      password: '$passuser1'

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
      username: '$username2'
      password: '$passuser2'

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
      username: '$username3'
      password: '$passuser3'

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
