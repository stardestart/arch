sudo ip addr add 192.168.1.100/24 dev eth0.0
sudo docker network create -d ipvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=eth0.0 cassandra-net
#sudo docker run -d --name cassandra-1 --restart always -p 9042:9042 --net cassandra-net --ip 192.168.1.200 cassandra:latest
sudo brctl addbr br0
sudo brctl addif br0 eth0.0
sudo brctl addif br0 enp0s3
sudo ip link set br0 up
sudo ip route add 192.168.1.0/24 via 192.168.1.254 dev br0
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
