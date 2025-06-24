#!/bin/bash

# Exit on error
set -e

CONFIG_DIR="$HOME"
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
    error "config.yml not found at $CONFIG_FILE. Please ensure it exists."
    exit 1
fi

# Read current values
declare -A config
config[project]=$(grep '^custom_metrics_bigquery_project:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"')
config[location]=$(grep '^custom_metrics_location:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"')
config[credentials]=$(grep '^custom_metrics_credentials_path:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"')
config[interval]=$(grep '^custom_metrics_collection_interval:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"')

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
if [ -z "$cred_path" ]; then cred_path="$DEFAULT_CRED_PATH"; fi
echo "Current Google Credentials Path: $cred_path"
if [ ! -f "$cred_path" ]; then
    echo "Credentials file not found at $cred_path."
    echo "Paste your Google credentials JSON below. When finished, type END on a new line:"
    json_input=""
    while IFS= read -r line; do
        if [[ "$line" == "END" ]]; then
            break
        fi
        json_input+="$line"$'\n'
    done
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
fi
config[credentials]="$cred_path"

echo "Current Collection Interval: ${config[interval]}"
read -p "Enter collection interval (e.g., 1h) [${config[interval]}]: " input
if [ -n "$input" ]; then config[interval]="$input"; fi

echo
echo "Summary of BigQuery configuration to be saved:"
echo "  Project: ${config[project]}"
echo "  Location: ${config[location]}"
echo "  Credentials: ${config[credentials]}"
echo "  Interval: ${config[interval]}"
read -p "Is this correct? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
    echo "Aborting. No changes made."
    exit 1
fi

# Update config.yml
sed -i "" "s|^custom_metrics_bigquery_project:.*|custom_metrics_bigquery_project: \"${config[project]}\"|" "$CONFIG_FILE"
sed -i "" "s|^custom_metrics_location:.*|custom_metrics_location: \"${config[location]}\"|" "$CONFIG_FILE"
sed -i "" "s|^custom_metrics_credentials_path:.*|custom_metrics_credentials_path: \"${config[credentials]}\"|" "$CONFIG_FILE"
sed -i "" "s|^custom_metrics_collection_interval:.*|custom_metrics_collection_interval: \"${config[interval]}\"|" "$CONFIG_FILE"

log "BigQuery configuration updated in $CONFIG_FILE." 