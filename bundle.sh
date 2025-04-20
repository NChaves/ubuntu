#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt update

# Function to check and install/update packages
install_or_update() {
    local pkg=$1
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed. Checking for updates..."
        sudo apt install --only-upgrade -y "$pkg"
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
}

# Install nano, ufw, rsync
install_or_update nano
install_or_update ufw
install_or_update rsync

# Configure ufw
echo "Setting UFW rule to allow SSH from 192.168.10.0/24..."
sudo ufw allow from 192.168.10.0/24 to any port 22 proto tcp
echo "UFW rule added. (Note: UFW is not enabled by default.)"

# Setup Filebrowser
FILEBROWSER_DIR="/home/filebrowser"
if [ ! -d "$FILEBROWSER_DIR" ]; then
    echo "Creating $FILEBROWSER_DIR..."
    sudo mkdir -p "$FILEBROWSER_DIR"
    sudo chown "$USER":"$USER" "$FILEBROWSER_DIR"
fi

# Check if filebrowser is installed
if ! command -v filebrowser >/dev/null 2>&1; then
    echo "Installing Filebrowser..."
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
else
    echo "Filebrowser is already installed."
fi

# Get local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Create filebrowser config
FILEBROWSER_CONFIG="/etc/filebrowser.json"
echo "Creating Filebrowser config at $FILEBROWSER_CONFIG..."
sudo tee "$FILEBROWSER_CONFIG" >/dev/null <<EOF
{
  "port": 8080,
  "baseURL": "",
  "address": "$LOCAL_IP",
  "log": "stdout",
  "database": "/etc/filebrowser.db",
  "root": "$FILEBROWSER_DIR"
}
EOF

# Create systemd service
FILEBROWSER_SERVICE="/etc/systemd/system/filebrowser.service"
echo "Creating systemd service for Filebrowser..."
sudo tee "$FILEBROWSER_SERVICE" >/dev/null <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -c /etc/filebrowser.json

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Enabling and starting Filebrowser service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable filebrowser
sudo systemctl start filebrowser

# Offer to symlink a folder
read -p "Do you want to symlink a folder into /home/filebrowser/? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    read -p "Enter the source directory to symlink: " src
    read -p "Enter the name for the destination folder (relative to /home/filebrowser/): " dest
    dest_path="$FILEBROWSER_DIR/$dest"

    if [ -e "$src" ]; then
        if [ ! -e "$dest_path" ]; then
            ln -s "$src" "$dest_path"
            echo "Symlink created: $dest_path -> $src"
        else
            echo "Destination $dest_path already exists. Skipping symlink."
        fi
    else
        echo "Source directory $src does not exist. Skipping symlink."
    fi
else
    echo "No symlink created."
fi

echo "All tasks completed."
