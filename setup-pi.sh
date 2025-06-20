#!/bin/bash

# Exit on error
set -e

# Configuration
REPO_OWNER="your-github-username"
REPO_NAME="internet-pi"
BRANCH="master"
INSTALL_DIR="/opt/internet-pi"

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install required packages
apt-get update
apt-get install -y git python3 python3-pip

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Clone the repository
git clone "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$INSTALL_DIR"

# Install Ansible
pip3 install --user ansible

# Copy the update script
cp "$INSTALL_DIR/update.sh" /usr/local/bin/update-internet-pi
chmod +x /usr/local/bin/update-internet-pi

# Copy the systemd service
cp "$INSTALL_DIR/internet-pi-updater.service" /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable and start the service
systemctl enable internet-pi-updater.service
systemctl start internet-pi-updater.service

echo "Setup complete! The Pi will now automatically check for updates every hour." 