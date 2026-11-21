# TODO

Projet Hermes en local sur le node 5700u

Ce qu'il me faut de ta part avant de pousser (sinon le pod reste bloqué) :
1. Dans Infisical, chemin /hermes :  (avec un plafond de 5 € dans la console Mistral), TELEGRAM_BOT_TOKEN (bot créé avec BotFather), et TELEGRAM_USER_ID (ton identifiant numérique).
2. Un groupe Telegram privé en mode forum, avec le bot dedans et les topics Briefing, Mails et Sport. Donne-moi l'ID du groupe et les trois IDs de topic : je les mets dans config.yaml. Ils ne sont pas secrets, ils ne servent à rien sans le token du bot.

Pendant ce temps, tu peux préparer la tranche suivante : le client OAuth Google (Gmail, Calendar et Tasks en lecture seule, application publiée en production) et l'application Strava.

Points à vérifier au premier démarrage (non confirmés par la doc) :
- L'image Hermes démarre bien avec la config de sécurité du pod.
- L'identifiant exact du modèle Mistral.
- L'emplacement des skills dans /opt/data/skills/.
- La sortie de hermes cron list, dont dépend setup-cron.sh pour éviter les doublons.
- Le test décisif : demander à l'agent, dans le topic Sport, de lire un fichier. Il doit refuser, ce qui prouve que les outils sont bien désactivés.

Sources :
- Documentation Hermes Agent (https://hermes-agent.nousresearch.com/docs)
- Hermes : Telegram (https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram)
- Hermes : tâches planifiées (https://hermes-agent.nousresearch.com/docs/user-guide/features/cron)
- Hermes : Docker (https://hermes-agent.nousresearch.com/docs/user-guide/docker)
- Hermes : MCP (https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp)
- Hermes : fournisseurs de modèles (https://hermes-agent.nousresearch.com/docs/integrations/providers)
- Skill Google Workspace (https://hermes-agent.nousresearch.com/docs/user-guide/skills/google-workspace)
- Avis Tessl / Snyk sur ce skill (https://tessl.io/registry/skills/github/NousResearch/hermes-agent/google-workspace/review)







Passer la communication in-cluster par le LAN et plus tailscale. On ne garde tailscale que pour que server NFS, object storage S3 et pour que mon laptop puisse contacter l'API server.
On peut alors supprimer la restriction sur la reconstructions des volumes longhorn 1 à la fois, ainsi que le MTU cilium

Kube Workflow : kubernetes linter, helm linter, Kubernetes good practices, etc.
Adapter le déploiement Kubernetes avec les conventions 

Supprimer monitoring v2 et datadog...

Faire du cleanup partout
* Organisation du repo
* Ressources inutiles

Faire le tofix

Finir la config NAS (backup sur kDrive, alert, fichier de conf MD)

Backup Longhorn en NFS

Réinitialiser le cluster, et essayer de reconstruire via Ansible

Arr Stack DevOps

Voir ce qui serait utile en monitoring
* Dashboard pour le server S3 et NFS côté Grafana (s'inspirer du dashboard Longhorn)
* Alerting si une backup longhorn fail ?

Conf NFS dans Ansible

GI Github pour le playbook ansible

## Next Steps

* Create a full CD for Ansible : Preview using Tailscale on GitHub, If merged on main then deploy using Tailscale on GitHub
* NetworkPolicy for inside-cluster security
* Pod-Security
  * Pod Security Standards
  * non-root containers
  * read-only filesystem
  * dropped capabilities
* Create a true backend (Go/NodeJS, PostgreSQL, Redis) with a full CI that runs tests, build backend, scan image with Trivy/Sonarqube, push on a registry, update helm values, and auto-deploy

## Could be cool

* Deploy Immich on the cluster
* Deploy Nextcloud on the cluster

* Full Rolling strategy, self-managed or using Kargo, for the true backend

* Create a `docs/disasters/` folder with each possible incident, the impact, the recovery procedure and metrics (RTO, RPO)
* AdmissionPolicies Kyverno/gatekeeper

* Use Terraform to create Proxmox VM on OpenStack then ansible to setup them

## Global

### Fix
- Pourquoi les alertes de Alertmanager n'apparaissent pas dans Grafana
- Les logs de WARN/ERROR

### Chore

- Redirection nimportequoi.mdlmr.fr -> mdlmr.fr

### Feat

- Passer les outils en mode MS : ElasticSearch, Loki, Tempo, etc.
- Revoir les config Loki, Tempo, Kibana, ElasticSearch, Victoria Metricsetc. pour avoir un truc propre et concrètement utile (pas juste installé)
- Revoir l'orga des apps, namespaces, appProjects, etc.
- Refaire README de k3s
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