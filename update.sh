#!/bin/bash

# Configuration
REPO_OWNER="${REPO_OWNER:-roguisharcanetrickster}"
REPO_NAME="${REPO_NAME:-internet-pi}"
BRANCH="${BRANCH:-master}"
# UPDATE_INTERVAL=3600  # Check every hour
UPDATE_INTERVAL=500 # DEV MODE check every 5 minutes
LOG_FILE="${LOG_FILE:-/var/log/internet-pi-updates.log}"
LOCK_FILE="${LOCK_FILE:-/tmp/internet-pi-update.lock}"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if another update is running
if [ -f "$LOCK_FILE" ]; then
    log "Update already in progress, exiting"
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"


# Get the latest commit hash from GitHub
LATEST_COMMIT=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$BRANCH" | grep -m 1 '"sha":' | cut -d'"' -f4)

if [ -z "$LATEST_COMMIT" ]; then
    log "Failed to get latest commit hash"
    rm -f "$LOCK_FILE"
    exit 1
fi

# Get current commit hash
CURRENT_COMMIT=$(git rev-parse HEAD)

# Check if update is needed
if [ "$LATEST_COMMIT" != "$CURRENT_COMMIT" ]; then
    log "Update available. Current: $CURRENT_COMMIT, Latest: $LATEST_COMMIT"
    
    # Pull latest changes
    git fetch origin
    git reset --hard "origin/$BRANCH"
    
    # Run the deployment
    log "Running deployment..."
    ~/.local/bin/ansible-playbook main.yml -e "runner_user=$USER" -i inventory.ini
    
    # Check if deployment was successful
    if [ $? -eq 0 ]; then
        log "Deployment completed successfully"
    else
        log "Deployment failed"
        rm -f "$LOCK_FILE"
        exit 1
    fi
else
    log "No updates available"
fi

# Remove lock file
rm -f "$LOCK_FILE" 