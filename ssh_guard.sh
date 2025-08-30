#!/bin/sh

# === SSH 安全卫士 BanIP v2.3 无标志符稳定版本 ===

LOG_KEYWORDS="luci: failed login on|bad password|Failed password|invalid user|Exit before auth|authentication failure"
MAX_ATTEMPTS=20
BANIP_LIST="/etc/banip.list"
LOG_FILE="/mnt/sda1/Caches/ssh_guard.log"
LAST_RUN="/tmp/ssh_guard.last"

[ -f "$LAST_RUN" ] && [ $(($(date +%s) - $(cat "$LAST_RUN"))) -lt 60 ] && exit 0
date +%s > "$LAST_RUN"
mkdir -p "$(dirname "$LOG_FILE")"

BLOCK_COUNT=0
TMP_FILE="/tmp/ssh_guard.tmp"

logread | grep -Ei "$LOG_KEYWORDS" | sed -nE 's/.*from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | sort | uniq -c > "$TMP_FILE"

while read -r COUNT IP; do
  [ "$COUNT" -lt "$MAX_ATTEMPTS" ] && continue
  grep -q "^$IP$" "$BANIP_LIST" 2>/dev/null && continue
  iptables -t raw -C PREROUTING -s "$IP" -j DROP 2>/dev/null && continue
  iptables -t raw -I PREROUTING -s "$IP" -j DROP
  echo "$IP" >> "$BANIP_LIST"
  echo "$(date '+%Y-%m-%d %H:%M:%S') 封禁 $IP（尝试 $COUNT 次）" >> "$LOG_FILE"
  BLOCK_COUNT=$((BLOCK_COUNT + 1))
done < "$TMP_FILE"

rm -f "$TMP_FILE"

# ✅ 只有真正封禁成功的 IP 数量 > 0 时，才清理日志
if [ "$BLOCK_COUNT" -gt 0 ]; then
  [ -f /tmp/log/syslog ] && truncate -s 0 /tmp/log/syslog
  /etc/init.d/log restart
fi
