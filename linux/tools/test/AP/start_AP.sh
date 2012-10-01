#! /bin/bash

### see ###
# http://linuxwireless.org/en/users/Documentation/hostapd

### required packages: ###
# sudo apt-get install hostapd dhcp3-server

### get info: ###
# grep dhcpd /var/log/syslog
# grep hostapd /var/log/syslog


echo "--> Writting DHCP server config"
sudo cp /secm/T60/AP/etc.default.isc-dhcp-server /etc/default/isc-dhcp-servers
sudo cp /secm/T60/AP/etc.dhcp.dhcpd.conf /etc/dhcp/dhcpd.conf

echo "--> Setting ip for wlan0"
sudo ifconfig wlan0 10.0.0.1 netmask 255.255.255.0 up

echo "--> Enabling NAT and forwarding"
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat --flush
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE # enable nat

echo "--> Starting DHCP server"
sudo service isc-dhcp-server start
echo "--> Starting hostapd"
sudo hostapd -B /secm/T60/AP/hostapd.conf

echo "--> Reducing transmit power"
sudo iwconfig wlan0 txpower 5

echo "--> done"
