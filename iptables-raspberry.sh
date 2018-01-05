#!/bin/bash

IPTABLES="/sbin/iptables"
LAN="192.168.1.0/24"
GITHUB="192.30.252.0/22"

#########
# CLEAN #
#########

"$IPTABLES" -F
"$IPTABLES" -X
"$IPTABLES" -F

##########
# POLICY #
##########
"$IPTABLES" -P INPUT DROP
"$IPTABLES" -P OUTPUT DROP
"$IPTABLES" -P FORWARD DROP

#########
# BLOCK #
#########
bash ./iptables-server-block-list.sh "$IPTABLES" "$LAN"

#########
# RULES #
#########

# DNS ICMP
"$IPTABLES" -A OUTPUT -p icmp --icmp-type 3/3 -d 8.8.8.8 -m comment --comment "Destination port unreachable Google DNS" -j DROP
"$IPTABLES" -A OUTPUT -p icmp --icmp-type 3/3 -d 8.8.4.4 -m comment --comment "Destination port unreachable Google DNS" -j DROP
"$IPTABLES" -A INPUT -p icmp --icmp-type 3/3 -s "$LAN" -m comment --comment "Destination port unreachable Router DNS Client" -j ACCEPT

# PI-hole
"$IPTABLES" -A INPUT -p tcp -s "$LAN" --dport 443 -m comment --comment "HTTPS PI-hole" -j REJECT
"$IPTABLES" -A INPUT -p udp -s "$LAN" --dport 443 -m comment --comment "HTTPS QUIC PI-hole" -j REJECT
"$IPTABLES" -A OUTPUT -p icmp --icmp-type 3/3 -d "$LAN" -m comment --comment "HTTPS QUIC PI-hole" -j ACCEPT

# Invalid
"$IPTABLES" -A INPUT -m conntrack --ctstate INVALID -j DROP
"$IPTABLES" -A OUTPUT -m conntrack --ctstate INVALID -j DROP

# IGMP
"$IPTABLES" -A INPUT -p igmp -s "$LAN" -d 224.0.0.0/4 -m comment --comment "IGMP" -j ACCEPT
"$IPTABLES" -A OUTPUT -p igmp -s "$LAN" -d 224.0.0.0/4 -m comment --comment "IGMP" -j ACCEPT

# DNS Server
"$IPTABLES" -A INPUT -p udp -s "$LAN" -d "$LAN" --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "DNS Server" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp -s "$LAN" --sport 53 -d "$LAN" -m conntrack --ctstate ESTABLISHED -m comment --comment "DNS Server" -j ACCEPT

# DNS
"$IPTABLES" -A INPUT -p udp -s 8.8.8.8 --sport 53 -m conntrack --ctstate ESTABLISHED -m comment --comment "Google DNS" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp -d 8.8.8.8 --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "Google DNS" -j ACCEPT
"$IPTABLES" -A INPUT -p udp -s 8.8.4.4 --sport 53 -m conntrack --ctstate ESTABLISHED -m comment --comment "Google DNS" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp -d 8.8.4.4 --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "Google DNS" -j ACCEPT

# SSH Server
"$IPTABLES" -A INPUT -p tcp -s "$LAN" --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "SSH Server" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp --sport 22 -d "$LAN" -m conntrack --ctstate ESTABLISHED -m comment --comment "SSH Server" -j ACCEPT

# HTTP Server
"$IPTABLES" -A INPUT -p tcp -s "$LAN" --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "HTTP Server" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp -d "$LAN" --sport 80 -m conntrack --ctstate ESTABLISHED -m comment --comment "HTTP Server" -j ACCEPT

# HTTP
"$IPTABLES" -A INPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -m comment --comment "HTTP" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "HTTP" -j ACCEPT

# NTP
"$IPTABLES" -A INPUT -p udp --sport 123 -m conntrack --ctstate ESTABLISHED -m comment --comment "NTP" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp --dport 123 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "NTP" -j ACCEPT

# mDNS
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 5353 --dport 5353 -m comment --comment "mDNS" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp -s "$LAN" --sport 5353 --dport 5353 -m comment --comment "mDNS" -j ACCEPT

# DHCP
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 67 --dport 68 -m comment --comment "DHCP" -j ACCEPT
"$IPTABLES" -A OUTPUT -p udp --sport 68 --dport 67 -m comment --comment "DHCP" -j ACCEPT
"$IPTABLES" -A INPUT -p udp --sport 68 --dport 67 -m comment --comment "DHCP Client" -j DROP

# Github
"$IPTABLES" -A INPUT -p tcp -s "$GITHUB" --sport 22 -m conntrack --ctstate ESTABLISHED -m comment --comment "Github" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp -d "$GITHUB" --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "Github" -j ACCEPT
"$IPTABLES" -A INPUT -p tcp -s "$GITHUB" --sport 443 -m conntrack --ctstate ESTABLISHED -m comment --comment "PI-hole Github Update" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp -d "$GITHUB" --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "PI-hole Github Update" -j ACCEPT

# Loopback
"$IPTABLES" -A INPUT -i lo -m comment --comment "Loopback" -j ACCEPT
"$IPTABLES" -A OUTPUT -o lo -m comment --comment "Loopback" -j ACCEPT

# LOG
"$IPTABLES" -A INPUT -j LOG --log-prefix "[INPUT]"
"$IPTABLES" -A OUTPUT -j LOG --log-prefix "[OUTPUT]"
