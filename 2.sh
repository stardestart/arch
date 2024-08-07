#!/bin/bash

# Установка пакета snapd, который необходим для установки и управления пакетами snap

sudo apt install snapd


# Установка пакета cqlsh с помощью snap, который является интерфейсом командной строки для взаимодействия с базой данных Cassandra

sudo snap install cqlsh


echo -e "После установки cqlsh вы можете использовать его для подключения к кластеру Cassandra, который был развернут с помощью docker-compose. Например: cqlsh 192.168.1.200 -u \$user -p \$password"
