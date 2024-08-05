sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -o br-4cc67dcd34a0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
