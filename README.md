
# Shadowsocks Rust 一键安装与优化脚本

本仓库提供一个用于安装、配置和优化 Shadowsocks Rust 的自动化脚本，适用于 Linux 系统，支持运行时手动输入端口、密码和加密方式。

---

## 功能

- **自动安装**：一键安装 Shadowsocks Rust。
- **动态配置**：运行脚本时手动输入端口、密码和加密方式。
- **系统优化**：自动启用 TCP BBR 拥塞控制，优化网络性能。
- **服务管理**：使用 `systemd` 管理 Shadowsocks 服务。

---

## 使用方法

### 1. 下载脚本
克隆仓库到本地：
```bash
git clone https://github.com/sunnfun-0/shadowsocks-install.git
cd shadowsocks-install
```

或直接下载脚本：
```bash
wget https://raw.githubusercontent.com/sunnfun-0/shadowsocks-install/main/install_ss_optimized.sh
```

### 2. 赋予执行权限
```bash
chmod +x install_ss_optimized.sh
```

### 3. 运行脚本
```bash
sudo ./install_ss_optimized.sh
```

### 4. 输入配置信息
按照提示输入以下内容：
- **监听端口**（默认 `27088`）：Shadowsocks 服务的端口。
- **密码**：用于连接的密码。
- **加密方式**（默认 `aes-128-gcm`）：支持多种加密方式，如 `aes-256-gcm`、`chacha20-ietf-poly1305`。

---

## 示例

运行脚本时的示例交互：
```
请输入 Shadowsocks 监听端口 (默认 27088): 8388
请输入 Shadowsocks 密码: ********
请输入 Shadowsocks 加密方式 (默认 aes-128-gcm): chacha20-ietf-poly1305
```

运行成功后，服务将自动启动，并使用 `systemd` 管理。

---

## 系统优化

脚本会自动启用以下网络优化：
- 设置队列调度算法为 `fq`。
- 启用 TCP BBR 拥塞控制。

验证优化是否生效：
```bash
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr
```

---

## 注意事项

- 请确保系统为 **Ubuntu 20.04** 或更高版本。
- 需要 `wget`、`tar` 和 `vim` 等工具，脚本会自动安装缺失的软件包。
- 脚本将修改系统的网络参数，请确认您的需求与服务器环境相符。

---

## 开源协议

本项目基于 [MIT License](LICENSE) 开源，欢迎自由使用和修改。
