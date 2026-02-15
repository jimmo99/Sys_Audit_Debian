
# 🔍 SysAudit: Linux Server Inventory & Recovery Tool

**SysAudit** is a lightweight, dependency-free Bash script designed to generate a detailed **Markdown report** of your Linux server or workstation. 

It audits hardware, network configurations, Docker containers, and installed software, automatically creating a **Disaster Recovery Cheat Sheet** to help you reinstall your environment on a new machine.

> **Perfect for:** SysAdmins, DevOps, and Homelab enthusiasts running Ubuntu, Debian, or Linux Mint.

## 🚀 Features

* **⚡ Zero Dependencies:** Written in pure Bash. No need to install Python or extra agents.
* **📊 Hardware Audit:** CPU model, RAM usage, Disk partitions, and Filesystem types (ext4, fuseblk, etc.).
* **🛡️ Network & Security:** Detects open ports (Listening), processes binding them, and UFW Firewall status.
* **🐳 Docker & Virtualization:**
    * Lists active/stopped containers.
    * Detects **Docker Compose** project paths (so you know where your `docker-compose.yml` files are).
* **📦 Package Inventory:**
    * **APT:** Lists only *manually installed* packages (filters out automatic dependencies).
    * **Snap & Flatpak:** Lists installed applications.
    * **Dev Tools:** Detects global Node.js packages (npm), Pipx tools, and Python environments.
* **🤖 Automation:** Captures User Crontabs and custom Systemd services.
* **♻️ Auto-Recovery:** Generates a copy-paste **"Cheat Sheet"** at the end of the report with the exact commands to reinstall your software.

## 📥 Installation & Usage

You can download and run the script directly. **Root privileges (sudo)** are recommended to detect open ports, firewall status, and system-wide configs.

### 1. Download the script
```bash
wget [https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/sys_audit.sh](https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/sys_audit.sh)

```

### 2. Make it executable

```bash
chmod +x sys_audit.sh

```

### 3. Run it

```bash
sudo ./sys_audit.sh

```

---

## 📄 Output Example

The script generates a file named `server_report_HOSTNAME_DATE.md`.
You can view it with any Markdown viewer or text editor.

**Sample content structure:**

| Section | Description |
| --- | --- |
| **1. Hardware** | CPU, RAM, Disk usage. |
| **2. Network** | Open ports (`ss -tulnp`) & Firewall rules. |
| **3. Software** | Clean list of APT/Snap/Flatpak packages. |
| **4. Docker** | Containers, images, and Compose paths. |
| **5. Dev** | Git repos found in `/home` or `/opt`. |
| **6. System** | Cron jobs and Systemd services. |
| **7. RECOVERY** | **Commands to reinstall everything.** |

---

## 🤖 Automation (Optional)

You can set up a Cron job to auto-generate this report monthly:

1. Edit crontab: `sudo crontab -e`
2. Add this line (runs on the 1st of every month):
```bash
0 4 1 * * /bin/bash /path/to/sys_audit.sh

```



## 🛠 Compatibility

Tested and working on:

* ✅ Ubuntu 20.04 / 22.04 / 24.04 (Server & Desktop)
* ✅ Debian 11 / 12
* ✅ Linux Mint & Pop!_OS
* ✅ Raspberry Pi OS

## 📄 License

MIT License - Feel free to modify and share!

```

```
