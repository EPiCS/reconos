#! /bin/bash

echo "--> Stopping DHCP server"
sudo service isc-dhcp-server stop

echo "--> Killing hostapd"
sudo killall hostapd

echo "--> Disabling NAT and forwarding"
sudo iptables -P FORWARD DROP
sudo sysctl -w net.ipv4.ip_forward=0
sudo iptables -t nat --flush

echo "--> Resetting IP of wlan0"
sudo ifconfig wlan0 0.0.0.0 up

echo "--> done"