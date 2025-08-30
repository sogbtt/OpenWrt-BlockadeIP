# BanIP —— OpenWrt 轻量级防火墙封禁工具

## 📖 项目简介
BanIP 是一个运行在 **OpenWrt 路由器**上的轻量化防火墙工具，目标是为用户提供 **高效、持久、可控** 的 IP 封禁能力。  
它的核心思路是使用 `iptables -t raw PREROUTING`，保证即使在 **端口转发（DNAT）** 场景下，恶意流量也能第一时间被丢弃。  

相比于传统的 `fw4` / `banIP` 插件，BanIP 更加：
- ✅ **轻量级**：无需 Python、无需 fail2ban，仅依赖 Shell 与 iptables  
- ✅ **场景化**：解决转发流量无法被阻断的问题  
- ✅ **持久化**：内置 `banip-persist`，重启后自动恢复规则  
- ✅ **可拓展**：已支持“SSH 安全卫士”自动检测爆破行为并封禁  

<img width="2560" height="1239" alt="Image" src="https://github.com/user-attachments/assets/2a4bf489-0fb9-4ecb-aa04-ad203c75e590" />

<img width="2560" height="1239" alt="Image" src="https://github.com/user-attachments/assets/fdd0db47-415b-4790-807f-7648da04bd29" />

## 🛠 前置环境

### 【已测试】系统环境
- **操作系统**：OpenWrt 23.05 / 24.10 / 及更新版本  
- **架构支持**：x86_64、ARM（R4S、R2S 等均可）  
- **内核版本**：≥ 5.15（推荐 6.x 系列）  

### 防火墙要求
- 使用 **iptables 兼容层**（默认 OpenWrt 提供）  
- 实测环境：
  - OpenWrt 24.10.0  
  - 内核 `6.12.18`  
  - 目标平台：`x86/64`（Intel N5100）  

### 注意事项
- 本工具 **直接操作 raw 表**，不会与 nftables/fail2ban 冲突  
- 如系统未安装 iptables，可通过：
  ```sh
  opkg update
  opkg install iptables-mod-raw


