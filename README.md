
# Ubuntu Server Setup Script

This repository contains a Bash script to quickly set up a clean Ubuntu server with:

- nano
- ufw (with SSH access restricted to 192.168.10.0/24)
- rsync
- Filebrowser (web file manager)

You can choose to install **all components**, or **specific ones individually** during the setup process.

---

## 📦 What's Included

- Package installs: `nano`, `ufw`, `rsync`
- Filebrowser setup with systemd service
- UFW rule for port 22 from 192.168.10.0/24
- Optional symlink into `/home/filebrowser/` for custom directories

---

## 🚀 Quick Start

### On a clean Ubuntu server, run:

```bash
sudo apt update && sudo apt install -y git && git clone https://github.com/NChaves/ubuntu.git && cd setup-scripts && chmod +x setup.sh && ./setup.sh
```

> 🔁 Replace `https://github.com/yourusername/setup-scripts.git` with the actual URL of this repository.

---

## 🔧 Manual Step-by-Step

If you prefer to run each command individually:

```bash
# 1. Install git (if not already installed)
sudo apt update && sudo apt install -y git

# 2. Clone this repository
git clone https://github.com/yourusername/setup-scripts.git

# 3. Change into the repo directory
cd setup-scripts

# 4. Make the setup script executable
chmod +x setup.sh

# 5. Run the setup script
./setup.sh
```

---

## 🔐 Note

This script will:

- Prompt you to select which components to install.
- Set up Filebrowser with a config pointing to your local IP.
- Offer to symlink a folder into `/home/filebrowser/`.

---

## 📬 Questions?

Feel free to open an issue or PR if you have suggestions or improvements!
