# Common syntax
  firewall-cmd [ action ]

# Firewalld Service Management
  --state               : get current state
  --reload              : soft reload firewalld service                         --complete-reload   : hard reload with interrupting connections
  --panic-on            : enable panic mode                                     --panic-off         : disable panic mode
  --query-panic         : query panic status mode

# Get Zone and Interfaces Status 
  --get-active-zones                : enum zones and attached interfaces        --set-default-zone=..         : set default zone
  --get-zone-of-interface=..        : get zone of specified interface           --zone=.. --list-interfaces   : enum interfaces of specified zone
  --zone=.. --list-all              : enum zone settings 

  --zone=.. --add-interface=..      : add interface to zone

# Ports and Service Management
  --get-services                    : enum available services                   --get-services --permanent          : get active services after reload
  --zone=.. --add-port=8080/tcp     : add port into zone                        --zone=.. --add-port=123-133/udp    : add ports interval
  --zone=.. --add-service=smtp      : add service                               --zone=.. --remove-service=ssh      : remove service

# Masquerade and Forwarding
  --zone=.. --query-masquerade      : query masquerade
  --zone=.. --add-masquearde        : add masquerade                            --zone=.. --remove-masquerade   : remove masquerade

  --zone=.. --add-forward-port=port=22:proto=tcp:toport=2022                    : packets intended to port 22 are now forwarded to 2022
  --zone=.. --add-forward-port=port=22:proto=tcp:toport=2022:toaddr=1.2.3.4     : packets intended to port 22 are now forwarded to 1.2.3.4:2022 
