sudo docker network create -d ipvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=br0 cassandra-net
