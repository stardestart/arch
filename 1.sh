#sudo docker ps -a
sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cassandra-1
#sudo ip route add 172.16.1.0/24 via 172.16.1.200
