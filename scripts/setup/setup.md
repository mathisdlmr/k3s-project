# Setup

> [!WARNING]  
> Les scripts suivants ont été prévus pour tourner sur une distribution Ubuntu 24.04 LTS Server

Avant toute chose, lancer `./setup-node.sh` sur chaque machine qui va être utilisée. Ce script est prévu pour préparer une machine a être une node k3s selon ma config.

Si l'une des nodes tourne sur un AMD 5825U, lancer le script `./setup-5825u.sh` pour désactiver les C-States et éviter que le NUC crash comme un looser.

## Cluster Normal

Lancer `./basic-cluster/setup-master.sh` sur un node

Pour ajouter des noeuds workers au cluster, il suffit alors de faire `./basic-cluster/setup-worker.sh` avec les flags suivants :

| Flag | Valeur | Requis |
|---|---|---|
| `--cp-ip <IP>` | IP Tailscale du control-plane | oui |
| `--token <TOKEN>` | Token K3S du control-plane | oui |
| `--node-name <NOM>` | Nom du worker | oui |

Exemple : `./setup-worker.sh --cp-ip 100.x.x.x --token K10... --node-name worker1`

## Cluster HA

Lancer `./ha-cluster/setup-init-ha-node.sh` sur un premier control-plane

Ensuite, lancer `./ha-cluster/setup-ha-node.sh` sur les autres noeuds control-plane pour qu'ils rejoignent le cluster, avec les flags suivants :

| Flag | Valeur | Requis |
|---|---|---|
| `--token=<TOKEN>` | Token récupéré en fin de `setup-init-ha-node.sh` | oui |
| `--init-node-ip=<IP>` | IP Tailscale du noeud d'init | oui |

Exemple : `./setup-ha-node.sh --token=K10... --init-node-ip=100.x.x.x`

Finalement, lancer `./ha-cluster/setup-local-computer.sh` pour installer et config HAProxy et Kubeconfig pour connecter son PC au cluster, avec les flags suivants :

| Flag | Valeur | Requis |
|---|---|---|
| `--master-ips=<IP1,IP2,...>` | IPs Tailscale de tous les control-planes | oui |
| `--master-names=<NOM1,NOM2,...>` | Noms de tous les control-planes (même ordre que les IPs) | oui |

Exemple : `./setup-local-computer.sh --master-ips=100.x.x.1,100.x.x.2 --master-names=master1,master2`
