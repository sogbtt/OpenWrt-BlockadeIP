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
  
# 🚀 部署流程【手动封禁管理脚本】

## 1. 部署终端手动封禁脚本

* 将 `banip.sh` 拷贝至 `/usr/bin/` 下，并取消 `.sh` 尾缀
* 赋予脚本权限：

```sh
chmod +x /usr/bin/banip
```

## 2. 使用方式

在终端输入：

```sh
banip
```

即可弹出手动封禁脚本，用于临时封禁测试和手动指定 IP 封禁。

<img width="702" height="248" alt="image" src="https://github.com/user-attachments/assets/37e90e3f-1947-4c88-90e1-3673968ff864" />

```sh
BANIP_LIST="/etc/banip.list"   # 黑名单存放路径
```

## 3. 配置 init.d 启动项

* 将 `banip-persist.sh` 脚本内容粘贴进：

  ```sh
  nano /etc/init.d/banip-persist
  ```
* 保存并退出后，赋予执行权限：

  ```sh
  chmod +x /etc/init.d/banip-persist
  ```
* 设置开机自动启动（只需执行一次）：

  ```sh
  /etc/init.d/banip-persist enable
  ```
* （可选）立即手动执行一次测试：

  ```sh
  /etc/init.d/banip-persist start
  ```

## 4. 在 Luci 面板配置

在 `exit 0` 前加入启动脚本：

```sh
/etc/init.d/banip-persist start
```

<img width="1504" height="680" alt="image" src="https://github.com/user-attachments/assets/e6450249-9256-476d-9577-212ccfddc6ff" />

* 本脚本用于启动时恢复曾经已经封禁的黑名单 IP 列表。

## 5. 查看当前生效封禁 IP 列表

```sh
iptables -t raw -L PREROUTING -n --line-numbers
```
<img width="716" height="467" alt="image" src="https://github.com/user-attachments/assets/5b61095c-d75c-4547-bbdb-5a3227aee26d" />

---

# 🔒 高级功能：【SSH 安全卫士】

* 自动分析 `logread` 或 LuCI 系统日志
* 识别同一 IP 短时间内多次 SSH 爆破行为（默认阈值：20 次）
* 自动调用 `banip.sh` 封禁该 IP
* 在 `/mnt/sda1/Caches/` 下生成日志文件，仅记录成功封禁的 IP

## 部署步骤

1. 部署防护脚本：

   ```sh
   cp ssh_guard.sh /usr/bin/ssh_guard.sh
   chmod +x /usr/bin/ssh_guard.sh
   ```

2. 守护日志路径：

   ```sh
   /mnt/sda1/Caches/ssh_guard.log
   ```

   如需修改日志储存路径，请修改脚本中，其余路径请不要做改动：

   ```sh
   LOG_FILE="/mnt/sda1/Caches/ssh_guard.log"
   ```

3. 设置计划任务周期性运行 IP 封禁卫士脚本：

   ```sh
   * * * * * /usr/bin/ssh_guard.sh
   ```

<img width="1168" height="578" alt="image" src="https://github.com/user-attachments/assets/396c9a25-b1b1-4c0d-a081-eea0452fa061" />

---

# 🔒 高级功能：【SSH 安全卫士 - WEB 前端部分】

* 请将 `index.html` 文件放在同上：

  ```sh
  LOG_FILE="/mnt/sda1/Caches/ssh_guard.log"
  ```

* 前端文件将自动读取 log 内容并在前端呈现。

## 使用 Docker 部署 Nginx 简易前端服务器

<img width="440" height="76" alt="image" src="https://github.com/user-attachments/assets/61d27d4d-f0da-449f-bc08-53b98a9e3c13" />

### 1. 拉取并运行 Nginx 容器

```sh
docker run -d \
  --name banip-web \
  -p 17480:80 \
  -v /mnt/sda1/Caches:/usr/share/nginx/html:rw \
  nginx:latest
```

### 2. 访问日志面板

```
http://<你的路由器IP>:17480/
```

### 3. 查看结果

* `/mnt/sda1/Caches` 下的封禁日志文件将实时展示在前端 Web 页面中。



# 🔒 高级功能：【SSH 安全卫士 - Luci 登录页样式修改】

OpenWrt 默认登录界面并没有额外的按钮扩展，可通过修改模板样式文件来实现新增防护按钮。

* LuCI 登录界面文件路径：

  ```
  /usr/lib/lua/luci/view/themes/argon/sysauth.htm
  ```
* 大概在第 154 行左右找到 submit 登录按钮位置，在下方新增代码：

<img width="868" height="281" alt="image" src="https://github.com/user-attachments/assets/84b54560-b8e8-40cd-b218-f2b21514c998" />

```html
<a href="http://你的服务器地址:17480/" target="_blank"
style="display:block; margin-top:-80px; padding:15px 0; width:100%; background-color:#ff7e00; color:#fff; font-size:16px; text-align:center; border-radius:8px; text-decoration:none; font-weight:bold;">
 🛡️ 爆 破 攻 击 拦 截 L o g s </a>
```

# ✅【验证测试】所有步骤均已完成

### 1. 用 logger 伪造 SSH 失败日志，比如 30 次：

```sh
for i in $(seq 1 30); do \
  logger -t sshd "Failed password for root from 37.252.240.79 port $((40000+i)) ssh2"; \
done
```

<img width="765" height="579" alt="image" src="https://github.com/user-attachments/assets/33bf430c-ebf8-4b7b-a95d-172048eeecb9" />

静静等待 1 分钟，等待下一周期脚本自动运行检测后，会对日志中异常 IP 提取并封禁，在完成封禁后会清理一次系统日志，防止重复封禁。

<img width="470" height="250" alt="image" src="https://github.com/user-attachments/assets/7756b19a-31f8-4c9f-b9cc-422559981c2b" />

### 2. 查看当前生效封禁 IP 列表

```sh
iptables -t raw -L PREROUTING -n --line-numbers
```

### 3. 查看 log 封禁日志

```sh
/mnt/sda1/Caches/ssh_guard.log
```

<img width="585" height="507" alt="image" src="https://github.com/user-attachments/assets/080b3b66-d18d-49f7-95ac-27b7b67f3702" />

### 4. 访问 WEB 前端封禁界面

<img width="2231" height="398" alt="image" src="https://github.com/user-attachments/assets/04e0b37b-2a7f-4f68-a6b8-88d69a555533" />

# 📌 写在最后

有能力的大咖可以尝试将本项目 **编译为 ipk 插件**。毕竟隔三差五就会遇到 SSH 爆破和 WEB 异常爆破，虽然系统自带了一些防护手段，但效果始终不尽人意，只能做到拦截，而缺乏真正的防治能力。

更神奇的是，自从这个面板上线后，我已经很久没有看到有人再次攻击我的 OpenWrt —— 这或许就是 **「望而生畏计划」** 的魅力。

