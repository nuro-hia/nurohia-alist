#!/bin/bash
set -e

INSTALL_DIR="/opt/alist"
SERVICE_FILE="/etc/systemd/system/alist.service"
ARCH=$(uname -m)
DEFAULT_PORT=5244

ALIST_AMD64_URL="https://github.com/nuro-hia/nurohia-alist/releases/download/v3.39.4/alist-linux-amd64.tar.gz"
ALIST_ARM64_URL="https://github.com/nuro-hia/nurohia-alist/releases/download/v3.39.4/alist-linux-arm64.tar.gz"

function detect_arch() {
  if [[ "$ARCH" == "x86_64" ]]; then
    echo "$ALIST_AMD64_URL"
  elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "$ALIST_ARM64_URL"
  else
    echo "[!] 不支持的架构: $ARCH"
    exit 1
  fi
}

function pause_return() {
  echo
  read -rp "按回车键返回菜单..."
}

function backup_data() {
  if [ -f "$INSTALL_DIR/data/data.db" ]; then
    cp "$INSTALL_DIR/data/data.db" "$INSTALL_DIR/data/data.db.bak.$(date +%Y%m%d%H%M%S)"
    echo "[*] 数据库已备份"
  fi
}

function install_alist() {
  echo "[+] 安装 Alist 到 $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR"

  systemctl stop alist 2>/dev/null || true
  backup_data

  echo -e "[*] 是否使用自定义 .tar.gz 下载链接？\n留空则使用默认版本 v3.39.4"
  read -rp "请输入下载链接: " custom_url

  if [[ -n "$custom_url" ]]; then
    url="$custom_url"
  else
    url=$(detect_arch)
  fi

  echo "[*] 下载 Alist..."
  wget -O alist.tar.gz "$url"

  echo "[*] 解压中..."
  tar -xzf alist.tar.gz
  chmod +x alist
  rm -f alist.tar.gz

  echo "[*] 初始化配置目录..."
  mkdir -p data
  echo '{"address": ":'"$DEFAULT_PORT"'"}' > data/config.json

  echo "[*] 写入 systemd 服务配置..."
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Alist Server
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/alist server
WorkingDirectory=${INSTALL_DIR}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable alist
  systemctl start alist

  echo "[*] 初始化管理员密码为: 用户名 admin 密码 123456"
  "${INSTALL_DIR}/alist" admin set 123456 >/dev/null 2>&1 || true

  echo "Web 面板访问地址： http://你的服务器IP:$DEFAULT_PORT"
  echo "======================================="
  pause_return
}

function downgrade_alist() {
  echo "[!] 正在降级至 v3.39.4..."
  install_alist
}

function show_status() {
  echo "===== 当前 Alist 状态 ====="
  if systemctl is-active --quiet alist; then
    echo "[✔] Alist 正在运行"
  else
    echo "[✘] Alist 未运行"
  fi
  echo -n "[*] 当前版本: "
  if [ -x "$INSTALL_DIR/alist" ]; then
    "$INSTALL_DIR/alist" version | grep Version || echo "未知"
  else
    echo "未检测到"
  fi
  echo -n "[*] 监听端口: "
  ss -lntp | grep alist || echo "未监听或未启动"
  echo "================================"
  pause_return
}

function show_version() {
  echo "===== 当前 Alist 版本 ====="
  if [ -x "$INSTALL_DIR/alist" ]; then
    "$INSTALL_DIR/alist" version || echo "未知"
  else
    echo "未检测到 Alist 可执行文件"
  fi
  echo "================================"
  pause_return
}

function restart_alist() {
  systemctl restart alist
  echo "[*] Alist 已重启"
  pause_return
}

function stop_alist() {
  systemctl stop alist
  echo "[*] Alist 已停止"
  pause_return
}

function uninstall_alist() {
  echo "[!] 确认卸载 Alist？[y/N]"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    systemctl stop alist
    systemctl disable alist
    rm -f "$SERVICE_FILE"
    systemctl daemon-reexec
    systemctl daemon-reload
    rm -rf "$INSTALL_DIR"
    echo "[✔] Alist 已卸载"
  else
    echo "已取消"
  fi
  pause_return
}

function reset_admin_password() {
  echo "[!] 这将重置管理员密码，是否继续？[y/N]"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "[*] 重置为默认密码 123456..."
    "$INSTALL_DIR/alist" admin set 123456 && echo "[✔] 密码已重置为 123456"
  else
    echo "已取消操作。"
  fi
  pause_return
}

function change_port() {
  echo "[*] 当前监听端口:"
  grep '"address"' "$INSTALL_DIR/data/config.json" || echo "默认: $DEFAULT_PORT"
  read -rp "请输入新的端口号: " new_port
  sed -i "s/\"address\": \".*\"/\"address\": \":$new_port\"/" "$INSTALL_DIR/data/config.json"
  echo "[*] 端口已更新，正在重启 Alist..."
  systemctl restart alist
  echo "[✔] 已更改监听端口为: $new_port"
  pause_return
}

function quick_open_panel() {
  echo "[*] 正在打开默认面板地址..."
  IP=$(curl -s ipv4.ip.sb || curl -s ifconfig.me || echo "你的服务器IP")
  echo "浏览器访问：http://$IP:$DEFAULT_PORT"
  pause_return
}

function show_menu() {
  clear
  echo "===== NuroHia Alist v3.39.4 一键部署管理器 ====="
  echo "1) 安装 Alist"
  echo "2) 强制降级至 v3.39.4"
  echo "3) 查看当前运行状态"
  echo "4) 查看当前 Alist 版本"
  echo "5) 重启 Alist 服务"
  echo "6) 停止 Alist 服务"
  echo "7) 卸载 Alist"
  echo "8) 重置管理员密码"
  echo "9) 更改面板端口"
  echo "10) 快速打开访问地址"
  echo "11) 退出"
  echo "======================================="
  read -rp "请输入选项 [1-11]: " choice

  case "$choice" in
    1) install_alist ;;
    2) downgrade_alist ;;
    3) show_status ;;
    4) show_version ;;
    5) restart_alist ;;
    6) stop_alist ;;
    7) uninstall_alist ;;
    8) reset_admin_password ;;
    9) change_port ;;
    10) quick_open_panel ;;
    11) exit 0 ;;
    *) echo "无效选项" && sleep 1 ;;
  esac
}

while true; do
  show_menu
done
