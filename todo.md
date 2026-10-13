# TODO

## Next Steps

* Deploy Immich
* Deploy NextCloud
* Buy a NAS, and setup a S3 (Garage, MinIO or smthg) and a NFS (ClusterFS or Ceph) on it and use it as a storage
* Create a full CI for kubernetes : kubernetes linter, helm linter, Kubernetes good practices, etc.
* Create a full CD for Ansible : Preview using Tailscale on GitHub, If merged on main then deploy using Tailscale on GitHub
* Full backup policy (Only need Longhord Backups ? on Backblaze B ? and also add Velero's cluster backups ?)
  * En profiter pour voir toutes les possibilités de longhorn
* NetworkPolicy for inside-cluster security
* Pod-Security
  * Pod Security Standards
  * non-root containers
  * read-only filesystem
  * dropped capabilities
* Create a true backend (Go/NodeJS, PostgreSQL, Redis) with a full CI that runs tests, build backend, scan image with Trivy/Sonarqube, push on a registry, update helm values, and auto-deploy

## Could be cool

* Full Rolling strategy, self-managed or using Kargo, for the true backend

* Create a `docs/disasters/` folder with each possible incident, the impact, the recovery procedure and metrics (RTO, RPO)
* AdmissionPolicies Kyverno/gatekeeper

* Use Terraform to create Proxmox VM on nodes then ansible to setup them

## Global

### Fix
- Pourquoi les alertes de Alertmanager n'apparaissent pas dans Grafana
- Les logs de WARN/ERROR

### Chore

- Redéfinir les resources avec des VPA
- Définir taint et tolérations
- Définir liveness et readiness probes
- Redirection nimportequoi.mdlmr.fr -> mdlmr.fr

### Feat

- Passer les outils en mode MS : ElasticSearch, Loki, Tempo, etc.
- Revoir les config Loki, Tempo, Kibana, ElasticSearch, Victoria Metricsetc. pour avoir un truc propre et concrètement utile (pas juste installé)
- Revoir l'orga des apps, namespaces, appProjects, etc.
- Merge les PRs
- Reset le cluster pour tester
- Refaire README de k3s et mathisDlmr, màj le site et LinkedIn
- Cillium Hubble
- Victoria Metrics
- oTel (+ APM server ?)
- Sysdig et/ou Falco et/ou trivy operator (app "security")
- Kyverno
- Istio /Linkerd + Kcert
- Sonarqube
- Gateway API
- Configuration Alloy boostée aux hormones : https://grafana.com/docs/opentelemetry/collector/grafana-alloy/
- ArgoWorkflow ou Apache Workflow
- Jaeger
- Tools Go
- TFA avec Google (https://mattdyson.org/blog/2024/02/using-traefik-with-cloudflare-tunnels/) ou Keycloak
- Templatiser Ski'ut en Helm, surtout pour injecter les env
- Chaos Mesh, Kubecost, kube-resource-report, kube-bench, etc.
- External DNS