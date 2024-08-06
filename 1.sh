
#sudo ip link add vlan0 link eth0 type vlan id 10
#sudo ip link set vlan0 up
#sudo ip addr add 192.168.1.100/24 dev vlan0
#sudo docker network create -d ipvlan --subnet=192.168.1.0/24 --gateway=192.168.1.254 -o parent=vlan0 cassandra-net
#sudo docker run -d --name cassandra-1 --restart always -p 9042:9042 --net cassandra-net --ip 192.168.1.200 cassandra:latest
#sudo brctl addbr br0
#sudo brctl addif br0 vlan0
#sudo brctl addif br0 enp0s3
#sudo ip link set br0 up
#sudo ip route add default via 192.168.1.1 dev br0
#&&sudo ip route add 192.168.1.0/24 via 192.168.1.254 dev br0
#sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
#sudo brctl addbr br0
#sudo brctl addif br0 enp0s3
#sudo ip addr add 192.168.1.1/24 dev enp0s3
#sudo docker network create -d bridge --attachable --subnet=192.168.1.0/24 --gateway=192.168.1.254 cassandra-net
#sudo ip addr add 192.168.1.254/24 dev br0
#sudo ip route add default via 192.168.1.1 dev br0
#sudo systemctl restart docker

sudo ip link add br0 type bridge
sudo ip link set enp0s3 master br0
sudo ip addr add 192.168.1.66/24 dev br0
sudo docker network create -d bridge --attachable --subnet=192.168.1.0/24 --gateway=192.168.1.66 -o "com.docker.network.bridge.name"="br0" cassandra-net
sudo docker network connect cassandra-net br0

sudo systemctl restart docker
sudo ip link show br0
sudo docker network inspect cassandra-net
