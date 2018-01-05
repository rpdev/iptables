#!/bin/bash

if [ $# != 2 ]; then
    echo "Script requires two parameters!"
    echo "$0 <iptables-path> <lan-cidr>"
    exit 1
fi

IPTABLES="$1"
LAN="$2"

"$IPTABLES" -I INPUT -p udp --sport 17500 --dport 17500 -m comment --comment "Dropbox" -j DROP
"$IPTABLES" -I INPUT -p udp --sport 57621 --dport 57621 -m comment --comment "Spotify" -j DROP
"$IPTABLES" -I INPUT -p udp -s "$LAN" --sport 137 --dport 137 -m comment --comment "NetBIOS Name Service" -j DROP
"$IPTABLES" -I INPUT -p udp -s "$LAN" --sport 138 --dport 138 -m comment --comment "NetBIOS Datagram Service" -j DROP
"$IPTABLES" -I INPUT -p udp -s "$LAN" --sport 27031:27036 --dport 27031:27036 -m comment --comment "Steam, In-Home Streaming" -j DROP
