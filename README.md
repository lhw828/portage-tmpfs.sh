# 🧠 portage-tmpfs.sh  
**Gentoo Portage 内存编译加速脚本**

---

## 📖 简介

`portage-tmpfs.sh` 是一个用于 **Gentoo Linux** 的实用脚本，可将 Portage 临时编译目录 (`/var/tmp/portage`) 挂载到内存中（tmpfs）。  
这样可以显著提升大型软件包（如 `llvm`, `firefox`, `webkit`, `chromium` 等）的编译速度，减少磁盘 I/O，延长 SSD 寿命。

使用后，编译过程将在内存中进行，结束后再恢复至磁盘。

---

## ⚙️ 功能概览

| 命令 | 说明 |
|------|------|
| `sudo ./portage-tmpfs.sh start [size]` | 启用 tmpfs 并设置大小（默认 8G） |
| `sudo ./portage-tmpfs.sh stop` | 卸载 tmpfs，恢复磁盘目录 |
| `sudo ./portage-tmpfs.sh status` | 查看当前 tmpfs 状态 |

---

## 🚀 使用示例

```bash
# 克隆脚本（假设你已保存）
sudo chmod +x portage-tmpfs.sh

# 启动 tmpfs，指定大小 12G
sudo ./portage-tmpfs.sh start 12G

# 查看当前状态
sudo ./portage-tmpfs.sh status

# 编译完成后恢复
sudo ./portage-tmpfs.sh stop
