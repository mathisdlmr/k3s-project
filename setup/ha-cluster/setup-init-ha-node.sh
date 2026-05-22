#!/bin/bash

set -euo pipefail

# setup-init-ha.sh
# À lancer sur le PREMIER control-plane (nœud d'initialisation du cluster)

# ---------------------------
# Collecte des paramètres
# ---------------------------
read -p "Nom du nœud : " NODE_NAME

echo ""
echo "=== Tailscale peers ==="
tailscale status
echo "========================"
echo ""

read -p "Nombre de nœuds control-plane au total : " NUM_MASTERS

MASTER_IPS=()
MASTER_NAMES=()
for i in $(seq 1 "$NUM_MASTERS"); do
  read -p "IP Tailscale du $i-e control-plane : " ip
  read -p "Nom du $i-e control-plane (ex: 5700u) : " name
  MASTER_IPS+=("$ip")
  MASTER_NAMES+=("$name")
done

# ---------------------------
# 0. Préparation du noeud
# ---------------------------
echo ""
echo "[0] Préparation du noeud..."
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
echo ""
echo "[1] Récupération de l'IP Tailscale..."
TAILSCALE_IP=$(tailscale ip -4)
echo "IP Tailscale de CE nœud : $TAILSCALE_IP"

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
# 3. Installation de K3S (cluster-init)
# ---------------------------
echo ""
echo "[3] Installation de K3S (cluster-init)..."
sudo mkdir -p /etc/rancher/k3s

sudo tee /etc/rancher/k3s/config.yaml > /dev/null << EOF
node-name: ${NODE_NAME}
node-ip: ${TAILSCALE_IP}

cluster-init: true

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

etcd-snapshot-schedule-cron: "0 */6 * * *"
etcd-snapshot-retention: 10

write-kubeconfig-mode: "0644"
EOF

echo ""
echo "Configuration du cluster :"
cat /etc/rancher/k3s/config.yaml

read -p "Appuyer sur Entrée pour continuer..."

echo "Installation de K3S..."
curl -sfL https://get.k3s.io | sh -

# ---------------------------
# 4. Kubeconfig
# ---------------------------
echo ""
echo "[4] Création du kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
export KUBECONFIG=~/.kube/config

echo ""
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo "======================================================"
echo "Noeud init OK. Lancer setup-ha.sh sur les autres control-planes avec :"
echo "   ./setup-ha.sh --token=${TOKEN} --init-node-ip=${TAILSCALE_IP}"
echo "======================================================"
read -p "Appuyer sur Entrée quand les autres control-planes sont ajoutés..."

# ---------------------------
# 5. Cilium
# ---------------------------
echo ""
echo "[5] Installation de Cilium..."
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar xzvf cilium-linux-amd64.tar.gz
sudo mv cilium /usr/local/bin/
rm -f cilium-linux-amd64.tar.gz

cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=6443 \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# --set mtu=1200 has no effect in Cilium 1.19.1 (not rendered in ConfigMap).
# Pod MTU must be set manually: tailscale0=1200, vxlan overhead=50 → pod MTU=1150.
# bpf-lb-sock enables socket-level LB (reduces hairpin NAT impact for local backends).
kubectl patch configmap cilium-config -n kube-system --patch '{"data":{"mtu":"1150","bpf-lb-sock":"true"}}'
kubectl rollout restart daemonset/cilium -n kube-system

echo "Attente que Cilium soit prêt..."
cilium status --wait

# ---------------------------
# 6. ArgoCD
# ---------------------------
echo ""
echo "[6] Installation de ArgoCD..."
kubectl create namespace argocd || true
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd -n argocd -f ./valueFiles/argocd.yaml

echo "Attente du démarrage d'ArgoCD..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password : $ARGOCD_PWD"

echo "Déploiement de l'app bootstrap..."
kubectl apply -f ./bootstrap-app.yaml

# ---------------------------
# 7. Configuration du PC
# ---------------------------

echo ""
echo "[7] Configuration du PC..."
echo "======================================================"
echo "Setup du cluster OK. Lancer setup-local-computer.sh sur votre PC avec :"
echo "   ./setup-local-computer.sh --master-ips ${MASTER_IPS[@]} --master-names ${MASTER_NAMES[@]}"
echo "======================================================"
echo "Puis accéder à ArgoCD via : kubectl port-forward svc/argocd-server -n argocd 8080:443"