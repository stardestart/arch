sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -o enp0s3 -j MASQUERADE
