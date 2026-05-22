#!/bin/bash
# setup-ha.sh
# À lancer sur les masters SUIVANTS (pas le nœud init)
# Usage : ./setup-ha.sh --token=<TOKEN>
set -euo pipefail

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
read -p "Nom de CE nœud : " NODE_NAME

echo ""
echo "=== Tailscale peers ==="
tailscale status
echo "========================"
echo ""

read -p "Nombre de nœuds control-plane au total : " NUM_MASTERS

declare -a MASTER_IPS
declare -a MASTER_NAMES
for i in $(seq 1 "$NUM_MASTERS"); do
  read -p "IP Tailscale du $i-e control-plane : " ip
  read -p "Nom du $i-e control-plane (ex: 5700u) : " name
  MASTER_IPS+=("$ip")
  MASTER_NAMES+=("$name")
done

# ---------------------------
# 0. Préparation du nœud
# ---------------------------
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo modprobe br_netfilter
sudo modprobe overlay

cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# ---------------------------
# 1. Récupération de l'IP Tailscale
# ---------------------------
TAILSCALE_IP=$(tailscale ip -4)
echo "IP Tailscale de CE nœud : $TAILSCALE_IP"

# ---------------------------
# 2. Génération du tls-san
# ---------------------------
TLS_SAN="  - localhost\n  - 127.0.0.1"
for ip in "${MASTER_IPS[@]}"; do
  TLS_SAN="${TLS_SAN}\n  - ${ip}"
done

# ---------------------------
# 3. Installation de K3S (join)
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

etcd-arg:
  - "heartbeat-interval=100" 
  - "election-timeout=1000" 
  - "peer-dial-timeout=3s"
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