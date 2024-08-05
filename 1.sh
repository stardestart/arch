sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -o br-4cc67dcd34a0 -j MASQUERADE
sudo iptables -A FORWARD -i br-4cc67dcd34a0 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o br-4cc67dcd34a0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1
