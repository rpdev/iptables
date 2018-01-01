#!/bin/bash

IPTABLES="/sbin/iptables"
LAN="192.168.1.0/24"

#########
# CLEAN #
#########

"$IPTABLES" -F
"$IPTABLES" -X
"$IPTABLES" -F
"$IPTABLES" -P INPUT DROP
"$IPTABLES" -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
"$IPTABLES" -A INPUT -i lo -j ACCEPT
"$IPTABLES" -P OUTPUT ACCEPT

#########
# RULES #
#########

# Block
"$IPTABLES" -A INPUT -p udp --sport 17500 --dport 17500 -m comment --comment "Dropbox" -j DROP
"$IPTABLES" -A INPUT -p udp --sport 57621 --dport 57621 -m comment --comment "Spotify" -j DROP
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 137 --dport 137 -m comment --comment "NetBIOS Name Service" -j DROP
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 138 --dport 138 -m comment --comment "NetBIOS Datagram Service" -j DROP
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 27031:27036 --dport 27031:27036 -m comment --comment "Steam, In-Home Streaming" -j DROP

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
"$IPTABLES" -A INPUT -p tcp -s github.com --sport 22 -m conntrack --ctstate ESTABLISHED -m comment --comment "Github" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp -d github.com --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "Github" -j ACCEPT
"$IPTABLES" -A INPUT -p tcp -s github.com --sport 443 -m conntrack --ctstate ESTABLISHED -m comment --comment "PI-hole Github Update" -j ACCEPT
"$IPTABLES" -A OUTPUT -p tcp -d github.com --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "PI-hole Github Update" -j ACCEPT

# Loopback
"$IPTABLES" -A INPUT -i lo -m comment --comment "Loopback" -j ACCEPT
"$IPTABLES" -A OUTPUT -o lo -m comment --comment "Loopback" -j ACCEPT

# LOG
"$IPTABLES" -A INPUT -j LOG --log-prefix "[INPUT]"
"$IPTABLES" -A OUTPUT -j LOG --log-prefix "[OUTPUT]"

##########
# POLICY #
##########
"$IPTABLES" -P INPUT DROP
"$IPTABLES" -P OUTPUT DROP
"$IPTABLES" -P FORWARD DROP

############
# CLEAN UP #
############
"$IPTABLES" -D INPUT 1
"$IPTABLES" -D INPUT 1
