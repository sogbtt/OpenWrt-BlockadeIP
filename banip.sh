#!/bin/sh

FIREWALL_USER="/etc/firewall.user"
BANIP_LIST="/etc/banip.list"
DELAY=0  # 不再需要延迟了，封禁持久化由 banip-persist 接管

add_to_banip_list() {
  grep -q "^$1$" "$BANIP_LIST" 2>/dev/null || echo "$1" >> "$BANIP_LIST"
}

remove_from_banip_list() {
  sed -i "/^$1$/d" "$BANIP_LIST"
}

ban_ip() {
  echo
  echo "请输入要封禁的 IP 地址："
  read IP
  [ -z "$IP" ] && echo "[错误] IP 不能为空" && return

  echo "请确认是否封禁该 IP：$IP？(y/N)"
  read -p "> " CONFIRM1
  [ "$CONFIRM1" != "y" ] && echo "已取消。" && return

  echo "再次确认是否永久封禁该 IP：$IP？(y/N)"
  read -p "> " CONFIRM2
  [ "$CONFIRM2" != "y" ] && echo "已取消。" && return

  iptables -t raw -C PREROUTING -s "$IP" -j DROP 2>/dev/null || \
  iptables -t raw -I PREROUTING -s "$IP" -j DROP

  add_to_banip_list "$IP"
  echo
  echo "[已封禁] $IP（每次开机自动生效）"
}

unban_ip() {
  echo
  echo "请输入要解封的 IP 地址："
  read IP
  [ -z "$IP" ] && echo "[错误] IP 不能为空" && return

  echo "请确认是否解封该 IP：$IP？(y/N)"
  read -p "> " CONFIRM
  [ "$CONFIRM" != "y" ] && echo "已取消。" && return

  RULE_LINE=$(iptables -t raw -L PREROUTING --line-numbers | grep "$IP" | awk '{print $1}' | head -n1)
  if [ -n "$RULE_LINE" ]; then
    iptables -t raw -D PREROUTING "$RULE_LINE"
    echo "[已解封] $IP（运行中规则）"
  else
    echo "[提示] 未找到该 IP 的封禁规则（可能尚未生效或已丢失）"
  fi

  remove_from_banip_list "$IP"
  echo "[清除记录] banip.list 中该 IP 已移除（若存在）"
}

main_menu() {
  while true; do
    sleep 1
    clear
    echo "====== BanIP 工具 ======"
    echo "1. 封禁 IP（双重确认）"
    echo "2. 解封 IP（单次确认）"
    echo "========================"
    read -p "请输入操作编号 (1/2，Ctrl+C 退出): " CHOICE
    case "$CHOICE" in
      1) ban_ip ; read -n 1 -s -r -p "\n按任意键返回菜单..." ;;
      2) unban_ip ; read -n 1 -s -r -p "\n按任意键返回菜单..." ;;
      *) echo "[错误] 无效选项" ; sleep 1 ;;
    esac
  done
}

main_menu
