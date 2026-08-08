#!/usr/bin/env bash
set -euo pipefail

CP_IP=""
K3S_TOKEN=""
NODE_NAME=""

# ---------------------------
# 0. Parsing des arguments
# ---------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --cp-ip)
      CP_IP="$2"
      shift 2
      ;;
    --token)
      K3S_TOKEN="$2"
      shift 2
      ;;
    --node-name)
      NODE_NAME="$2"
      shift 2
      ;;
    *)
      echo "Argument inconnu: $1"
      exit 1
      ;;
  esac
done

for var in CP_IP K3S_TOKEN NODE_NAME; do
  if [ -z "${!var}" ]; then
    echo "Erreur : $var n'est pas défini"
    exit 1
  fi
done

echo "[0/6] Variables OK :"
echo "CONTROL_PLANE_IP=$CP_IP"
echo "WORKER_NODE_NAME=$NODE_NAME"

# ---------------------------
# 1. Config réseau
# ---------------------------
echo "[1/6] Configuration réseau..."
if ping -c1 1.1.1.1 &>/dev/null; then
  echo "Réseau déjà opérationnel."
else
  read -p "Voulez-vous configurer le wifi ou ethernet ? (w/e) " NET_CHOICE
  if [ "$NET_CHOICE" == "w" ]; then
    read -p "Nom du wifi : " WIFI_NAME
    read -s -p "Mot de passe wifi : " WIFI_PASSWORD
    echo
    sudo tee /etc/netplan/00-config.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    wlp1s0:
      dhcp4: true
      access-points:
        "$WIFI_NAME":
          password: "$WIFI_PASSWORD"
EOF
  else
    sudo tee /etc/netplan/00-config.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp3s0:
      dhcp4: true
EOF
  fi
  sudo netplan generate
  sudo netplan apply
fi
ip a

# ---------------------------
# 2. SSH
# ---------------------------
echo "[2/6] Installation SSH..."
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# ---------------------------
# 3. Firewall
# ---------------------------
echo "[3/6] Activation firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 6443/tcp
sudo ufw enable

# ---------------------------
# 4. Tailscale
# ---------------------------
echo "[4/6] Installation Tailscale..."
sudo apt install -y tailscale
sudo systemctl enable --now tailscaled
echo "Connectez-vous à Tailscale (tailscale up --ssh)..."
sudo tailscale up --ssh
TAILSCALE_IP=$(tailscale ip -4)
echo "IP Tailscale détectée : $TAILSCALE_IP"
sudo ufw allow in on tailscale0

# ---------------------------
# 5. Ajouter le worker au cluster K3S
# ---------------------------
echo "[5/6] Ajout au cluster K3S..."
curl -sfL https://get.k3s.io | sh -s - agent \
  --server https://$CP_IP:6443 \
  --node-ip $TAILSCALE_IP \
  --flannel-iface tailscale0 \
  --token $K3S_TOKEN \
  --node-name $NODE_NAME

echo "Le worker $NODE_NAME a été ajouté au cluster."

# ---------------------------
# 6. Vérification du cluster
# ---------------------------
echo "[6/6] Vérification des nodes K3S..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo kubectl get nodes

# ---------------------------
# 7. Inotify config for log collection
# ---------------------------
sudo sysctl -w fs.inotify.max_user_watches=524288
sudo sysctl -w fs.inotify.max_user_instances=512
echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Setup worker terminé !"
