#!/bin/bash
set -euo pipefail

CP_NODE_NAME="master"
CLOUDFLARE_TUNNEL_TOKEN=""
CLOUDFLARE_API_TOKEN=""

# ---------------------------
# 0. Vérification des variables
# ---------------------------
echo "[0/10] Vérification des variables..."
for var in CLOUDFLARE_TUNNEL_TOKEN CLOUDFLARE_API_TOKEN; do
  if [ -z "${!var}" ]; then
    echo "Erreur : la variable $var n'est pas définie"
    exit 1
  fi
done

# ---------------------------
# 1. Tailscale + récupération IP
# ---------------------------
tailscale -v 


TAILSCALE_IP=$(tailscale ip -4)
echo "IP Tailscale détectée : $TAILSCALE_IP"

# ---------------------------
# 2. K3S Control-plane
# ---------------------------
curl -sfL https://get.k3s.io | sh -s - server \
  --node-name "$CP_NODE_NAME" \
  --node-ip $TAILSCALE_IP \
  --flannel-iface tailscale0 \
  --tls-san 127.0.0.1 \
  --tls-san localhost \
  --tls-san "$TAILSCALE_IP" \
  --disable traefik

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/token)

# ---------------------------
# 3. Worker node
# ---------------------------
USE_WORKER="N"
read -p "Voulez-vous ajouter un worker ? (y/N) " USE_WORKER
if [ "$USE_WORKER" == "y" ]; then
  read -p "Nom du worker : " WORKER_NODE_NAME
  echo "Pour ajouter le worker, connectez-vous au worker et lancez :"
  echo "./setup-worker.sh --cp-ip $TAILSCALE_IP --token $K3S_TOKEN --node-name $WORKER_NODE_NAME"
  read -p "Appuyez sur Entrée quand le worker est ajouté pour continuer..."
fi

# ---------------------------
# 4. ArgoCD
# ---------------------------
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
kubectl -n argocd port-forward svc/argocd-server 8081:443 &

echo "Déploiement de l'app bootstrap..."
kubectl apply -f ./bootstrap-app.yaml

# ---------------------------
# 5. SealedSecrets
# ---------------------------
KUBESEAL_VERSION="0.34.0"
wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal

echo "Attente que le pod sealed-secrets-controller soit prêt..."
kubectl wait --for=condition=Ready pod -l name=sealed-secrets-controller -n kube-system --timeout=120s

# ---------------------------
# 6. Secrets Cloudflare
# ---------------------------
echo "[Création des secrets Cloudflare...]"

mkdir -p ./infra/cloudflared

cat > ./infra/cloudflared/cloudflare-api-token-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: infra
type: Opaque
data:
  api-token: $(echo -n "$CLOUDFLARE_API_TOKEN" | base64)
EOF

cat > ./infra/cloudflared/cloudflare-tunnel-token-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-tunnel-token-secret
  namespace: infra
type: Opaque
data:
  token: $(echo -n "$CLOUDFLARE_TUNNEL_TOKEN" | base64)
EOF

# ---------------------------
# 7. Git push new cloudflared secrets
# ---------------------------
echo "Chiffrement des secrets avec kubeseal..."
kubeseal --controller-namespace infra --controller-name sealed-secrets --format yaml < ./infra/cloudflared/cloudflare-api-token-secret.yaml > ./infra/cloudflared/cloudflare-api-token-sealed-secret.yaml
kubeseal --controller-namespace infra --controller-name sealed-secrets --format yaml < ./infra/cloudflared/cloudflare-tunnel-token-secret.yaml > ./infra/cloudflared/cloudflare-tunnel-token-sealed-secret.yaml
git add infra/cloudflared/cloudflare-api-token-sealed-secret.yaml infra/cloudflared/cloudflare-tunnel-token-sealed-secret.yaml
git commit -m "chore(infra: cloudflare): roll cloudflare sealed-secrets with new encryption key"
git push

# ---------------------------
# 8. Final message
# ---------------------------
echo "Setup terminé !"
echo "Accès ArgoCD UI: http://localhost:8081 (login: admin, mot de passe $ARGOCD_PWD)"
echo "Pour accéder au control-plane depuis votre pc, faites le rejoindre le réseau Tailscale et ajouter dans ~/.kube/config : "
cat $KUBECONFIG
