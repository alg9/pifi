#!/bin/bash
# this script is based on the content of this post https://pimylifeup.com/raspberry-pi-wifi-bridge/
# and this post https://iceburn.medium.com/raspberry-pi-connected-to-wifi-of-wpa2-enterprise-ddd5a40c0b07
# and this one too https://www.raspberrypi.org/forums/viewtopic.php?t=247310

read -p 'SSID: ' VAR_SSID
read -p 'Username: ' VAR_USERNAME
read -p 'Password: ' VAR_PASSWORD

sudo apt-get -y install dnsmasq

#create wpa2 enterprise profile
sudo tee /etc/wpa_supplicant/wpa_supplicant.conf << END
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
        ssid="$VAR_SSID"
        key_mgmt=WPA-EAP
        eap=TTLS
        identity="$VAR_USERNAME"
        password="$VAR_PASSWORD"
        phase2="auth=MSCHAPV2"
}
END

sudo sed -i s/-nl80211,wext/-wext,nl80211/ /lib/dhcpcd/dhcpcd-hooks/10-wpa_supplicant

if ! grep -q 'routers=192.168.220.0' /etc/dhcpcd.conf  
then
# setup static address range for ethernet
sudo tee -a /etc/dhcpcd.conf << END
interface eth0
static ip_address=192.168.220.1/24
static routers=192.168.220.0
END
fi

sudo service dhcpcd restart

#set up dhcp 
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo tee /etc/dnsmasq.conf << END
interface=eth0       # Use interface eth0  
listen-address=192.168.220.1   # Specify the address to listen on  
bind-dynamic         # Bind to the interface
server=8.8.8.8       # Use Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Drop the non-routed address spaces.  
dhcp-range=192.168.220.50,192.168.220.150,12h # IP range and lease time 
END

# set up NAT
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"


#setup IPTABLES
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE  
sudo iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT 

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

if ! grep -q 'iptables-restore' /etc/rc.local 
then
sudo sed -i '/^exit 0/i iptables-restore < \/etc\/iptables.ipv4.nat' /etc/rc.local
fi

sudo service dnsmasq start


