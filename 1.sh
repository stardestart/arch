sudo docker network create -d ipvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=br0 cassandra-net
sudo docker run -d --name cassandra-1 --restart always -p 9042:9042 --net cassandra-net --ip 192.168.1.200 cassandra:latest
