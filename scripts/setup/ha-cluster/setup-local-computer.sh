#!/bin/bash

set -euo pipefail

echo "Setup a laptop to connect to a HA K3S cluster"

# ---------------------------
# 1. Parse arguments
# ---------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --master-ips=*) MASTER_IPS=("${${1#*=}//,/ }" ) ; shift ;;
    --master-names=*) MASTER_NAMES=("${${1#*=}//,/ }" ) ; shift ;;
    *) echo "Usage: $0 --master-ips=IP1,IP2 --master-names=NAME1,NAME2" ; exit 1 ;;
  esac
done

for var in MASTER_IPS MASTER_NAMES; do
  if [ -z "${!var}" ]; then
    echo "Erreur : $var n'est pas défini"
    exit 1
  fi
done

# ---------------------------
# 2. Install HAProxy
# ---------------------------
echo ""
echo "[2] Installation de HAProxy..."
sudo apt-get update -qq
sudo apt-get install -y haproxy

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

sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "HAProxy démarré sur 127.0.0.1:6443"
echo "Backends : ${MASTER_IPS[@]}:6443"
echo ""
echo "Vérification du status :"
sudo systemctl status haproxy --no-pager

# ---------------------------
# 3. Kubeconfig
# ---------------------------
echo "[WARN] k3s certificate are valid for 1y (https://docs.k3s.io/cli/certificate)"
echo "[WARN] Re-apply this part every year to refresh the kubeconfig on the laptop"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config