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
        sed -i 's/^custom_metrics_bigquery_project: ".*"/custom_metrics_bigquery_project: ""/' "$CONFIG_FILE"
        sed -i 's/^custom_metrics_location: ".*"/custom_metrics_location: ""/' "$CONFIG_FILE"
        sed -i 's|^custom_metrics_credentials_path: ".*"|custom_metrics_credentials_path: "config/credentials.json"|' "$CONFIG_FILE"
        sed -i 's/^custom_metrics_collection_interval: ".*"/custom_metrics_collection_interval: ""/' "$CONFIG_FILE"
    else
        error "config.yml not found at $CONFIG_FILE and example.config.yml not found in $CONFIG_DIR. Please ensure one exists."
        exit 1
    fi
fi

# Read current values
declare -A config
log "Reading current configuration..."
config[project]=$(grep '^custom_metrics_bigquery_project:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[location]=$(grep '^custom_metrics_location:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[credentials]=$(grep '^custom_metrics_credentials_path:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
config[interval]=$(grep '^custom_metrics_collection_interval:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Debug output
log "Current configuration values:"
echo "Project: '${config[project]}'"
echo "Location: '${config[location]}'"
echo "Credentials path: '${config[credentials]}'"
echo "Interval: '${config[interval]}'"
echo

# Prompt for each value
echo
echo "BigQuery Configuration (leave blank to keep current value)"
echo "--------------------------------------------------------"
echo "Current BigQuery Project: ${config[project]}"
read -p "Enter BigQuery Project ID [${config[project]}]: " input
if [ -n "$input" ]; then config[project]="$input"; fi

echo "Current Location: ${config[location]}"
read -p "Enter Location (ex: Miami_florida_south_office) [${config[location]}]: " input
if [ -n "$input" ]; then config[location]="$input"; fi

# Credentials JSON
cred_path="${config[credentials]}"
if [ -z "$cred_path" ]; then 
    cred_path="config/credentials.json"  # Make this relative by default
fi

# Remove any template variables that might be in the path and clean it up
cred_path=$(echo "$cred_path" | sed 's/{{[^}]*}}//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# If path is not absolute (doesn't start with /), make it relative to PWD
if [[ "$cred_path" != /* ]] && [[ "$cred_path" != "" ]]; then
    cred_path="$PWD/$cred_path"
fi

echo "Current Google Credentials Path: $cred_path"
if [ ! -f "$cred_path" ]; then
    # Ensure the directory exists
    mkdir -p "$(dirname "$cred_path")"
    echo "Credentials file not found at $cred_path."
    echo "Paste your Google credentials JSON (as a single line):"
    read -r json_input
    if [ -n "$json_input" ]; then
        echo "$json_input" > "$cred_path"
        chmod 600 "$cred_path"
        log "Saved Google credentials JSON to $cred_path."
    else
        error "No credentials provided. Aborting."
        exit 1
    fi
else
    echo "Credentials file exists at $cred_path."
    read -p "Do you want to update the credentials? [y/N]: " update_creds
    if [[ "$update_creds" =~ ^[Yy] ]]; then
        echo "Paste your new Google credentials JSON (as a single line):"
        read -r json_input
        if [ -n "$json_input" ]; then
            echo "$json_input" > "$cred_path"
            chmod 600 "$cred_path"
            log "Updated Google credentials JSON at $cred_path."
        else
            warn "No new credentials provided. Keeping existing file."
        fi
    else
        log "Keeping existing credentials file."
    fi
fi
config[credentials]="$cred_path"

# TODO allow users to customize this. default to 5 minutes
# echo "Current Collection Interval: ${config[interval]}"
# read -p "Enter collection interval (e.g., 1h) [${config[interval]}]: " input
# if [ -n "$input" ]; then config[interval]="$input"; fi
config[interval]="5m"  # Default to 5 minutes

# Add tables configuration
config[tables]="speed,ping"  # Default tables

echo
echo "Summary of BigQuery configuration to be saved:"
echo "  Project: ${config[project]}"
echo "  Location: ${config[location]}"
echo "  Credentials: ${config[credentials]}"
echo "  Interval: ${config[interval]}"
echo "  Tables: ${config[tables]}"
read -p "Is this correct? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
    echo "Aborting. No changes made."
    exit 1
fi

# Update config.yml with proper file path - Linux compatible sed
sed -i "s|^custom_metrics_bigquery_project:.*|custom_metrics_bigquery_project: \"${config[project]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_location:.*|custom_metrics_location: \"${config[location]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_credentials_path:.*|custom_metrics_credentials_path: \"${config[credentials]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_collection_interval:.*|custom_metrics_collection_interval: \"${config[interval]}\"|" "$CONFIG_FILE"
sed -i "s|^custom_metrics_tables:.*|custom_metrics_tables: \"${config[tables]}\"|" "$CONFIG_FILE"

log "BigQuery configuration updated in $CONFIG_FILE." 