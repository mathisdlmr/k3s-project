#!/bin/bash
set -euo pipefail

echo "Fixing CPU C-states for AMD 5825U"

sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash processor.max_cstate=1"/' /etc/default/grub
sudo update-grub
sudo reboot