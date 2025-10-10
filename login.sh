#!/bin/bash

# Exit on error
set -e

CONFIG_DIR="$PWD"
CONFIG_FILE="$CONFIG_DIR/config.yml"
CRED_KEY="custom_metrics_credentials_path"
DEFAULT_CRED_PATH="$CONFIG_DIR/credentials.json"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}
warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}
error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

if [ ! -f "$CONFIG_FILE" ]; then
    # try cp example.config.yml
    if [ -f "$CONFIG_DIR/example.config.yml" ]; then
        cp "$CONFIG_DIR/example.config.yml" "$CONFIG_FILE"
        log "Created $CONFIG_FILE from example.config.yml."
        # Clean up default example values - Linux compatible sed
        sed -i 's|^custom_metrics_turso_db_url: ".*"|custom_metrics_turso_db_url: ""|' "$CONFIG_FILE"
        sed -i 's|^custom_metrics_turso_auth_token: ".*"|custom_metrics_turso_auth_token: ""|' "$CONFIG_FILE"
        sed -i 's/^custom_metrics_collection_interval: ".*"/custom_metrics_collection_interval: ""/' "$CONFIG_FILE"
    else
        error "config.yml not found at $CONFIG_FILE and example.config.yml not found in $CONFIG_DIR. Please ensure one exists."
        exit 1
    fi
fi

# Read current values
declare -A config
log "Reading current configuration..."
config[db_url]=$(grep '^custom_metrics_turso_db_url:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[auth_token]=$(grep '^custom_metrics_turso_auth_token:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[location]=$(grep '^custom_metrics_location:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[collection_interval]=$(grep '^custom_metrics_collection_interval:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[sync_interval]=$(grep '^custom_metrics_sync_interval:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[custom_metrics_location]=$(grep '^custom_metrics_location:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[tables]=$(grep '^custom_metrics_tables:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Debug output
log "Current configuration values:"
echo "Turso DB URL: '${config[db_url]}'"
echo "Turso Auth Token: '${config[auth_token]}'"
echo "Location: '${config[location]}'"
echo "Collection Interval: '${config[collection_interval]}'"
echo "Sync Interval: '${config[sync_interval]}'"
echo "Tables: '${config[tables]}'"
echo

# Prompt for each value
echo
echo "Turso Configuration (leave blank to keep current value)"
echo "--------------------------------------------------------"
echo "Current Turso DB URL: ${config[db_url]}"
read -p "Enter Turso Database URL [${config[db_url]}]: " input
if [ -n "$input" ]; then config[db_url]="$input"; fi

echo "Current Turso Auth Token: ${config[auth_token]}"
read -p "Enter Turso Auth Token [${config[auth_token]}]: " input
if [ -n "$input" ]; then config[auth_token]="$input"; fi

echo "Current Location: ${config[location]}"
read -p "Enter Location (e.g., home, office, remote) [${config[location]}]: " input
if [ -n "$input" ]; then config[location]="$input"; fi

echo "Current Collection Interval: ${config[collection_interval]}"
read -p "Enter Collection Interval (e.g., 5m, 1h) [${config[collection_interval]}]: " input
if [ -n "$input" ]; then config[collection_interval]="$input"; fi

echo "Current Sync Interval: ${config[sync_interval]}"
read -p "Enter Sync Interval (e.g., 1444) [${config[sync_interval]}]: " input
if [ -n "$input" ]; then config[sync_interval]="$input"; fi

echo "Current Tables: ${config[tables]}"
read -p "Enter Tables (comma-separated, e.g., speed,ping) [${config[tables]}]: " input
if [ -n "$input" ]; then config[tables]="$input"; else config[tables]="speed,ping"; fi # Default if blank

echo
echo "Summary of Turso configuration to be saved:"
echo "  DB URL: ${config[db_url]}"
echo "  Auth Token: ${config[auth_token]}"
echo "  Location: ${config[location]}"
echo "  Collection Interval: ${config[collection_interval]}"
echo "  Sync Interval: ${config[sync_interval]}"
echo "  Tables: ${config[tables]}"
read -p "Is this correct? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
    echo "Aborting. No changes made."
    exit 1
fi

# Update config.yml with proper file path - Linux compatible sed
sed -i "s|^custom_metrics_turso_db_url:.*|custom_metrics_turso_db_url: \"${config[db_url]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_turso_auth_token:.*|custom_metrics_turso_auth_token: \"${config[auth_token]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_location:.*|custom_metrics_location: \"${config[location]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_collection_interval:.*|custom_metrics_collection_interval: \"${config[collection_interval]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_sync_interval:.*|custom_metrics_sync_interval: \"${config[sync_interval]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_tables:.*|custom_metrics_tables: \"${config[tables]}\"|" "$CONFIG_FILE"

log "Turso configuration updated in $CONFIG_FILE."
