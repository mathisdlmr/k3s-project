#!/bin/bash

set -euo pipefail

echo "Setup another (not the 1st) control-plane node for a HA K3S cluster"
echo "This script must be run once the first control-plane node is setup and running"
echo "This script was wrote for a ubuntu 24.04 LTS server"

TOKEN=""
INIT_NODE_IP=""

for arg in "$@"; do
  case $arg in
    --token=*) TOKEN="${arg#*=}" ;;
    --init-node-ip=*) INIT_NODE_IP="${arg#*=}" ;;
    *) echo "Usage: $0 --token=TOKEN --init-node-ip=IP" ; exit 1 ;;
  esac
done

if [ -z "$TOKEN" ]; then
  echo "Erreur : --token requis (récupéré en fin de setup-init-ha.sh)"
  exit 1
fi

# ---------------------------
# Collecte des paramètres
# ---------------------------
read -p "Nom de ce noeud : " NODE_NAME

echo ""
echo "=== Tailscale peers ==="
tailscale status
echo "========================"
echo ""

read -p "Nombre de noeuds control-plane au total : " NUM_MASTERS

MASTER_IPS=()
MASTER_NAMES=()
for i in $(seq 1 "$NUM_MASTERS"); do
  read -p "IP Tailscale du $i-e control-plane : " ip
  read -p "Nom du $i-e control-plane (ex: 5700u) : " name
  MASTER_IPS+=("$ip")
  MASTER_NAMES+=("$name")
done

# ---------------------------
# 1. Récupération de l'IP Tailscale
# ---------------------------
echo ""
echo "[1] Récupération de l'IP Tailscale..."
TAILSCALE_IP=$(tailscale ip -4)
echo "IP Tailscale de CE noeud : $TAILSCALE_IP"

# ---------------------------
# 2. Génération du tls-san
# ---------------------------
echo ""
echo "[2] Génération du tls-san..."
TLS_SAN="  - localhost\n  - 127.0.0.1"
for ip in "${MASTER_IPS[@]}"; do
  TLS_SAN="${TLS_SAN}\n  - ${ip}"
done

# ---------------------------
# 3. Installation de K3S
# ---------------------------
echo ""
echo "[3] Jonction au cluster K3S..."
sudo mkdir -p /etc/rancher/k3s

sudo tee /etc/rancher/k3s/config.yaml > /dev/null << EOF
server: https://${INIT_NODE_IP}:6443
token: ${TOKEN}

node-name: ${NODE_NAME}
node-ip: ${TAILSCALE_IP}

disable:
  - traefik
  - servicelb
  - kube-proxy

flannel-backend: none
disable-network-policy: true

tls-san:
$(printf '%b' "$TLS_SAN")
EOF

curl -sfL https://get.k3s.io | sh -s - server

# ---------------------------
# 4. Kubeconfig
# ---------------------------
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
export KUBECONFIG=~/.kube/config

echo ""
echo "Master ${NODE_NAME} ajouté au cluster."
kubectl get nodes -o wide