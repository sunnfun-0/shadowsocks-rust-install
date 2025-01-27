#!/usr/bin/env bash
#
# Shadowsocks-Rust + BBR 一键安装脚本（适用于 Ubuntu 24）
# 1. 询问用户端口和密码
# 2. 安装 Shadowsocks-Rust
# 3. 配置 Shadowsocks-Rust 并写入 systemd
# 4. 启用 BBR 加速
#
# 使用方法：
#   1) chmod +x ss_rust_bbr_install.sh
#   2) sudo ./ss_rust_bbr_install.sh
#

#=======================
#   0. 检查是否使用 root 运行
#=======================
if [[ $(id -u) -ne 0 ]]; then
  echo "请使用 root 权限或在命令前加 sudo 运行此脚本。"
  exit 1
fi

#=======================
#   1. 询问用户输入端口与密码
#=======================
echo "请输入 Shadowsocks-Rust 监听端口（默认: 8388）:"
read -r SS_PORT
SS_PORT=${SS_PORT:-8388}

echo "请输入 Shadowsocks-Rust 密码（默认: yourpassword）:"
read -r SS_PASSWORD
SS_PASSWORD=${SS_PASSWORD:-yourpassword}

# Shadowsocks-Rust 默认使用的加密方式
SS_METHOD="aes-128-gcm"

#=======================
#   2. 安装 Shadowsocks-Rust
#=======================
echo "==> 更新系统软件包列表..."
apt update -y

echo "==> 安装依赖: build-essential、pkg-config、libssl-dev、curl 等..."
apt install -y build-essential pkg-config libssl-dev curl

echo "==> 安装最新稳定版 Rust (如果已安装，自动跳过)..."
# 安装 Rustup
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # 载入环境变量
    source "$HOME/.cargo/env"
else
    echo "Rustup 已安装，执行更新..."
    rustup update
fi

echo "==> 通过 Cargo 安装最新 shadowsocks-rust..."
# 如果此前已安装过 shadowsocks-rust，这里会检查更新
~/.cargo/bin/cargo install shadowsocks-rust

# 如果 Cargo bin 不在系统 PATH 中，可将其软链接到 /usr/local/bin
if [[ ! -f /usr/local/bin/ssserver ]]; then
    ln -sf ~/.cargo/bin/ssserver /usr/local/bin/ssserver
    ln -sf ~/.cargo/bin/sslocal /usr/local/bin/sslocal
    ln -sf ~/.cargo/bin/ssurl /usr/local/bin/ssurl
    ln -sf ~/.cargo/bin/ssmanager /usr/local/bin/ssmanager
fi

#=======================
#   3. 创建并配置 Shadowsocks-Rust 服务端配置
#=======================
echo "==> 配置 Shadowsocks-Rust 服务端..."

# 创建配置路径
SS_CONFIG_PATH="/etc/shadowsocks-rust"
mkdir -p "${SS_CONFIG_PATH}"

# 备份原有配置文件
if [[ -f "${SS_CONFIG_PATH}/config.json" ]]; then
    mv "${SS_CONFIG_PATH}/config.json" "${SS_CONFIG_PATH}/config.json.bak.$(date +%F_%T)"
fi

# 写入配置文件
cat > "${SS_CONFIG_PATH}/config.json" <<EOF
{
    "server": "::",
    "server_port": ${SS_PORT},
    "password": "${SS_PASSWORD}",
    "method": "${SS_METHOD}",
    "mode": "tcp_and_udp",
    "timeout": 300,
    "no_delay": true
}
EOF

#=======================
#   4. 设置 Systemd 服务并开机自启
#=======================
echo "==> 写入 systemd service 配置..."

SERVICE_FILE="/etc/systemd/system/shadowsocks-rust.service"

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Shadowsocks-Rust Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ssserver -c ${SS_CONFIG_PATH}/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置并启用服务
systemctl daemon-reload
systemctl enable shadowsocks-rust --now

#=======================
#   5. 启用 BBR 加速
#=======================
echo "==> 开启 BBR 加速..."

if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
fi

if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
fi

sysctl -p

# 检查BBR是否生效
tcp_cc=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [[ "$tcp_cc" == "bbr" ]]; then
    echo "BBR 已成功开启。当前拥塞控制算法: $tcp_cc"
else
    echo "BBR 未能正常开启，请检查配置。当前拥塞控制算法: $tcp_cc"
fi

#=======================
#   6. 安装完成，显示信息
#=======================
echo "==================================================================="
echo "Shadowsocks-Rust 安装完成，并已设置为 systemd 开机自启。"
echo "端口:          $SS_PORT"
echo "密码:          $SS_PASSWORD"
echo "加密方式:       $SS_METHOD"
echo "配置文件:       ${SS_CONFIG_PATH}/config.json"
echo ""
echo "BBR 已配置完成，查看是否生效:"
echo "  sysctl net.ipv4.tcp_congestion_control"
echo "  lsmod | grep bbr"
echo "==================================================================="
echo "如需再次修改 Shadowsocks-Rust 配置，请编辑: ${SS_CONFIG_PATH}/config.json"
echo "修改完成后，使用 systemctl restart shadowsocks-rust.service 重启生效。"
echo "脚本执行完毕，祝使用愉快！"
