#!/bin/bash

set -euo pipefail

echo "Update Ubuntu 24.04 LTS server"

sudo apt update && sudo apt upgrade

sudo apt autoremove
sudo apt autoclean

sudo unattended-upgrades --dry-run

fwupdmgr upgrade
