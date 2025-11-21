#!/bin/bash

# Log starting time
echo "---" >> /var/log/internet-pi-updates.log
echo "Starting system update at $(date)" >> /var/log/internet-pi-updates.log

# Update and upgrade
/usr/bin/apt-get update >> /var/log/internet-pi-updates.log 2>&1
/usr/bin/apt-get upgrade -y >> /var/log/internet-pi-updates.log 2>&1

# Log finishing time
echo "Finished system update at $(date)" >> /var/log/internet-pi-updates.log
echo "---" >> /var/log/internet-pi-updates.log
