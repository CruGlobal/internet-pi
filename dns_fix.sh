#!/bin/bash

sudo bash -c "grep -q '^nameserver 1.1.1.1' /etc/resolv.conf || sudo sed -i '/^nameserver/cnameserver 1.1.1.1' /etc/resolv.conf || echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolv.conf" && sudo bash -c "grep -q '^nameserver 1.0.0.1' /etc/resolv.conf || echo 'nameserver 1.0.0.1' | sudo tee -a /etc/resolv.conf"