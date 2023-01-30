pacman -S openvpn strongswan iptables --noconfirm
rm /etc/ipsec.conf
mkdir -p ~/cert/{cacerts,certs,private}
pki --gen --type rsa --size 4096 --outform pem > ~/cert/private/ca-key.pem
pki --self --ca --lifetime 3650 --in ~/cert/private/ca-key.pem --type rsa --dn "CN=VPN Server" --outform pem > ~/cert/cacerts/ca-cert.pem
pki --gen --type rsa --size 4096 --outform pem > ~/cert/private/server-key.pem
pki --pub --in ~/cert/private/server-key.pem --type rsa | pki --issue --lifetime 1825 --cacert ~/cert/cacerts/ca-cert.pem --cakey ~/cert/private/ca-key.pem --dn "CN=1217581-cn58105.tw1.ru" --san 1217581-cn58105.tw1.ru --flag serverAuth --flag ikeIntermediate --outform pem >  ~/cert/certs/server-cert.pem 
cp -r ~/cert/* /etc/ipsec.d/
mv /etc/ipsec.conf{,.original}
echo 'config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=@1217581-cn58105.tw1.ru
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity
    ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!' > /etc/ipsec.conf
systemctl start strongswan-starter
systemctl enable strongswan-starter
systemctl restart strongswan-starter
rm -rf ~/cert
echo 'net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.ip_no_pmtu_disc = 1' > /etc/sysctl.d/99-sysctl.conf
sysctl -p
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j sudo ACCEPT iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
netfilter-persistent save 
netfilter-persistent reload
systemctl stop iptables
systemctl enable iptables
systemctl start iptables
iptables -S
