#!/bin/bash
clear

HOST=""
USER=""
HUB=""
BRIDGE=""
SE_PASSWORD=""
 
 
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
 
 
echo -n "Enter Server IP: "
read HOST
echo -n "Set Virtual Hub: "
read HUB
echo -n "Set ${HUB} Hub Username: "
read USER
echo -n "Set ${HOST} Server Password: "
read SE_PASSWORD
echo " "
echo "Have some coffee while waiting for this to finish."
echo " "
yum upgrade
yum -y groupinstall "Development Tools"
yum -y install gcc zlib-devel openssl-devel readline-devel ncurses-devel wget tar dnsmasq net-tools iptables-services system-config-firewall-tui nano iptables-services
systemctl disable firewalld
systemctl stop firewalld
systemctl status firewalld
service iptables save
service iptables stop
chkconfig iptables off
cd /usr/local
wget http://www.softether-download.com/files/softether/v4.25-9656-rtm-2018.01.15-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.25-9656-rtm-2018.01.15-linux-x64-64bit.tar.g
tar xzvf softether-vpnserver-v4.25-9656-rtm-2018.01.15-linux-x64-64bit.tar.gz
cd /usr/local/vpnserver
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver
sudo make
 
echo '#!/bin/sh
# chkconfig: 2345 99 01
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=192.168.7.1
TAP_ADAPTER='tap_soft'
 
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
sleep 3
sleep 1
ifconfig $TAP_ADAPTER $TAP_ADDR
service dnsmasq start
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
sleep 1
ifconfig $TAP_ADAPTER $TAP_ADDR
service dnsmasq restart
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0' > /etc/init.d/vpnserver
#
chmod +x /etc/init.d/vpnserver
#
/etc/init.d/vpnserver start
systemctl enable vpnserver
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
TARGET="/usr/local/"
${TARGET}vpnserver/vpncmd localhost /SERVER /CMD ServerPasswordSet ${SE_PASSWORD}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubCreate ${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserCreate ${USER} /GROUP:none /REALNAME:none /NOTE:none
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserAnonymousSet ${USER}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:vpn /DEFAULTHUB:${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubDelete DEFAULT
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD BridgeCreate /DEVICE:"soft" /TAP:yes ${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD VpnOverIcmpDnsEnable /ICMP:yes /DNS:yes
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 53
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 137
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 500
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 921
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 4500
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 4000
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 40000
cd ..
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
service vpnserver stop
#
echo interface=tap_soft >> /etc/dnsmasq.conf
echo dhcp-range=tap_soft,192.168.7.0,192.168.7.254,12h >> /etc/dnsmasq.conf
echo dhcp-option=tap_soft,3,192.168.7.1 >> /etc/dnsmasq.conf
echo port=0 >> /etc/dnsmasq.conf
echo dhcp-option=option:dns-server,8.8.8.8,8.8.4.4 >> /etc/dnsmasq.conf
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/ipv4_forwarding.conf
#
cat /etc/sysctl.d/ipv4_forwarding.conf
#
sysctl --system
service dnsmasq restart && service vpnserver restart
#
yum install bind-utils
HOST=${HOST}
iptables -t nat -A POSTROUTING -s 192.168.7.0/24 -j SNAT --to-source ${HOST}
iptables -A INPUT -i eth0 -p tcp --destination-port 53 -s ${HOST} -j DROP
iptables -A INPUT -i eth0 -p tcp --destination-port 443 -s ${HOST} -j DROP
iptables -A INPUT -i eth0 -p tcp --destination-port 80 -s ${HOST} -j DROP
iptables -A INPUT -i eth0 -p tcp --destination-port 22 -s ${HOST} -j DROP
/etc/init.d/vpnserver restart
service vpnserver stop
HOST=${HOST}
service dnsmasq restart && service vpnserver restart
HOST=${HOST}
iptables -t nat -A POSTROUTING -s 192.168.7.0/24 -j SNAT --to-source ${HOST}
/etc/init.d/vpnserver restart
echo "Softether server configuration has been done!"
echo " "
echo "Host: ${HOST}"
echo "Virtual Hub: ${HUB}"
echo "Port: 443, 53, 137"
echo "Username: ${USER}"
echo "Server Password : ${SE_PASSWORD}"
echo " "
