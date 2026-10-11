---
name: net-audit
description: Audite la topologie privée du homelab et liste les risques (exposition, segmentation, accès VPN trop large, services en écoute sur 0.0.0.0) classés par gravité, avec la correction proposée.
---

# Audit du réseau

Audit **en lecture seule** : ne rien modifier, ne rien exécuter sur le réseau.

1. Lire `~/.claude/homelab-net/topology.md` en entier, sauf s'il a déjà été lu en entier dans cette session et n'a pas été modifié depuis.
   - Absent : le dire, expliquer comment le créer depuis `${CLAUDE_PLUGIN_ROOT}/templates/topology.example.md`, et proposer à la place une liste de points à vérifier à la main. Ne pas inventer de topologie.
2. Charger le skill `reseau-homelab` et, selon ce que contient la topologie, ses références utiles.
3. Passer en revue :
   - **Exposition** : ports redirigés depuis Internet, cible hors DMZ, interface d'administration ou LAPI CrowdSec joignable de l'extérieur, dashboard du proxy, service public sans authentification.
   - **Segmentation** : réseau à plat, VLAN sans règle d'isolation, règle « any → any », gestion joignable depuis des réseaux non fiables, IoT ou DMZ pouvant initier vers l'interne, VLAN 1 utilisé.
   - **VPN** : règle « tunnel → any », tous les réseaux poussés, accès gestion pour tous les profils, certificat partagé.
   - **Écoute** : services sur `0.0.0.0` ou `[::]` qui devraient être liés à une IP ou à `127.0.0.1`, ports Docker publiés.
   - **Hygiène** : règles sans alias, DHCP statique dans le pool, DNS non maîtrisé, absence de journalisation ou de sauvegarde de config.
4. Signaler séparément ce que la topologie **ne dit pas** et qui empêche de conclure. Une information absente n'est pas un risque avéré.

## Format de sortie

Tableau trié par gravité, puis le détail de chaque ligne :

| Gravité | Risque | Où | Correction proposée |
|---------|--------|----|---------------------|

- **Critique** : exploitable depuis Internet, ou donne accès à la gestion.
- **Élevée** : un équipement compromis atteint les autres réseaux.
- **Moyenne** : défense en profondeur manquante.
- **Faible** : hygiène, lisibilité.

Pour chaque correction : ce qu'il faut changer, où, et l'effet de bord possible. Ce sont des **propositions** : aucune n'est appliquée sans validation explicite de l'utilisateur, une par une.

Terminer par les trois actions à faire en premier.

$ARGUMENTS
