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
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1

# Определение сервисов
services:
  # Сервис для узла Cassandra 1
  cass-db-1:
    # Использование последнего образа Cassandra
    image: cassandra:latest
    # Установка имени контейнера
    container_name: cass-db-1
    #Cassandra слушает на правильном IP-адресе
    volumes:
      - ./cassandra-1.yaml:/etc/cassandra/cassandra.yaml
    # Пропуск порта 9042 на хосте к порту 9042 в контейнере (для CQLSH)
    ports:
      - "9042:9042"
    # Подключение к сети cassandra-net
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.200

  # Сервис для узла Cassandra 2
  cass-db-2:
    # Установка имени контейнера
    container_name: cass-db-2
    # Использование последнего образа Cassandra
    image: cassandra:latest
    #Cassandra слушает на правильном IP-адресе
    volumes:
      - ./cassandra-2.yaml:/etc/cassandra/cassandra.yaml
    # Пропуск порта 9043 на хосте к порту 9042 в контейнере (для CQLSH)
    ports:
      - "9043:9042"
    # Подключение к сети cassandra-net
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.201

  # Сервис для узла Cassandra 3
  cass-db-3:
    # Установка имени контейнера
    container_name: cass-db-3
    # Использование последнего образа Cassandra
    image: cassandra:latest
    #Cassandra слушает на правильном IP-адресе
    volumes:
      - ./cassandra-3.yaml:/etc/cassandra/cassandra.yaml
    # Пропуск порта 9044 на хосте к порту 9042 в контейнере (для CQLSH)
    ports:
      - "9044:9042"
    # Подключение к сети cassandra-net
    networks:
      cassandra-net:
        ipv4_address: 192.168.1.202' > docker-compose.yml
echo '#Cassandra-1 слушает на правильном IP-адресе
cassandra:
  listen_address: 192.168.1.200' > cassandra-1.yaml
echo '#Cassandra-1 слушает на правильном IP-адресе
cassandra:
  listen_address: 192.168.1.201' > cassandra-2.yaml
echo '#Cassandra-1 слушает на правильном IP-адресе
cassandra:
  listen_address: 192.168.1.202' > cassandra-3.yaml

#
#sudo docker-compose up
