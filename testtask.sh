#!/bin/bash
#
#sudo apt install docker-compose -y
#
#sudo apt install snapd -y
#
#sudo snap install cqlsh
#
echo '# Определение сети

networks:

  cassandra-net:

    driver: bridge


# Определение сервисов

services:

  # Сервис для узла Cassandra 1

  cass-db-1:

    # Использование последнего образа Cassandra

    image: cassandra:latest

    # Установка имени контейнера

    container_name: cass-db-1

    # Пропуск порта 9042 на хосте к порту 9042 в контейнере (для CQLSH)

    ports:

      - "9042:9042"

    # Подключение к сети cassandra-net

    networks:

      - cassandra-net


  # Сервис для узла Cassandra 2

  cass-db-2:

    # Установка имени контейнера

    container_name: cass-db-2

    # Использование последнего образа Cassandra

    image: cassandra:latest

    # Пропуск порта 9043 на хосте к порту 9042 в контейнере (для CQLSH)

    ports:

      - "9043:9042"

    # Подключение к сети cassandra-net

    networks:

      - cassandra-net


  # Сервис для узла Cassandra 3

  cass-db-3:

    # Установка имени контейнера

    container_name: cass-db-3

    # Использование последнего образа Cassandra

    image: cassandra:latest

    # Пропуск порта 9044 на хосте к порту 9042 в контейнере (для CQLSH)

    ports:

      - "9044:9042"

    # Подключение к сети cassandra-net

    networks:

      - cassandra-net' > docker-compose.yml
#
#sudo docker-compose up
