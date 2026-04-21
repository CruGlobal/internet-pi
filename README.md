# Internet Pi

[![CI](https://github.com/CruGlobal/internet-pi/workflows/test/badge.svg?event=push)](https://github.com/CruGlobal/internet-pi/actions?query=workflow%3Atest)

---

## 🚀 Quick Start: Install on Raspberry Pi

To install Internet Pi on a fresh Raspberry Pi, just run the following commands in your terminal:

```bash
# Clone the repository
sudo apt-get update && sudo apt-get install -y git
# You can use any directory you like, e.g. $HOME/internet-pi
cd $HOME

git clone https://github.com/CruGlobal/internet-pi.git
cd internet-pi
chmod +x ./setup-pi.sh

# Run the setup script
sudo ./setup-pi.sh
```

This will:
- Install all required dependencies
- Clone the project
- Install Ansible
- Set up the auto-updater (systemd service, requires root)
- **Run the Ansible playbook to fully configure your Pi**

After running the script, your Pi will be fully set up and will automatically check for updates.

If dns breaks these cli commands should fix it
```
sudo bash -c "grep -q '^nameserver 1.1.1.1' /etc/resolv.conf || sudo sed -i '/^nameserver/cnameserver 1.1.1.1' /etc/resolv.conf || echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolv.conf" && sudo bash -c "grep -q '^nameserver 1.0.0.1' /etc/resolv.conf || echo 'nameserver 1.0.0.1' | sudo tee -a /etc/resolv.conf"
```
---

**A Raspberry Pi Configuration for Internet connectivity**

I have had a couple Pis doing random Internet-related duties for years. It's finally time to formalize their configs and make all the DNS/ad-blocking/monitoring stuff encapsulated into one Ansible project.

So that's what this is.

## Features

## Custom Metrics Service

The Custom Metrics container queries Prometheus and submits rows to a Google Form. The only host label from this stack is `DEVICE_ID`, set from `custom_metrics_device_id` in `config.yml`. No separate device-location or geo field is configured here.

### Setup

Requires `monitoring_enable: true` (same Prometheus stack). In `config.yml`:

```yaml
custom_metrics_enable: true
custom_metrics_device_id: ""   # set to a stable opaque label, e.g. hostname or inventory id
```

Then run the playbook:

```bash
ansible-playbook main.yml
```

### Metrics Collected

The service collects the following metrics from Prometheus (among others configured in the custom-metrics image):

- `speedtest_download_bits_per_second`
- `speedtest_upload_bits_per_second`
- `speedtest_ping_latency_milliseconds`

These are included in form submissions for long-term analysis.

**Internet Monitoring**: Installs a few Docker containers to monitor your Internet connection with Speedtest.net speedtests and HTTP tests so you can see uptime, ping stats, and speedtest results over time.

Other features:

**IMPORTANT NOTE**: If you use the included Internet monitoring, it will download a decently-large amount of data through your Internet connection on a daily basis. Don't use it, or tune the `internet-monitoring` setup to not run the speedtests as often, if you have a metered connection!

## Recommended Pi and OS

You should use a Raspberry Pi 4 model B or better. The Pi 4 and later generations of Pi include a full gigabit network interface and enough I/O to reliably measure fast Internet connections.

Older Pis work, but have many limitations, like a slower CPU and sometimes very-slow NICs that limit the speed test capability to 100 Mbps or 300 Mbps on the Pi 3 model B+.

Other computers and VMs may run this configuration as well, but it is only regularly tested on a Raspberry Pi.

The configuration is tested against Raspberry Pi OS, both 64-bit and 32-bit, and runs great on that or a generic Debian installation.

## Setup

  1. [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html). The easiest way (especially on Pi or a Debian system) is via Pip:
     1. (If on Pi/Debian): `sudo apt-get install -y python3-pip`
     2. (Everywhere): `pip3 install ansible`
     3. If you get an error like "externally-managed-environment", follow [this guide to fix it](https://www.jeffgeerling.com/blog/2023/how-solve-error-externally-managed-environment-when-installing-pip3), then run `pip3 install ansible` again.
     4. Make sure Ansible is in your PATH: `export PATH=$PATH:~/.local/bin` (and consider [adding it permanently](https://askubuntu.com/a/1113838)).
  2. Clone this repository: `git clone https://github.com/CruGlobal/internet-pi.git`, then enter the repository directory: `cd internet-pi`.
  3. Install requirements: `ansible-galaxy collection install -r requirements.yml` (if you see `ansible-galaxy: command not found`, restart your SSH session or reboot the Pi and try again)
  4. Make copies of the following files and customize them to your liking:
     - `example.inventory.ini` to `inventory.ini` (replace IP address with your Pi's IP, or comment that line and uncomment the `connection=local` line if you're running it on the Pi you're setting up).
     - `example.config.yml` to `config.yml`
  5. Run the playbook: `ansible-playbook main.yml`

> **If running locally on the Pi**: You may encounter an error like "Error while fetching server API version" or "connect: permission denied". If you do, please either reboot or log out and log back in, then run the playbook again.

## Usage


### Configurations and internet-monitoring images

Upgrades for the other configurations are similar (go into the directory, and run the same `docker compose` commands. Make sure to `cd` into the `config_dir` that you use in your `config.yml` file. 

Alternatively, you may update the initial `config.yml` in the the repo folder and re-run the main playbook: `ansible-playbook main.yml`. At some point in the future, a dedicated upgrade playbook may be added, but for now, upgrades may be performed manually as shown above.

## Backups

A guide for backing up the configurations and historical data will be posted here as part of [Issue #194: Create Backup guide](https://github.com/geerlingguy/internet-pi/issues/194).

## Uninstall

To remove `internet-pi` from your system, run the following commands (assuming the default install location of `~`, your home directory):

```bash
# Enter the internet-monitoring directory.
cd ~/internet-monitoring

# Shut down internet-monitoring containers and delete data volumes.
docker compose down -v

# Delete all the unused container images, volumes, etc. from the system.
docker system prune -af
```

## License

MIT

## Author

This project was created in 2021 by [Jeff Geerling](https://www.jeffgeerling.com/).
