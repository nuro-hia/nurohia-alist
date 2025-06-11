# Alist v3.39.4 一键部署工具 - NuroHia

本项目提供 Alist v3.39.4 的简洁稳定部署方式，支持自动安装、降级、密码重置、状态查看等功能，适配 `amd64` 与 `arm64` 架构。

## 📦 安装方式

### ✅ 一键执行安装脚本：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nurohia-alist/main/install.sh)
```

> 建议以 `root` 用户执行，以确保对 systemd 服务、安装路径等无权限限制。

## 🔧 脚本功能菜单

运行后将进入交互菜单，功能如下：

```
===== NuroHia Alist v3.39.4 一键部署管理器 =====

1) 安装 Alist v3.39.4（支持自定义压缩包链接）
2) 强制降级至 v3.39.4
3) 查看当前运行状态
4) 查看当前 Alist 版本
5) 重启 Alist 服务
6) 停止 Alist 服务
7) 卸载 Alist
8) 重置管理员密码
9) 退出
```

## 📁 安装位置与服务说明

- 安装目录：`/opt/alist`
- systemd 服务名：`alist`
- 默认数据路径：`/opt/alist/data/`
- 默认端口：`5244`（可通过 config.json 修改）

## 🔐 安装成功后将自动显示登录信息：

```
Username: admin
Password: （自动生成，首次安装时显示）
Web 面板: http://<你的服务器IP>:5244
```

如忘记密码，可在菜单中选择 `8) 重置管理员密码`。

## 🛠 架构支持

- ✅ x86_64 (`amd64`)
- ✅ aarch64 (`arm64`)

## 📌 免责声明

本脚本由 NuroHia 编写与维护，适用于希望部署 Alist v3.39.4 的用户，如遇到 bug 可通过 issue 提出反馈。
