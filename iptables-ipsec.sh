#!/bin/bash

if [ $# != 2 ]; then
    echo "Script requires two parameters!"
    echo "$0 <iptables-path> <lan-cidr>"
    exit 1
fi

IPT="$1"
LAN="$2"

#########
# RESET #
#########
"$IPT" -t nat -F
"$IPT" -t nat -X
"$IPT" -t nat -F
"$IPT" -t mangle -F
"$IPT" -t mangle -X
"$IPT" -t mangle -F

##########
# POLICY #
##########
"$IPT" -P FORWARD DROP

##########
# CHAINS #
##########
# ACCEPT IN
"$IPT" -I in ! -s "$LAN" -d "$IPSEC" -m comment --comment "WAN -> IPSEC" -j ACCEPT
"$IPT" -I in -s "$LAN" -d "$IPSEC" -m comment --comment "LAN -> IPSEC" -j DROP

# ACCEPT OUT
"$IPT" -I out -s "$IPSEC" ! -d "$LAN" -m comment --comment "IPSEC -> WAN" -j ACCEPT
"$IPT" -I out -s "$IPSEC" -d "$LAN" -m comment --comment "IPSEC -> LAN" -j DROP

#########
# IPSEC #
#########
"$IPT" -N wan-to-vpn
"$IPT" -A wan-to-vpn -p udp --sport 53 -m state --state ESTABLISHED -m comment --comment "DNS UDP" -j in
"$IPT" -A wan-to-vpn -p tcp --sport 80 -m state --state ESTABLISHED -m comment --comment "HTTP" -j in
"$IPT" -A wan-to-vpn -p tcp --sport 443 -m state --state ESTABLISHED -m comment --comment "HTTPS" -j in
"$IPT" -A wan-to-vpn -p tcp --sport 993 -m state --state ESTABLISHED -m comment --comment "IMAP" -j in
"$IPT" -A wan-to-vpn -p tcp --sport 465 -m state --state ESTABLISHED -m comment --comment "SMTP" -j in
"$IPT" -A wan-to-vpn -m limit -j LOG --log-prefix "[wan->vpn]"
"$IPT" -A wan-to-vpn -j DROP

"$IPT" -N vpn-to-wan
"$IPT" -A vpn-to-wan -p udp --dport 53 -m state --state NEW,ESTABLISHED -m comment --comment "DNS UDP" -j out
"$IPT" -A vpn-to-wan -p tcp --dport 80 -m state --state NEW,ESTABLISHED -m comment --comment "HTTP" -j out
"$IPT" -A vpn-to-wan -p tcp --dport 443 -m state --state NEW,ESTABLISHED -m comment --comment "HTTPS" -j out
"$IPT" -A vpn-to-wan -p tcp --dport 993 -m state --state NEW,ESTABLISHED -m comment --comment "IMAP" -j out
"$IPT" -A vpn-to-wan -p tcp --dport 465 -m state --state NEW,ESTABLISHED -m comment --comment "SMTP" -j out
"$IPT" -A vpn-to-wan -m limit -j LOG --log-prefix "[vpn->wan]"
"$IPT" -A vpn-to-wan -j DROP

"$IPT" -N vpn-to-lan
"$IPT" -A vpn-to-lan -m limit -j LOG --log-prefix "[vpn->lan]"
"$IPT" -A vpn-to-lan -j DROP

"$IPT" -N lan-to-vpn
"$IPT" -A lan-to-vpn -m limit -j LOG --log-prefix "[lan->vpn]"
"$IPT" -A lan-to-vpn -j DROP
    
#######
# NAT #
#######
"$IPT" -t nat -A POSTROUTING -o p2p1 -s "$IPSEC" -j MASQUERADE

##########
# MANGLE #
##########
"$IPT" -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -s "$IPSEC" -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

###########
# FORWARD #
###########
"$IPT" -A FORWARD ! -s "$LAN" -d "$IPSEC" -m comment --comment "IPSec WAN -> VPN" -j wan-to-vpn
"$IPT" -A FORWARD -s "$IPSEC" ! -d "$LAN" -m comment --comment "IPSec VPN -> WAN" -j vpn-to-wan
"$IPT" -A FORWARD -s "$LAN" -d "$IPSEC" -m comment --comment "IPSec LAN -> VPN" -j lan-to-vpn
"$IPT" -A FORWARD -s "$IPSEC" -d "$LAN" -m comment --comment "IPSec VPN -> LAN" -j vpn-to-lan
"$IPT" -A FORWARD -m limit -j LOG --log-prefix "[FORWARD]"

#########
# RULES #
#########
"$IPT" -A INPUT -p udp --dport 500 -m state --state NEW,ESTABLISHED -m comment --comment "IPSec IKE" -j in
"$IPT" -A OUTPUT -p udp --sport 500 -m state --state ESTABLISHED -m comment --comment "IPSec IKE" -j out

"$IPT" -A INPUT -p udp --dport 4500 -m state --state NEW,ESTABLISHED -m comment --comment "IPSec IKE NAT" -j in
"$IPT" -A OUTPUT -p udp --sport 4500 -m state --state ESTABLISHED -m comment --comment "IPSec IKE NAT" -j out

"$IPT" -A INPUT -p esp -m state --state NEW,ESTABLISHED -m comment --comment "IPSec ESP" -j in
"$IPT" -A OUTPUT -p esp -m state --state RELATED,ESTABLISHED -m comment --comment "IPSec ESP" -j out

