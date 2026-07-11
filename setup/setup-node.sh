#!/bin/bash

set -euo pipefail

echo "Setup secure Kubernetes node (K3S-ready)"
echo "This script was wrote for a ubuntu 24.04 LTS server"

# ---------------------------
# 1. SYSTEM UPDATE
# ---------------------------
echo "[1/9] System update..."
sudo apt update && sudo apt upgrade -y

# ---------------------------
# 2. BASE PACKAGES
# ---------------------------
echo "[2/9] Installing base packages..."
sudo apt install -y openssh-server ufw unattended-upgrades

# ---------------------------
# 3. SSH CONFIG
# ---------------------------
echo "[3/9] Securing SSH..."

mkdir -p ~/.ssh/authorized_keys
read -p "Enter your SSH public key: " SSH_PUBLIC_KEY
echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys

sudo rm /etc/ssh/sshd_config.d/50-cloud-init.conf # TODO : lire et si il contient "PasswordAuthentication yes" alors on override
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#*LoginGraceTime.*/LoginGraceTime 30/' /etc/ssh/sshd_config

sudo systemctl restart ssh

# ---------------------------
# 4. AUTO SECURITY UPDATES
# ---------------------------
echo "[4/9] Enabling unattended upgrades..."
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# ---------------------------
# 5. MODIFY KERNEL PARAMETERS
# ---------------------------
echo "[5/9] Modifying kernel parameters..."

# 5.1. Pas de swap car k3s ne sait pas le gérer
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 5.2. Activation des modules nécessaires pour k3s
sudo modprobe br_netfilter
sudo modprobe overlay

# 5.3. Activation du forwarding et de la gestion des paquets sur le bridge
cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# ---------------------------
# 6. INSTALL TAILSCALE
# ---------------------------
echo "[6/9] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

sudo systemctl enable --now tailscaled
read -p "Appuyer sur entrée une fois la connexion Tailscale établie..."

sudo tailscale up --ssh
TAILSCALE_IP=$(tailscale ip -4)
echo "Tailscale IP: $TAILSCALE_IP"

# ---------------------------
# 7. FIREWALL
# ---------------------------
echo "[7/9] Configuring firewall..."

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Tailscale WireGuard
sudo ufw allow 41641/udp

# On accepte ce qui vient du réseau Tailscale (tailscale0)
sudo ufw allow in on tailscale0

# LAN local
sudo ufw allow from 192.168.0.0/16

# SSH depuis Tailscale et LAN local
sudo ufw allow in on tailscale0 to any port 22
sudo ufw allow from 192.168.0.0/16 to any port 22

sudo ufw --force enable

# ---------------------------
# 8. Inotify config for log collection
# ---------------------------
echo "[8/9] Configuring inotify..."

sudo touch /etc/sysctl.d/99-k3s.conf
echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.d/99-k3s.conf
echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.d/99-k3s.conf
echo "fs.inotify.max_queued_events=65536" | sudo tee -a /etc/sysctl.d/99-k3s.conf
sudo sysctl --system

# ---------------------------
# 9. Final check on opened ports
# ---------------------------
echo "[9/9] Final checks on opened ports..."

echo "Open ports:"
ss -tulnp

echo "Firewall status:"
sudo ufw status verbose

echo "Node ready"