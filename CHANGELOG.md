# Changelog

All notable changes to this k3s cluster are documented here

Entries are grouped by day, newest first. Each entry uses the following labels, loosely inspired by [Keep a Changelog](https://keepachangelog.com/) :

- **Added** - new components, apps or capabilities
- **Changed** - architecture or configuration evolutions
- **Fixed** - notable bug hunts worth remembering
- **Removed** - things decommissioned or replaced

---

## 13 07 2026 - EFK Stack

### Added
- **ECK Operator** deployed on monitoring-v2 namespace to provide ready-to-use elasticsearch cluster and kibana UI. In the short term, it will be use to create a ElasticSearch-Fluentd-Kibana stack as an other way than Grafana Labs to monitore
- **Fluent Operator** deployed on monitoring-v2 namespace, also to provide a ready-to-use tool in cluster : fluentbit log collector.
- **EFK Stack** as an other monitoring stack to make comparaison between Grafana Labs vs EFK. Thanks to ECK and Fluent Operator, the deployment is very easy, and ressources lifecycle fully managed

_References :_ 
* https://support.tools/efk-stack-kubernetes-production-eck-fluent-operator/

### Changes 
- Create Jobs that fully configure EFK stack
  - `efk-ilm-policy-jobs` uses `efk-ilm-configmap` to create a new Index Lifecycle Management using Elasticsearch API
  - `efk-kibana-admin-user-setup` create a new Elasticsearch account to access Kibana UI using Infisicale creds (instead of ECK-managed creds)
  - `efk-fluentbit-es-user-setup` create a new Elasticsearch role and account that Fluentbit ClusterOutput can use to send logs into Elasticsearch
- Fix ArgoCD `resource.customizations.health.elasticsearch` to consider a yellow Elasticsearch cluster as healthy (because green color needs a 2e node for replica shard)

_References :_ 
* https://medium.com/@sraza0098/log-rotation-in-the-elk-stack-using-ilm-index-lifecycle-policy-0fcc011d0c2c
* https://discuss.elastic.co/t/cluster-health-wrong-yellow-spikes-because-new-index/330124

### Removed
- **Fluentd** fully removed for the benefit of Fluent Operator

---

## 12 07 2026 - Storage & secrets overhaul

### Added
- **External Secrets Operator (ESO) + Infisical** as the new secrets backend. Every secret was recreated as an `ExternalSecret`. HashiCorp Vault was considered but judged overkill for this use case; Infisical also allows browsing secrets from anywhere (e.g. phone)
- **Longhorn** deployed for high-availability distributed storage: cleaner StorageClass/PV management, snapshots, and (most importantly) metrics. UI exposed behind a Traefik middleware

_References :_
* External Secrets Operator
    * https://external-secrets.io/main/provider/infisical/
    * https://infisical.com/videos/external-secrets-operator-eso-explained
* Longhorn
    * https://longhorn.io/docs/1.12.0/deploy/install/#installation-requirements
    * https://longhorn.io/docs/1.12.0/deploy/install/install-with-argocd/

### Changed
- `kube-prometheus-stack` CRDs split into a dedicated ArgoCD app (`prometheus-operator-crds`) to avoid conflicts on version bumps, with a Renovate package rule keeping both charts in lockstep
- ArgoCD configured to ignore ESO-injected fields on `ExternalSecret` resources, eliminating permanent OutOfSync noise

_References :_
* https://oneuptime.com/blog/post/2026-02-26-how-to-deploy-the-prometheus-operator-with-argocd/view

### Removed
- **SealedSecrets** fully removed (Bitnami moving it behind a paywall was the trigger)

---

## 11 07 2026 - Post-exam cleanup & catch-up upgrades

### Changed
- Setup scripts consolidated into a `scripts/` directory; obsolete scripts and the website git submodule removed; README refreshed
- Major dependency catch-up after a busy study period:
    - **Argo CD v9.7.1 then to v10**
    - **kube-prometheus-stack v87**
    - **cert-manager v1.21.0**
    - **Alloy v1.10.1**
    - **victoria-metrics-single v0.42.0**

### Fixed
- ArgoCD extremely slow sync operations, root-caused to host firewall blocking traffic from Cilium interfaces to the host. Setup script now allows this traffic
- Ski'UT storage: stale `nodeAffinity` matching no node, and missing `spec.nodeAffinity` on the local PersistentVolume

### Removed
- Elasticsearch + Kibana removed from monitoring-v2 (to be replaced by ECK later)

---

## 11 05 2026 - SR05 app

### Added
- **SR05 / werewolf** app deployed under the `apps` AppProject

---

## 18 04 2026 - Tailscale MTU fix

### Added
- DaemonSet enforcing MTU 1200 on `tailscale0` across all nodes, fixing cross-node networking quirks

---

## 13 04 2026 - k3s server metrics

### Added
- Additional Prometheus `ScrapeConfig` to monitor the k3s server itself from Grafana

_References :_
* https://medium.com/@kunalvirwal/how-i-set-up-secure-external-monitoring-for-my-k3s-cluster-with-prometheus-and-tailscale-eba972dc19eb

---

## 04 04 2026 - Reproducible setup & monitoring v2

### Added
- **Setup scripts** written with a DevOps mindset so the whole cluster can be rebuilt from scratch
- **Monitoring v2**: EFK stack (Elasticsearch, Fluentd, Kibana) and **VictoriaMetrics** deployed alongside the existing stack

---

## 23 03 2026 - Network observability

### Added
- **Hubble relay** enabled to observe Cilium traffic

### Fixed
- ArgoCD ingress LB IP diff ignored to stop permanent OutOfSync

---

## 22 03 2026 - Routing on the HA network

### Changed
- Traefik switched to a **DaemonSet with hostPort** so cloudflared can route to any node
- ArgoCD sync-waves redefined to avoid conflicts

_References :_
* https://github.com/argoproj/argo-cd/issues/14607

### Fixed
- Cilium MTU issues on the Tailscale-backed HA cluster

---

## 19 03 2026 - Cilium

### Changed
- **Cilium** replacing Flannel as CNI - eBPF datapath, better performance, and a great oportunity to really understand how a CNI works

_References :_
* https://oneuptime.com/blog/post/2026-03-14-install-cilium-on-k3s/view

---

## 17 03 2026 - High availability & AppProjects

The biggest infrastructure milestone so far

### Added
- **High availability**: from a single control plane to **3 control-plane nodes**
- ArgoCD **AppProjects** properly defined per domain (infra, monitoring, apps, …) with scoped destinations
- ArgoCD metrics enabled

_References :_
* https://oneuptime.com/blog/post/2026-01-26-k3s-production-cluster/view
* https://medium.com/@andrea.grillo96/manage-permitted-destination-of-an-argocd-project-cd8e73ac61f8

### Changed
- Global repository structure redefined (bootstrap app separated, recursive directories abandoned where they proved fragile)

---

## 16 03 2026 - Spring cleaning

### Removed
- `pic` and `tutut` apps decommissioned (no longer used)

---

## 15 03 2026 - ArgoCD self-management

### Changed
- ArgoCD restructured for **self-management** with a custom image that replicates the `argocd.argoproj.io/instance` label onto UI breadcrumbs

---

## 06 03 2026 - tutut app

### Added
- **tutut** app deployed

---

## 01 03 2026 - Affine

### Added
- **Affine** deployed (with PostgreSQL + Redis) for course notes

### Changed
- Setup: Tailscale tunnel defined as the flannel interface so nodes communicate over the tailnet

---

## 29 01 2026 - pic app

### Added
- First iteration of the **pic** app (later removed; a second iteration for an RDP web chat lived briefly in June 2026)

---

## 13 01 2026 - Ski'UT storage & monitoring tuning

### Changed
- Ski'UT storage pinned to a stable node via a local PV + node affinity
- Loki storage configuration redefined; Alloy log format defined; extra Prometheus features enabled on node-exporter and kube-state-metrics

---

## 12 01 2026 - App-of-apps consistency

### Changed
- Manifest labels re-organized to consistently follow the app-of-apps pattern; finalizers added on Applications

---

## 11 01 2026 - Tempo metrics generator

### Added
- Tempo **metrics generator** with a Prometheus ServiceMonitor (pull model)
- Tempo added as a Grafana data source

---

## 10 01 2026 - Traces

### Added
- **Tempo** deployed for distributed tracing; Ski'UT backend instrumented with OTLP

---

## 09 01 2026 - Automation

### Added
- **Renovate** on the repository to keep every chart and action up to date (auto-PRs)
- **argo-diff-preview** GitHub Action to visualize the actual manifest diff of a PR before merging - pairs perfectly with Renovate
- Loki added as a Grafana data source

---

## 08 01 2026 - Alerting

### Added
- Alertmanager enabled on kube-prometheus-stack

---

## 04 01 2026 - Logs & TLS redesign

### Added
- **Grafana Alloy + Loki** for log collection and aggregation
- Resource requests defined across workloads

### Changed
- Routing and TLS management redesigned: wildcard certificate, TLS terminated at Traefik, cloudflared config using `originServerName`

---

## 03 01 2026 - Cluster reborn

Full cluster recreation for a big cleanup

### Added
- **Self-deployed Traefik** (Helm chart) replacing the k3s-embedded one, giving full control over the ingress layer

### Changed
- `argocd/` configuration moved into `meta/`; dangerous ArgoCD config removed; sync-waves and syncPolicies cleaned up (SealedSecrets at wave -1, cert-manager CRDs separated from the ClusterIssuer)
- Personal website split into its own ArgoCD Application

---

## 09 12 2025 - Ski'UT persistence

### Fixed
- Persistent volume added for the database; phpMyAdmin auth and volumeMount fixed

---

## 07 12 2025 - Ski'UT reminders

### Added
- Notification-reminder **CronJobs** for the Ski'UT app

---

## 01 11 2025 - Ski'UT hardening

### Changed
- HTTPS enforcement and TrustProxies middleware configured on the Ski'UT backend

---

## 27 10 2025 - Ski'UT OAuth

### Added
- OAuth on the Ski'UT backend (SealedSecret + callback ConfigMap)

---

## 13 10 2025 - phpMyAdmin ingress

### Added
- Separate ingress for phpMyAdmin

---

## 12 10 2025 - Shotgun preparation

### Added
- **ProxySQL** in front of MySQL to survive the "shotgun" traffic spike

### Changed
- Backend switched from Apache to **php-fpm + nginx**

---

## 11 10 2025 - Ski'UT in production

The cluster's first real production workload, hosting the Ski'UT event platform

### Added
- Persistent volume for user data; server image now bundling the website

---

## 27 09 2025 - Prometheus the CRD way

### Changed
- Prometheus configuration migrated from raw ConfigMaps to **CRDs** (`Prometheus`, `ServiceMonitor`) with kube-state-metrics, ending an epic battle with Helm-generated config

---

## 26 09 2025 - kube-prometheus-stack

### Added
- **kube-prometheus-stack** installed (Prometheus Operator, Grafana, node-exporter, alert rules) and Grafana ingress

### Fixed
- The infamous duplicated `web.enable-lifecycle` flag saga

---

## 14 09 2025 - First metrics

### Added
- First Prometheus + Grafana metrics setup
- ArgoCD RBAC and AppProject rights for the monitoring namespace

---

## 10 09 2025 - Encrypted secrets

### Added
- **SealedSecrets** so encrypted secrets can live safely in the public Git repository

---

## 08 09 2025 - First app

### Added
- **Ski'UT** application first draft: Laravel backend, MySQL StatefulSet, phpMyAdmin, HPA, TLS ingress

---

## 07 09 2025 - TLS & tunnel

### Added
- **cert-manager** with a Let's Encrypt ClusterIssuer, using the **DNS-01 challenge** (Cloudflare) - then switched to production certificates
- **Cloudflare Tunnel** (cloudflared) to expose the cluster without opening any port on the home router, with Cloudflare caching and DDoS protection for free
- Personal website served at the domain root

### Changed
- One ingress per namespace instead of a single cluster ingress; ArgoCD Applications standardized into the `argocd` namespace

---

## 06 09 2025 - Genesis

### Added
- **k3s** cluster bootstrapped on a single node (an N150 mini-PC)
- **ArgoCD** installed with an **app-of-apps** pattern (the `meta` application, synced first via sync-waves) - GitOps from day one
- Initial repository layout, README and setup documentation
