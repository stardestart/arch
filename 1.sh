#sudo docker ps -a
#sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cassandra-1
#sudo ip route add 172.16.1.0/24 via 172.16.1.200
echo "Test text" | mail -s "Test title" stardestart@gmail.com
sudo docker-compose logs cassandra-1
sudo docker-compose logs cassandra-2
sudo docker-compose logs cassandra-3
sudo docker-compose ps
sudo journalctl -u docker
sudo journalctl -b
