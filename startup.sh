#!/bin/sh

# Run VPN if VPN_ENABLE is 1
if [[ $VPN_ENABLE -eq 1 ]];then
  echo "startup/vpn: configuring vpn client."
  # template out all the config files using env vars
  sed -i 's/right=.*/right='$VPN_SERVER'/' /etc/ipsec.conf
  echo ': PSK "'$VPN_PSK'"' > /etc/ipsec.secrets
  sed -i 's/lns = .*/lns = '$VPN_SERVER'/' /etc/xl2tpd/xl2tpd.conf
  sed -i 's/name .*/name '$VPN_USERNAME'/' /etc/ppp/options.l2tpd.client
  sed -i 's/password .*/password '$VPN_PASSWORD'/' /etc/ppp/options.l2tpd.client

  # startup ipsec tunnel
  ipsec initnss
  sleep 1
  ipsec pluto --stderrlog --config /etc/ipsec.conf
  sleep 5
  #ipsec setup start
  #sleep 1
  #ipsec auto --add L2TP-PSK
  #sleep 1
  ipsec auto --up L2TP-PSK
  sleep 3
  ipsec --status
  sleep 3


  # startup xl2tpd ppp daemon then send it a connect command
  (sleep 7 \
    && echo "startup/vpn: send connect command to vpn client." \
    && echo "c myVPN" > /var/run/xl2tpd/l2tp-control) &
  exec /reconnector.sh &
  echo "startup/vpn: start vpn client daemon."
  exec /usr/sbin/xl2tpd -p /var/run/xl2tpd.pid -c /etc/xl2tpd/xl2tpd.conf -C /var/run/xl2tpd/l2tp-control -D &
else
  echo "startup/vpn: Ignore vpn client."
fi

# Run socks5 server after 10 Seconds if SCOKS5_ENABLE is 1
if [[ $SCOKS5_ENABLE -eq 1 ]];then
  echo "startup/socks5: waiting for ppp0"
  (while ! route | grep ppp0 > /dev/null; do sleep 1; done \
    && echo "startup/socks5: Socks5 will start in $SCOKS5_START_DELAY seconds" \
    && sleep $SCOKS5_START_DELAY \
    && sockd -N $SCOKS5_FORKS) &
else
  echo "startup/socks5: Ignore socks5 server."
fi

exec tail -f /dev/null  ## %%LAST-CMD_2_REPLACE%
