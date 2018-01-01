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

## Platforms
### [Raspberry running pi-hole](iptables-raspberry.sh) - Simple statefull firewall for raspberry pi running [pi-hole](https://github.com/pi-hole/pi-hole)
