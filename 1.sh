sudo ip link set lo down
sudo brctl addbr br0
sudo brctl addif br0 enp0s3
sudo brctl addif br0 br-77cf37c99627
sudo ip link up br0
#
#sudo iptables -A FORWARD -i br-4d9b06be0aee -o enp0s3 -j ACCEPT
#sudo iptables -A FORWARD -i enp0s3 -o br-4d9b06be0aee -j ACCEPT
#sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
#sudo sysctl -w net.ipv4.ip_forward=1
#
#sudo ip route add 192.168.0.0/24 via 192.168.1.254 dev br-4d9b06be0aee
#sudo ip route add 192.168.1.0/24 via 192.168.0.1 dev enp0s3
