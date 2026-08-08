#!/bin/bash
set -euo pipefail

CP_NODE_NAME="master"

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
# 5. Create ESO Creds for Infisical
# ---------------------------

echo "Déploiement des creds ESO pour Infisical..."
echo "Créez un Machine Identities dans Infisical, puis récupérer les creds en universal auth"

read -p "Entrer le Client-Id Infisical : " INFISICAL_CLIENT_ID
read -p "Entrer le Client-Secret Infisical : " INFISICAL_CLIENT_SECRET

echo "[Création du secret Infisical pour ESO...]"
mkdir -p ./infra/external-secrets/

cat > ./infra/external-secrets/infisical-universal-auth-credentials.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: infisical-universal-auth-credentials
  namespace: infra
type: Opaque
stringData:
  clientId: $(echo -n "$INFISICAL_CLIENT_ID" | base64)
  clientSecret: $(echo -n "$INFISICAL_CLIENT_SECRET" | base64)
EOF
kubectl apply -f ./infra/external-secrets/infisical-universal-auth-credentials.yaml

# ---------------------------
# 6. Final message
# ---------------------------
echo "Setup terminé !"
echo "Accès ArgoCD UI: http://localhost:8081 (login: admin, mot de passe $ARGOCD_PWD)"
echo "Pour accéder au control-plane depuis votre pc, faites le rejoindre le réseau Tailscale et ajouter dans ~/.kube/config : "
cat $KUBECONFIG
