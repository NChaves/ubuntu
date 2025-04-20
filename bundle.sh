#!/bin/bash

set -e

# Installable options
declare -A options=(
    [1]="nano"
    [2]="ufw"
    [3]="rsync"
    [4]="filebrowser"
)

# Prompt user to choose
echo "Select what to install:"
for i in "${!options[@]}"; do
    echo "  $i) ${options[$i]}"
done
echo "  All) Install all of the above"

read -p "Enter option (number or 'All'): " selection

# Determine what to install
install_all=false
install_selection=()

if [[ "$selection" =~ ^[Aa]ll$ ]]; then
    install_all=true
    install_selection=("${options[@]}")
elif [[ "${options[$selection]+exists}" ]]; then
    install_selection+=("${options[$selection]}")
else
    echo "Invalid selection. Exiting."
    exit 1
fi

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

# Install selected applications
for app in "${install_selection[@]}"; do
    case "$app" in
        nano)
            install_or_update nano
            ;;
        ufw)
            install_or_update ufw
            echo "Setting UFW rule to allow SSH from the local network..."

            # Get the local IP address
            LOCAL_IP=$(hostname -I | awk '{print $1}')

            # Automatically determine the subnet based on the local IP address
            NETWORK_SUBNET=$(echo $LOCAL_IP | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*/\1.0\/24/')

            echo "Setting UFW rule to allow SSH from $NETWORK_SUBNET..."
            sudo ufw allow from $NETWORK_SUBNET to any port 22 proto tcp
            echo "UFW rule added. (Note: UFW is not enabled by default.)"

            # Show current UFW status and rules
            echo ""
            echo "🔒 Current UFW Status and Rules:"
            sudo ufw status verbose

            # Ask if the user wants to enable UFW
            read -p "Do you want to enable UFW now? (y/n): " enable_ufw
            if [[ "$enable_ufw" =~ ^[Yy]$ ]]; then
                sudo ufw enable
                echo "UFW has been enabled."
            else
                echo "UFW remains disabled. You can enable it later using 'sudo ufw enable'."
            fi
            ;;
        rsync)
            install_or_update rsync
            ;;
        filebrowser)
            FILEBROWSER_DIR="/home/filebrowser"
            if [ ! -d "$FILEBROWSER_DIR" ]; then
                echo "Creating $FILEBROWSER_DIR..."
                sudo mkdir -p "$FILEBROWSER_DIR"
                sudo chown "$USER":"$USER" "$FILEBROWSER_DIR"
            fi

            if ! command -v filebrowser >/dev/null 2>&1; then
                echo "Installing Filebrowser..."
                curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
            else
                echo "Filebrowser is already installed."
            fi

            LOCAL_IP=$(hostname -I | awk '{print $1}')

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

            echo "Enabling and starting Filebrowser service..."
            sudo systemctl daemon-reexec
            sudo systemctl daemon-reload
            sudo systemctl enable filebrowser
            sudo systemctl start filebrowser
            ;;
        *)
            echo "Unknown option: $app"
            ;;
    esac
done

# Offer symlink option if filebrowser was installed
if [[ " ${install_selection[@]} " =~ " filebrowser " ]]; then
    read -p "Do you want to symlink a folder into /home/filebrowser/? (y/n): " want_symlink
    if [[ "$want_symlink" =~ ^[Yy]$ ]]; then
        read -p "Enter the source directory to symlink: " src
        read -p "Enter the name for the destination folder (relative to /home/filebrowser/): " dest
        dest_path="/home/filebrowser/$dest"

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
        echo "No symlink selected. Setup complete."
    fi
fi

echo "Setup complete."
