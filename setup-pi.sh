#!/bin/bash

# Exit on error
set -e

# Configuration
REPO_OWNER="roguisharcanetrickster"
REPO_NAME="internet-pi"
BRANCH="master"
INSTALL_DIR="/opt/internet-pi"
BACKUP_DIR="/opt/internet-pi.backup"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install required packages
log "Installing required packages..."
apt-get update
apt-get install -y git python3 python3-pip

# Handle existing installation
if [ -d "$INSTALL_DIR" ]; then
    if [ -d "$INSTALL_DIR/.git" ]; then
        warn "Existing installation found. Updating instead of fresh install..."
        cd "$INSTALL_DIR"
        git fetch origin
        git reset --hard "origin/$BRANCH"
    else
        warn "Directory exists but is not a git repository. Removing all contents for a fresh install..."
        rm -rf "$INSTALL_DIR"/*
        rm -rf "$INSTALL_DIR"/.[!.]* 2>/dev/null || true
        log "Emptied $INSTALL_DIR for a fresh clone."
    fi
else
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
fi

# Clone/update the repository
if [ ! -d "$INSTALL_DIR/.git" ]; then
    log "Cloning repository..."
    git clone "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$INSTALL_DIR"
fi

# Copy default config files if they do not exist
cd "$INSTALL_DIR"
if [ ! -f config.yml ]; then
    log "Creating config.yml from example.config.yml..."
    cp example.config.yml config.yml
fi
if [ ! -f inventory.ini ]; then
    log "Creating inventory.ini from example.inventory.ini..."
    cp example.inventory.ini inventory.ini
fi

# Install Ansible
log "Installing Ansible..."
# Remove EXTERNALLY-MANAGED file if it exists to avoid pip issues
rm -f /usr/lib/python3.11/EXTERNALLY-MANAGED
rm -f /usr/lib/python3.10/EXTERNALLY-MANAGED
rm -f /usr/lib/python3.9/EXTERNALLY-MANAGED
pip3 install --user ansible

# Ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Copy the update script
log "Setting up update mechanism..."
cp "$INSTALL_DIR/update.sh" /usr/local/bin/update-internet-pi
chmod +x /usr/local/bin/update-internet-pi

# Copy the systemd service
cp "$INSTALL_DIR/internet-pi-updater.service" /etc/systemd/system/

# Reload systemd
log "Configuring system service..."
systemctl daemon-reload

# Enable and start the service
systemctl enable internet-pi-updater.service
systemctl start internet-pi-updater.service

log "Setup complete! The Pi will now automatically check for updates every hour."
log "You can manually check for updates by running: update-internet-pi"