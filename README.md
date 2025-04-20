
# Ubuntu Server Bundle Script

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
sudo apt update && sudo apt install -y git && git clone https://github.com/NChaves/ubuntu-scripts.git && cd ubuntu-scripts && chmod +x bundle.sh && ./bundle.sh
```

---

## 🔧 Manual Step-by-Step

If you prefer to run each command individually:

```bash
# 1. Install git (if not already installed)
sudo apt update && sudo apt install -y git

# 2. Clone this repository
git clone https://github.com/NChaves/ubuntu-scripts.git

# 3. Change into the repo directory
cd ubuntu-scripts

# 4. Make the bundle script executable
chmod +x bundle.sh

# 5. Run the bundle script
./bundle.sh
```

---
## 📝 Updating the Repo and Re-running the Bundle Script

If you've made changes to the remote repository or simply want to update your local copy of the repository and re-run the bundle script in one command, you can do the following:
```bash
cd ubuntu-scripts && git pull && chmod +x bundle.sh && ./bundle.sh
```

What it does:

- `git pull`: Fetches and merges the latest changes from the remote repository into your local copy.
- `chmod +x bundle.sh`: Ensures that the bundle.sh script is executable (in case the permissions were reset).
- `./bundle.sh`: Executes the updated bundle script to apply any new configurations or changes.

---

## 🔐 Note

This script will:

- Prompt you to select which components to install.
- Set up Filebrowser with a config pointing to your local IP.
- Offer to symlink a folder into `/home/filebrowser/`.

---
