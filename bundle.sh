#!/bin/bash

set -e

# Color Definitions
CYAN='\033[1;36m'      # Brighter Cyan for emphasis
GREEN='\033[1;32m'     # Brighter Green for success
YELLOW='\033[1;33m'    # Brighter Yellow for warnings
RED='\033[1;31m'       # Brighter Red for errors
RESET='\033[0m'        # Reset colors for normal text

# Text-based Icon Definitions
CHECK_ICON="[✔️]"
WARNING_ICON="[⚠️]"
INFO_ICON="[INFO]"
ERROR_ICON="[❌]"
FOLDER_ICON="[📂]"
FILEBROWSER_ICON="[📄]"

# Installable options
declare -A options=(
    [1]="nano"
    [2]="ufw"
    [3]="rsync"
    [4]="filebrowser"
)

# Prompt user to choose
echo -e "${CYAN}Select what to install:${RESET}"
for i in "${!options[@]}"; do
    echo -e "  $i) ${options[$i]}"
done
echo -e "  All) ${YELLOW}Install all of the above${RESET}"

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
    echo -e "${ERROR_ICON} ${RED}Invalid selection. Exiting.${RESET}"
    exit 1
fi

echo -e "${INFO_ICON} ${CYAN}Updating package lists...${RESET}"
sudo apt update

# Function to check and install/update packages
install_or_update() {
    local pkg=$1
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo -e "${CHECK_ICON} ${GREEN}$pkg is already installed. Checking for updates...${RESET}"
        sudo apt install --only-upgrade -y "$pkg"
    else
        echo -e "${CHECK_ICON} ${GREEN}Installing $pkg...${RESET}"
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
            echo -e "${INFO_ICON} ${CYAN}Setting UFW rule to allow SSH from the local network...${RESET}"

            # Get the local IP address
            LOCAL_IP=$(hostname -I | awk '{print $1}')

            # Automatically determine the subnet based on the local IP address
            NETWORK_SUBNET=$(echo $LOCAL_IP | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*/\1.0\/24/')

            echo -e "${CHECK_ICON} ${GREEN}Setting UFW rule to allow SSH from $NETWORK_SUBNET...${RESET}"
            sudo ufw allow from $NETWORK_SUBNET to any port 22 proto tcp
            echo -e "${CHECK_ICON} ${GREEN}UFW rule added. (Note: UFW is not enabled by default.)${RESET}"

            # Show current UFW status and rules
            echo -e ""
            echo -e "${INFO_ICON} ${CYAN}🔒 Current UFW Status and Rules:${RESET}"
            sudo ufw status verbose

            # Ask if the user wants to enable UFW
            read -p "Do you want to enable UFW now? (y/n): " enable_ufw
            if [[ "$enable_ufw" =~ ^[Yy]$ ]]; then
                sudo ufw enable
                echo -e "${CHECK_ICON} ${GREEN}UFW has been enabled.${RESET}"
            else
                echo -e "${WARNING_ICON} ${YELLOW}UFW remains disabled. You can enable it later using 'sudo ufw enable'.${RESET}"
            fi
            ;;
        rsync)
            install_or_update rsync
            ;;
        filebrowser)
            FILEBROWSER_DIR="/home/filebrowser"
            if [ ! -d "$FILEBROWSER_DIR" ]; then
                echo -e "${FOLDER_ICON} ${CYAN}Creating $FILEBROWSER_DIR...${RESET}"
                sudo mkdir -p "$FILEBROWSER_DIR"
                sudo chown "$USER":"$USER" "$FILEBROWSER_DIR"
            fi

            if ! command -v filebrowser >/dev/null 2>&1; then
                echo -e "${FILEBROWSER_ICON} ${CYAN}Installing Filebrowser...${RESET}"
                curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
            else
                echo -e "${CHECK_ICON} ${GREEN}Filebrowser is already installed.${RESET}"
            fi

            LOCAL_IP=$(hostname -I | awk '{print $1}')

            FILEBROWSER_CONFIG="/etc/filebrowser.json"
            echo -e "${INFO_ICON} ${CYAN}Creating Filebrowser config at $FILEBROWSER_CONFIG...${RESET}"
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
            echo -e "${INFO_ICON} ${CYAN}Creating systemd service for Filebrowser...${RESET}"
            sudo tee "$FILEBROWSER_SERVICE" >/dev/null <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -c /etc/filebrowser.json

[Install]
WantedBy=multi-user.target
EOF

            echo -e "${INFO_ICON} ${CYAN}Enabling and starting Filebrowser service...${RESET}"
            sudo systemctl daemon-reexec
            sudo systemctl daemon-reload
            sudo systemctl enable filebrowser
            sudo systemctl start filebrowser
            ;;
        *)
            echo -e "${ERROR_ICON} ${RED}Unknown option: $app${RESET}"
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
                echo -e "${CHECK_ICON} ${GREEN}Symlink created: $dest_path -> $src${RESET}"
            else
                echo -e "${WARNING_ICON} ${YELLOW}Destination $dest_path already exists. Skipping symlink.${RESET}"
            fi
        else
            echo -e "${ERROR_ICON} ${RED}Source directory $src does not exist. Skipping symlink.${RESET}"
        fi
    else
        echo -e "${INFO_ICON} ${CYAN}No symlink selected. Setup complete.${RESET}"
    fi
fi

# Check if we're inside a git repo
if [ -d .git ]; then
    echo -e ""
    echo -e "${INFO_ICON} ${CYAN}🔄 Updating bundle.sh from the latest repo version...${RESET}"

    # Fetch the latest updates from the remote
    git fetch origin

    # Checkout the latest version of bundle.sh from the current branch
    git checkout origin/$(git rev-parse --abbrev-ref HEAD) -- bundle.sh

    # Inform user
    echo -e "${CHECK_ICON} ${GREEN}bundle.sh has been updated to the latest version from the repo.${RESET}"
else
    echo -e "${WARNING_ICON} ${YELLOW}Not a git repository, skipping bundle.sh update.${RESET}"
fi

echo -e "${CHECK_ICON} ${GREEN}Setup complete.${RESET}"
