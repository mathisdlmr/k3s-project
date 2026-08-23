# TODO

## Next Steps

* Create a full CI for kubernetes : kubernetes linter, helm linter, Kubernetes good practices, etc.
* Create a full CI/CD for Ansible : Linter, Preview using Tailscale on GitHub, If merged on main then deploy using Tailscale on GitHub
* Full backup policy (Only need Longhord Backups ? on Backblaze B ? and also add Velero's cluster backups ?)
* NetworkPolicy for inside-cluster security
* Pod-Security
  * Pod Security Standards
  * non-root containers
  * read-only filesystem
  * dropped capabilities
* Use Terraform to create Proxmox VM on nodes then ansible to setup them
* Proxmox Backups
* Keycloak / Authentik SSO
* Full Rolling strategy, self-managed or using Kargo
* Create a true backend (Go/NodeJS, PostgreSQL, Redis) with a full CI that runs tests, build backend, scan image with Trivy/Sonarqube, push on a registry, update helm values, and auto-deploy
* Create a `docs/disasters/` folder with each possible incident, the impact, the recovery procedure and metrics (RTO, RPO)
* AdmissionPolicies Kyverno/gatekeeper

## Global

### Chore

- Redéfinir les resources
- Définir taint et tolérations
- Définir liveness et readiness probes
- Redirection nimportequoi.mdlmr.fr -> mdlmr.fr

### Feat

- Velero
- Cillium Hubble
- Redis global (app "utils")
- OTel en parallele de Alloy (et pour log/metrics/traces Filebeat, metricbeat, APM server) (app "monitoring-v2")
- Kubernetes dashboard
- Sysdig et/ou Falco et/ou trivy operator (app "security")
- Sonarqube
- Configuration Alloy boostée aux hormones : https://grafana.com/docs/opentelemetry/collector/grafana-alloy/
- Minio
- ArgoWorkflow ou Apache Workflow
- Istio /Linkerd + Kcert
- Jaeger
- Tools Go
- TFA avec Google (https://mattdyson.org/blog/2024/02/using-traefik-with-cloudflare-tunnels/) ou Keycloak
- Templatiser Ski'ut en Helm, surtout pour injecter les env
- Chaos Mesh, Kubecost, kube-resource-report, kube-bench, etc.
- Rancher pour du multi node ? Karpenter ?
- External DNS