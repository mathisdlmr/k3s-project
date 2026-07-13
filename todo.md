# TODO

## FIX

- [ ] Pourquoi n'y a t il pas de métriques du node worker ?

## CHORE

- [ ] Redéfinir les resources
- [ ] Définir taint et tolérations :
  - Prom, Grafana, AlertManager, CronJobs Skiut c'est sur le worker
- [ ] Définir liveness et readiness probes
- [ ] Redirection skiut.mdlmr.fr -> skiut.mdlmr.fr/skiutc et idem pour nimportequoi.mdlmr.fr -> mdlmr.fr
- [ ] Mieux ranger les serviceMonitor :
  - Sois les supprimer
  - Sois les deployer dans leur namespace concerné
  - Et voir si il n'y a pas d'autres serviceMonitor sympa à deploy
- [ ] Voir pour parser les templates de value Helm (Traefik, Alloy, Loki, etc.) avec un LLM et voir ce qu'il peut etre interessant à garder
- [ ] Globalement mieux ranger monitoring entre chart helm, overload de config, dashboards, etc.

## FEAT

- cleanup sur la partie monitoring (folders organisés n'importe comment pour metrics/)
- dashboards prometheus en gitops
- Velero
- [ ] Cillium Hubble
- [ ] Voir pour des métriques sur tous les services : loki, tempo, traefik, etc.
- [ ] Refaire la doc de README
- [ ] Dashboards Grafana ArgoCD, Cloudflare, Traefik...
- [ ] Redis global (app "utils")
- [ ] OTel en parallele de Alloy (et pour log/metrics/traces Filebeat, metricbeat, APM server) (app "monitoring-v2")
- [ ] Kubernetes dashboard
- [ ] Sysdig et/ou Falco et/ou trivy operator (app "security")
- [ ] Sonarqube
- [ ] Configuration Alloy boostée aux hormones : https://grafana.com/docs/opentelemetry/collector/grafana-alloy/
- [ ] Minio et Longhorn pour du stockage S3 et des PV dynamiques (app "utils")
- [ ] ArgoWorkflow ou Apache Workflow
- [ ] Istio /Linkerd + Kcert
- [ ] Jaeger
- [ ] Tools Go
- [ ] TFA avec Google (https://mattdyson.org/blog/2024/02/using-traefik-with-cloudflare-tunnels/) ou Keycloak
- [ ] Serveur ski'ut en nodejs
- [ ] Templatiser Ski'ut en Helm, surtout pour injecter les env
- [ ] Kargo
- [ ] Chaos Mesh, Kubecost, kube-resource-report, kube-bench, etc.
- [ ] Uptime Kuma
- [ ] Registry Harbor
- [ ] Gitea
- [ ] Hosting
- [ ] Rancher pour du multi node ? Karpenter ?
- [ ] External DNS

## Migration 21/03/2026

une fois longhorn -> --disable=local-storage sur k3s

une fois CNI :

# /etc/rancher/k3s/config.yaml

disable:

- servicelb
- traefik
- local-storage # après migration Longhorn

# Perf etcd (pour HA)

etcd-arg:

- "quota-backend-bytes=4294967296" # 4Gi max DB size
- "auto-compaction-mode=periodic"
- "auto-compaction-retention=1h"

# Kubelet tuning

kubelet-arg:

- "max-pods=110"
- "kube-reserved=cpu=100m,memory=256Mi"
- "system-reserved=cpu=100m,memory=256Mi"
- "eviction-hard=memory.available<200Mi,nodefs.available<10%"

# API server

kube-apiserver-arg:

- "audit-log-path=/var/log/k3s-audit.log"
- "audit-log-maxage=7"

1. Sécurité Kubernetes (très important pour la suite)
* RBAC strict
* pas de cluster-admin partout
* limiter les ServiceAccount

2. Sécuriser K3S lui-même
* permissions sur /etc/rancher/k3s/k3s.yaml
* rotation des certificats
* tokens sécurisés

3. Isolation réseau (CNI) depuis LongHorn + HA
* traffic inter-node sécurisé
* policies réseau (NetworkPolicy)
