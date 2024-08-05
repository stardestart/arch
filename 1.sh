sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -o br-cbf455d29d99 -j MASQUERADE
sudo iptables -A FORWARD -i br-cbf455d29d99 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o br-cbf455d29d99 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1
