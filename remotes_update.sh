#!/bin/bash
# run quick update on remote hosts

ansible-galaxy collection install -r requirements.yml
ansible -i remotes_inventory.ini scry_pi -m ping
ansible-playbook -i remotes_inventory.ini playbooks/remote_scry_update.yml