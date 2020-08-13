#!/bin/sh
while true; do
  if ! route | grep  ppp0 > /dev/null; then
    # wait for 5 sec to make sure ppp0 is avalible again in case of diconnection
    echo "reconnector: wait for 5 secs";sleep 5
    # try to connect vpn if it's not connected
    xl2tpd-control -c /var/run/xl2tpd/l2tp-control connect 'myVPN'
    # Wait for vpn to create ppp0 network interface
    while ! route | grep ppp0 > /dev/null; do echo "reconnector: waiting for ppp0"; sleep 1; done

    # Get Default Gateway
    DEAFULT_ROUTE_IP=$(route | grep eth0 | grep default | awk '{print $2}')
    # Get VPN Gateway
    VPN_ROUTE_IP=$(ip a show ppp0  | grep peer | sed -e 's/.*peer\s\+\(\d\+\.\d\+\.\d\+\.\d\+\).*/\1/g')
    # Get IPs of VPN's FQDN if presented
    if echo "${VPN_SERVER}" | grep -E '\d+\.\d+\.\d+\.\d+'; then
      echo "${VPN_SERVER}" > /tmp/all_ips.txt
    else
      dig $VPN_SERVER a | grep "$VPN_SERVER" | grep -E '\d+\.\d+\.\d+\.\d+' | awk '{print $5}' > /tmp/all_ips.txt 
    fi
    
    echo "reconnector: Default Gateway=$DEAFULT_ROUTE_IP"
    echo "reconnector: VPN Gateway=$VPN_ROUTE_IP"
    echo -e "reconnector: VPN servers: \n$(cat /tmp/all_ips.txt | sed -e 's/^/ - /g')"
    echo "reconnector: wait for 3 secs";sleep 3
    # ip route add $VPN_SERVER via $DEAFULT_ROUTE_IP dev eth0
    while read p; do echo "reconnector: Adding $p to route table...";ip route add $p via $DEAFULT_ROUTE_IP dev eth0; done < /tmp/all_ips.txt

    # Check routes
    route -n
    traceroute 8.8.8.8 -m 1

    # Set default gateway to VPN
    route add -net default gw $VPN_ROUTE_IP dev ppp0

    # Check routes
    route -n
    traceroute 8.8.8.8 -m 1

    # Show Public IP
    # curl icanhazip.com
    echo "reconnector: Your Public IP: $(curl https://api64.ipify.org -s)"
  else
    sleep 10
  fi
done