# K3S Homelab

## Hello !

Ce projet c'est mon homelab k3s. L'objectif : héberger quelques apps perso et d'asso dans une infra qui tient la route — **GitOps-first**, **résiliente géographiquement**, et avec une **observabilité** poussée sur toutes les couches.

## Architecture physique

Le cluster tourne sur **3 NUCs** répartis sur **2 maisons différentes** (une forme d'HA géographique maison). Ils sont interconnectés via un réseau **Tailscale** (VPN mesh), ce qui permet à Cilium de faire tourner son réseau VXLAN inter-pods à travers ce tunnel sécurisé.

```
    Maison 1                                   Maison 2
  ┌──────────────┐                          ┌──────────────┐
  │  NUC 1       │◄────── Tailscale ────────►  NUC 2       │
  │  control-    │          VPN             │  control-    │
  │  plane       │                          │  plane       │
  └──────┬───────┘                          └──────┬───────┘
         │                                         │
         └──────────────────┬──────────────────────┘
                            │  Tailscale VPN
                     ┌──────┴───────┐
                     │  NUC 3       │
                     │  control-    │
                     │  plane       │
                     └──────────────┘
                            ▲
                            │ (via Tailscale)
                     ┌──────┴───────┐
                     │  Mon PC      │
                     │  HAProxy     │
                     │  127.0.0.1   │
                     │  :6443       │
                     └──────────────┘
```

Mon PC est également dans le réseau Tailscale. J'ai un **HAProxy local** qui fait du round-robin sur les 3 control-planes pour avoir un accès HA à l'API server depuis ma machine — si un noeud est down, kubectl continue de fonctionner.

Côté réseau pods, Cilium tourne en mode **VXLAN tunnel** (MTU 1150 : 1200 imposé par Tailscale, minus 50 d'overhead VXLAN). etcd est en cluster natif k3s avec des snapshots automatiques toutes les 6h.

## Stack

### Infrastructure & Cluster

| Outil | Rôle |
|-------|------|
| <img src="https://raw.githubusercontent.com/k3s-io/k3s/refs/heads/master/k3s.png" height="16"/> **k3s** | Distribution Kubernetes légère, base de tout |
| <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/cilium/icon/color/cilium-icon-color.svg" height="16"/> **Cilium** | CNI eBPF, remplace kube-proxy, réseau VXLAN via Tailscale + Hubble |
| **Tailscale** | VPN mesh inter-noeuds et accès depuis mon PC |
| **etcd** | Consensus distribué pour l'HA (snapshots toutes les 6h, rétention 10) |
| <img src="https://raw.githubusercontent.com/longhorn/website/master/src/img/logos/longhorn-icon-color.svg" height="16"/> **Longhorn** *(coming soon)* | Stockage distribué résilient, réplication cross-nodes, snapshots, backups |

### GitOps & Déploiement

| Outil | Rôle |
|-------|------|
| <img src="https://cdn.prod.website-files.com/5f10ed4c0ebf7221fb5661a5/5f2ba11e378c8f49e8b28486_argo.png" height="16"/> **ArgoCD** | CD GitOps, app-of-apps, sync auto avec self-heal et prune |
| <img src="https://www.redhat.com/rhdc/managed-files/helm.svg" height="16"/> **Helm** | Packaging des charts (multi-source dans ArgoCD) |
| **Sealed Secrets** | Secrets chiffrés dans Git, déchiffrés uniquement dans le cluster |

### Ingress & Réseau

| Outil | Rôle |
|-------|------|
| <img src="https://raw.githubusercontent.com/traefik/traefik/master/docs/content/assets/img/traefik.logo.png" height="16"/> **Traefik** | Ingress controller en DaemonSet, hostPort 80/443 |
| <img src="https://raw.githubusercontent.com/cert-manager/cert-manager/d53c0b9270f8cd90d908460d69502694e1838f5f/logo/logo-small.png" height="16"/> **cert-manager** | TLS automatique via Let's Encrypt (DNS-01 Cloudflare) |
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/cloudflare/cloudflare-original.svg" height="16"/> **Cloudflare Tunnel** | Tunnel sortant, zéro port ouvert sur la box |

Le flux d'une requête externe :
```
Internet → Cloudflare (DNS + TLS) → cloudflared DaemonSet → Traefik → Service → Pod
```

### Observabilité

L'objectif à terme : une observabilité **complète** sur toutes les couches — infra, middleware, et backends applicatifs. Logs, métriques et traces centralisés dans Grafana.

| Outil | Rôle |
|-------|------|
| <img src="https://raw.githubusercontent.com/prometheus/prometheus/main/documentation/images/prometheus-logo.svg" height="16"/> **Prometheus** | Scraping métriques cluster & apps (via kube-prometheus-stack) |
| <img src="https://raw.githubusercontent.com/grafana/grafana/main/public/img/grafana_icon.svg" height="16"/> **Grafana** | Dashboards, point d'entrée unique pour logs / métriques / traces |
| **Alertmanager** | Alertes |
| <img src="https://loki-operator.dev/logo.png" height="16"/> **Loki** | Agrégation de logs |
| **Grafana Alloy** | Collecteur unifié métriques + logs (remplace Promtail + agent Prometheus) |
| <img src="https://grafana.com/static/assets/img/logos/tempo.svg" height="16"/> **Tempo** | Backend de traces distribuées (compatible OTLP) |

Les backends applicatifs (Ski'UT en tête) sont instrumentés avec **OpenTelemetry** pour envoyer leurs traces directement vers Tempo.

### Applications

| App | Stack |
|-----|-------|
| **Ski'UT** | Laravel + MySQL + ProxySQL + PhpMyAdmin + HPA/PDB + OTEL |
| **Mon site** | Next.js |
| **Affine** | Workspace collaboratif (Postgres + Redis) |

## Organisation du repo

Le repo est déployé directement par ArgoCD via un pattern **app-of-apps** en plusieurs niveaux :

```
bootstrap-app                  ← appliqué une seule fois à la main
  └── meta                     ← app-of-apps racine
        ├── infra              ← sync-wave: -1 (déployée en premier)
        ├── monitoring
        ├── skiut
        ├── website
        └── productivity
```

```
k3s-project/
├── bootstrap/              # Bootstrap ArgoCD + définitions des AppProjects
├── meta/                   # App-of-apps (une ArgoCD App par dossier ci-dessous)
├── infra/                  # Traefik, cert-manager, Sealed Secrets, Cloudflare Tunnel
├── monitoring/             # kube-prometheus-stack, Loki, Alloy, Tempo
├── apps/                   # Ski'UT, Website
├── productivity/           # Affine
├── valueFiles/             # Fichiers de valeurs Helm (séparés des apps)
└── setup/                  # Scripts d'installation du cluster
    └── ha-cluster/         # Init premier CP, join des autres, HAProxy local
```

La séquence de bootstrap au premier déploiement :

```bash
# 1. Sur le premier NUC
./setup/ha-cluster/setup-init-ha-node.sh

# 2. Sur chaque NUC suivant
./setup/ha-cluster/setup-ha-node.sh --token=<TOKEN> --init-node-ip=<IP_TAILSCALE>

# 3. Sur mon PC
./setup/ha-cluster/setup-local-computer.sh --master-ips=IP1,IP2,IP3 --master-names=N1,N2,N3

# 4. Bootstrap ArgoCD (fait automatiquement par setup-init-ha-node.sh)
kubectl apply -f bootstrap-app.yaml
# → ArgoCD sync tout le reste automatiquement
```

## CI/CD

### <img src="https://avatars.githubusercontent.com/u/38656520?s=20&v=4" height="16"/> Renovate

[Renovate](https://docs.renovatebot.com/) scanne automatiquement les charts Helm et les images Docker pour ouvrir des PRs de mise à jour. Les mises à jour mineures sont **auto-mergées**, les majeures passent en revue manuelle.

### <img src="https://cdn.prod.website-files.com/5f10ed4c0ebf7221fb5661a5/5f2ba11e378c8f49e8b28486_argo.png" height="16"/> Argo Diff Preview

Chaque PR déclenche un workflow GitHub Actions qui génère le **diff complet des manifests ArgoCD** (Helm rendu + Kustomize) et le poste directement en commentaire de la PR. Pratique pour savoir exactement ce qui va changer dans le cluster avant de merger, sans avoir à faire tourner ArgoCD localement.

---

<div style="display: flex; justify-content: space-evenly; align-items: center; flex-wrap: wrap; gap: 12px; padding: 10px 0;">
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/linux/linux-original.svg" height="45" alt="Linux" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/bash/bash-original.svg" height="45" alt="Shell" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/git/git-original.svg" height="45" alt="Git" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" height="45" alt="Docker" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/kubernetes/kubernetes-plain.svg" height="45" alt="Kubernetes" />
  <img src="https://www.redhat.com/rhdc/managed-files/helm.svg" height="45" alt="Helm" />
  <img src="https://cdn.prod.website-files.com/5f10ed4c0ebf7221fb5661a5/5f2ba11e378c8f49e8b28486_argo.png" height="45" alt="ArgoCD" />
  <img src="https://raw.githubusercontent.com/traefik/traefik/master/docs/content/assets/img/traefik.logo.png" height="45" alt="Traefik" />
  <img src="https://raw.githubusercontent.com/cert-manager/cert-manager/d53c0b9270f8cd90d908460d69502694e1838f5f/logo/logo-small.png" height="45" alt="cert-manager" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/cloudflare/cloudflare-original.svg" height="45" alt="Cloudflare" />
  <img src="https://raw.githubusercontent.com/prometheus/prometheus/main/documentation/images/prometheus-logo.svg" height="45" alt="Prometheus" />
  <img src="https://raw.githubusercontent.com/grafana/grafana/main/public/img/grafana_icon.svg" height="45" alt="Grafana" />
  <img src="https://loki-operator.dev/logo.png" height="45" alt="Loki" />
  <img src="https://grafana.com/static/assets/img/logos/tempo.svg" height="45" alt="Tempo" />
  <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/cilium/icon/color/cilium-icon-color.svg" height="45" alt="Cilium" />
</div>
