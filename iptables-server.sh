#!/bin/bash

if [ $# != 1 ]; then
    echo "$0 requires ssh port as parameter"
    exit 1
fi

SSH_PORT="$1"
IPTABLES="/sbin/iptables"
LAN="192.168.1.0/24"

#########
# RESET #
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

##########
# CHAINS #
##########
# ACCEPT IN
"$IPTABLES" -N in
"$IPTABLES" -A in -s "$LAN" -d "$LAN" -m comment --comment "LAN -> LAN" -j ACCEPT
"$IPTABLES" -A in -m comment --comment "WAN -> LAN" -j ACCEPT

# ACCEPT OUT
"$IPTABLES" -N out
"$IPTABLES" -A out -s "$LAN" -d "$LAN" -m comment --comment "LAN -> LAN"  -j ACCEPT
"$IPTABLES" -A out -m comment --comment "LAN -> WAN" -j ACCEPT

#########
# BLOCK #
#########
bash ./iptables-server-block-list.sh "$IPTABLES" "$LAN"

#########
# RULES #
#########

# DNS UDP
"$IPTABLES" -A INPUT -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -m comment --comment "DNS UDP" -j in
"$IPTABLES" -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "DNS UDP" -j out

# DNS TCP
"$IPTABLES" -A INPUT -p tcp --sport 53 -m conntrack --ctstate ESTABLISHED -m comment --comment "DNS TCP" -j in
"$IPTABLES" -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "DNS TCP" -j out

# DHCP
"$IPTABLES" -A INPUT -p udp -s "$LAN" --sport 67 --dport 68 -m comment --comment "DHCP" -j in
"$IPTABLES" -A OUTPUT -p udp --sport 68 --dport 67 -m comment --comment "DHCP" -j out

# NTP
"$IPTABLES" -A INPUT -p udp --sport 123 -m conntrack --ctstate ESTABLISHED -m comment --comment "NTP" -j in
"$IPTABLES" -A OUTPUT -p udp --dport 123 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "NTP" -j out

# HTTP
"$IPTABLES" -A INPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -m comment --comment "HTTP" -j in
"$IPTABLES" -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "HTTP" -j out

# HTTPS
"$IPTABLES" -A INPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -m comment --comment "HTTPS" -j in
"$IPTABLES" -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "HTTPS" -j out

# SSH
"$IPTABLES" -A INPUT -p tcp -s "$LAN" -d "$LAN" --dport "$SSH_PORT" -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "SSH" -j in
"$IPTABLES" -A OUTPUT -p tcp -s "$LAN" -d "$LAN" --sport "$SSH_PORT" -m conntrack --ctstate ESTABLISHED -m comment --comment "SSH" -j out

# SMTPS
"$IPTABLES" -A INPUT -p tcp --sport 465 -m conntrack --ctstate ESTABLISHED -m comment --comment "SMTP TLS/SSL" -j in
"$IPTABLES" -A OUTPUT -p tcp --dport 465 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "SMTP TLS/SSL" -j out

# SMTP
"$IPTABLES" -A INPUT -p tcp --sport 587 -m conntrack --ctstate ESTABLISHED -m comment --comment "SMTP" -j in
"$IPTABLES" -A OUTPUT -p tcp --dport 587 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "SMTP" -j out

# DLNA
"$IPTABLES" -A INPUT -p tcp -s "$LAN" -d "$LAN" --dport 8200 -m conntrack --ctstate NEW,ESTABLISHED -m comment --comment "DLNA" -j in
"$IPTABLES" -A OUTPUT -p tcp -s "$LAN" --sport 8200 -d "$LAN" -m conntrack --ctstate ESTABLISHED -m comment --comment "DLNA" -j out
"$IPTABLES" -A INPUT -p udp -s "$LAN" -d "$LAN" --dport 1900 -m pkttype --pkt-type broadcast -m comment --comment "DLNA" -j in
"$IPTABLES" -A OUTPUT -p udp -s "$LAN" --sport 1900 -m pkttype --pkt-type broadcast -m comment --comment "DLNA" -j out

# Loopback
"$IPTABLES" -A INPUT -i lo -j ACCEPT
"$IPTABLES" -A OUTPUT -o lo -j ACCEPT

# LOG
"$IPTABLES" -A INPUT -j LOG --log-prefix "[INPUT]"
"$IPTABLES" -A OUTPUT -j LOG --log-prefix "[OUTPUT]"
