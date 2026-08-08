#!/bin/bash

set -euo pipefail

# 0. Parse arguments
MASTER_IPS=()
MASTER_NAMES=()

echo "[0] Verifying arguments..."
while [[ $# -ne 0 ]]; do
  case "$1" in
    --master-ips=*)
      ips="${1#*=}"
      IFS=',' read -r -a MASTER_IPS <<< "$ips"
      shift 1
      ;;
    --master-names=*)
      names="${1#*=}"
      IFS=',' read -r -a MASTER_NAMES <<< "$names"
      shift 1
      ;;
    *)
      echo "Usage: $0 --master-ips=IP1,IP2 --master-names=NAME1,NAME2"
      exit 1
      ;;
  esac
done

if [[ ${#MASTER_IPS[@]} -eq 0 ]]; then
  echo "Error: MASTER_IPS must be defined using --master-ips=IP1,IP2"
  exit 1
fi

if [[ ${#MASTER_NAMES[@]} -eq 0 ]]; then
  echo "Error: MASTER_NAMES must be defined using --master-names=NAME1,NAME2"
  exit 1
fi

# 1. Install Tailscale
echo ""
echo "[1] Install Tailscale VPN client..."
sudo dnf install tailscale -y
sudo systemctl start tailscaled
sudo tailscale up --operator=$USER

# 2. Install HAProxy
echo ""
echo "[2] Install HAProxy..."
sudo dnf update -y
sudo dnf install haproxy -y
sudo tee /etc/haproxy/haproxy.cfg > /dev/null << 'HAPROXYCFG'
global
    log /dev/log local0
    maxconn 4096
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5s
    timeout client  30s
    timeout server  30s
    retries 3

frontend k3s-api
    bind 127.0.0.1:6443
    default_backend k3s-masters

backend k3s-masters
    balance roundrobin
    option tcp-check
HAPROXYCFG

for i in "${!MASTER_IPS[@]}"; do
  echo "    server ${MASTER_NAMES[$i]} ${MASTER_IPS[$i]}:6443 check inter 2s fall 3 rise 2" | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null
done

sudo setsebool -P haproxy_connect_any=1
sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "HAProxy started on 127.0.0.1:6443"
echo "Backends : ${MASTER_IPS[@]}:6443"
echo ""
echo "Checking status :"
sudo systemctl status haproxy --no-pager

# 3. Prepare kubeconfig
echo ""
echo "[3] Prepare kubeconfig"
read -p "Enter the path to your kubeconfig file (default: ~/kubeconfig): " KUBECONFIG_PATH
KUBECONFIG_PATH=${KUBECONFIG_PATH:-~/kubeconfig}
if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  echo "Error: kubeconfig file not found at $KUBECONFIG_PATH"
  exit 1
fi
mkdir -p ~/.kube
sudo cp "$KUBECONFIG_PATH" ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

# 4. Setup kubectl
echo ""
echo "[4] Setup kubectl"
curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
echo "kubectl is ready to use"

# 5. Verify
echo ""
echo "[5] Verify installation"
kubectl get pods
echo "Ready to use Kubernetes !"