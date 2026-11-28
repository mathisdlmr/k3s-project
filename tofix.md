Etudier ce problème, proposer une solution sous forme de plan d'implémentation
- Voir comment sont géré les certificats de sécurité
  - Ne serait-ce pas mieux (plus propre) d'en avoir un par ingress et pas un wildcard ? Sont-ils correctement utilisées par Traefik ? Ou alors ça fonctionne juste parce que Cloudflare gère mes certificats ?
  - Prendre en compte que côté DNS pour l'instant il n'y a que 2 record de défini : un pour le nom de domaine racine mdlmr.fr et un wildcard *.mdlmr.fr
  - Dans l'idée je souhaiterai que cette conf reste aussi simple, ou alors qu'elle soit automatisée

Pour après, en me fournissant un plan d'implémentation que je validerai
- Refaire un tour sur les projets et rangement des dossiers/applications/namespace
  - proposer un rangement plus propre, utile et logique
    - En particulier, l'application bootstrap déploiera les applications (=dossiers) core/ network/ argocd/ monitoring/ monitoring-v2/
      - core = service de base du cluster ; network = traefik, cloudflare, cert-manager ; ...
    - Est-ce que l'organisation des namesapces est bonne ? Ou alors ils donnent un effet fourre-tout avec trop de ressources dans chaque namesapce ?
   - L'organisation des AppProjects est-elle censée sachant que je suis tout seul sur le cluster ?
