# iptables

## Apply rules
```bash
sudo ./iptables-<rules>.sh
```

### Make iptables persist between reboot (with counters)
```bash
chmod u+x iptablesload iptablessave
sudo cp iptablesload /etc/network/if-pre-up.d/
sudo cp iptablessave /etc/network/if-post-down.d/
```

## Rules
### [Raspberry running pi-hole](iptables-raspberry.sh) - Simple statefull firewall for raspberry pi running [pi-hole](https://github.com/pi-hole/pi-hole)

### [DLNA Server](iptables-server.sh) - Simple statefull firewall for server running [DLNA](https://en.wikipedia.org/wiki/Digital_Living_Network_Alliance), with support for sending email.

## Other
### [Block list](iptables-server-block-list.sh) - Contains block list for server
