#!/bin/sh /etc/rc.common
START=99

start() {
  logger "[banip-persist] 正在恢复封禁列表..."
  [ -f /etc/banip.list ] && grep -Ev '^[[:space:]]*(#|$)' /etc/banip.list | while read ip; do
    iptables -t raw -C PREROUTING -s "$ip" -j DROP 2>/dev/null || \
    iptables -t raw -I PREROUTING -s "$ip" -j DROP
  done
}
