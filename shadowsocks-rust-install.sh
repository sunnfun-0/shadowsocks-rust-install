#!/bin/bash

# Shadowsocks Rust 一键安装与优化脚本

# 设置变量
SS_VERSION="v1.21.2"
SS_FILE="shadowsocks-${SS_VERSION}.x86_64-unknown-linux-gnu.tar.xz"
SS_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${SS_VERSION}/${SS_FILE}"
SS_CONFIG="/etc/shadowsocks-rust.json"
SS_SERVICE="/etc/systemd/system/shadowsocks.service"

# 提示用户输入端口、密码和加密方式
read -p "请输入 Shadowsocks 监听端口 (默认 27088): " SS_PORT
SS_PORT=${SS_PORT:-27088} # 如果用户未输入，则使用默认值

read -sp "请输入 Shadowsocks 密码: " SS_PASSWORD
echo

read -p "请输入 Shadowsocks 加密方式 (默认 aes-128-gcm): " SS_METHOD
SS_METHOD=${SS_METHOD:-aes-128-gcm} # 如果用户未输入，则使用默认值

# 安装必要工具
echo "更新系统并安装必要工具..."
sudo apt update && sudo apt install -y wget tar vim

# 下载 Shadowsocks
echo "下载 Shadowsocks Rust..."
wget $SS_URL

# 解压并移动文件
echo "解压文件并移动可执行文件到系统路径..."
tar -xvf $SS_FILE
sudo mv ssserver /usr/local/bin/
sudo mv sslocal /usr/local/bin/
sudo mv ssmanager /usr/local/bin/

# 验证安装
echo "验证 Shadowsocks Rust 安装..."
ssserver --version || { echo "安装失败，请检查！"; exit 1; }

# 创建配置文件
echo "创建配置文件..."
sudo bash -c "cat > $SS_CONFIG" << EOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASSWORD",
    "method": "$SS_METHOD",
    "timeout": 300,
    "mode": "tcp_and_udp"
}
EOF

echo "配置文件已创建：$SS_CONFIG"

# 创建 systemd 服务
echo "创建 Shadowsocks 服务文件..."
sudo bash -c "cat > $SS_SERVICE" << EOF
[Unit]
Description=Shadowsocks Rust Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ssserver -c $SS_CONFIG
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启动服务
echo "启用并启动 Shadowsocks 服务..."
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl start shadowsocks

# 检查服务状态
echo "检查 Shadowsocks 服务状态..."
sudo systemctl status shadowsocks

# 系统优化
echo "开始系统优化..."
sudo bash -c "cat >> /etc/sysctl.conf" << EOF

# Shadowsocks 性能优化
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# 应用优化配置
sudo sysctl -p

# 验证 BBR 是否启用
echo "验证 BBR 是否启用..."
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr

echo "安装和优化完成！"