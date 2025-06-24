#!/bin/bash

# Exit on error
set -e

# Configuration variables
INSTALL_DIR="/opt/internet-pi"
CONFIG_DIR="$HOME"
LOG_FILE="/var/log/internet-pi-updates.log"
SETUP_SCRIPT="$INSTALL_DIR/setup-pi.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
}

setup_config() {
    log "Setting up configuration..."
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    # Copy example config if config doesn't exist
    if [ ! -f "$CONFIG_DIR/config.yml" ] && [ -f "$INSTALL_DIR/example.config.yml" ]; then
        cp "$INSTALL_DIR/example.config.yml" "$CONFIG_DIR/config.yml"
        # Generate a random password for pihole_password
        RANDOM_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom | head -c 20)
        sed -i "s/^pihole_password: .*/pihole_password: \"$RANDOM_PASS\"/" "$CONFIG_DIR/config.yml"
        log "Created default config.yml with a random Pi-hole password. Please check $CONFIG_DIR/config.yml."
    fi
    # Copy example inventory if inventory doesn't exist
    if [ ! -f "$CONFIG_DIR/inventory.ini" ] && [ -f "$INSTALL_DIR/example.inventory.ini" ]; then
        cp "$INSTALL_DIR/example.inventory.ini" "$CONFIG_DIR/inventory.ini"
        # Configure for local connection by default
        sed -i 's/^192.168.1.10/#192.168.1.10/' "$CONFIG_DIR/inventory.ini"
        sed -i 's/^#127.0.0.1/127.0.0.1/' "$CONFIG_DIR/inventory.ini"
        log "Created default inventory.ini configured for local connection"
    fi
}

report_enabled_services() {
    local config_file="$CONFIG_DIR/config.yml"
    if [ ! -f "$config_file" ]; then
        warn "config.yml not found at $config_file"
        return
    fi
    echo -e "\nEnabled services in config.yml:" | tee -a "$LOG_FILE"
    grep -E '^(custom_metrics_enable|pihole_enable|monitoring_enable|shelly_plug_enable|airgradient_enable|starlink_enable):' "$config_file" | \
    while IFS=: read -r key value; do
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        if [[ "$value" == "true" ]]; then
            echo -e "  ${GREEN}$key${NC}: enabled" | tee -a "$LOG_FILE"
        else
            echo -e "  ${YELLOW}$key${NC}: disabled" | tee -a "$LOG_FILE"
        fi
    done
}

show_status() {
    log "Checking Internet Pi status..."
    report_enabled_services
    # Check if services are running
    if command -v docker &> /dev/null; then
        echo -e "\nDocker containers status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        warn "Docker not installed"
    fi
    # Check if monitoring is accessible
    if curl -s http://localhost:3030 &> /dev/null; then
        log "Grafana monitoring is accessible at http://localhost:3030"
    else
        warn "Grafana monitoring is not accessible"
    fi
    # Check if Pi-hole is accessible
    if curl -s http://localhost/admin &> /dev/null; then
        log "Pi-hole is accessible at http://localhost/admin"
    else
        warn "Pi-hole is not accessible"
    fi
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Manage Internet Pi installation and configuration"
    echo
    echo "Options:"
    echo "  install    Install Internet Pi (delegates to setup-pi.sh)"
    echo "  update     Update Internet Pi (delegates to setup-pi.sh)"
    echo "  status     Show status of Internet Pi services"
    echo "  help       Show this help message"
    echo
    echo "Run as root (sudo) for installation and updates"
}

update_setup_script() {
    log "Ensuring latest setup-pi.sh is present..."
    curl -fsSL "https://raw.githubusercontent.com/roguisharcanetrickster/internet-pi/master/setup-pi.sh" -o "$SETUP_SCRIPT"
    chmod +x "$SETUP_SCRIPT"
    log "setup-pi.sh updated to latest version."
}

# Ensure installation directory exists and is writable
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating installation directory: $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
fi

if [ ! -w "$INSTALL_DIR" ]; then
    echo "Setting ownership of $INSTALL_DIR to $USER"
    sudo chown "$USER:$USER" "$INSTALL_DIR"
fi

# Double-check we can write to the directory
if [ ! -w "$INSTALL_DIR" ]; then
    echo "ERROR: Cannot write to $INSTALL_DIR. Please check permissions and try again."
    exit 1
fi

# Main script execution
case "$1" in
    "install")
        check_root
        update_setup_script
        if [ ! -f "$SETUP_SCRIPT" ]; then
            error "setup-pi.sh not found in $INSTALL_DIR. Please clone the repository first."
            exit 1
        fi
        sudo bash "$SETUP_SCRIPT"
        setup_config
        show_status
        ;;
    "update")
        check_root
        if [ ! -f "$SETUP_SCRIPT" ]; then
            error "setup-pi.sh not found in $INSTALL_DIR. Please clone the repository first."
            exit 1
        fi
        sudo bash "$SETUP_SCRIPT"
        setup_config
        show_status
        ;;
    "status")
        show_status
        ;;
    "help"|"")
        show_help
        ;;
    *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac