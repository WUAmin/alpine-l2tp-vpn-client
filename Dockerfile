FROM alpine:3.12

ENV LANG C.UTF-8
ENV VPN_ENABLE 1
ENV SCOKS5_ENABLE 0
ENV SCOKS5_FORKS 2
ENV SCOKS5_START_DELAY 5

RUN set -x && \
    apk add --no-cache \
              openrc \
              libreswan \
              xl2tpd \
              curl \
              bind-tools \
              ppp \
              dante-server \
    && rm -rf /tmp/* \
    && mkdir -p /var/run/pluto \
    && mkdir -p /var/run/xl2tpd \
    && touch /var/run/xl2tpd/l2tp-control

# VPN Files
COPY ipsec.conf /etc/ipsec.conf
COPY ipsec.secrets /etc/ipsec.secrets
COPY xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
COPY options.l2tpd.client /etc/ppp/options.l2tpd.client
# Socks5 Files
COPY sockd.conf /etc/sockd.conf
# Scripts
COPY startup.sh /
COPY reconnector.sh /

CMD ["/startup.sh"]
