---
name: net-plan
description: Propose comment intégrer un nouveau besoin dans le réseau du homelab (nouveau VLAN, nouveau service, nouvel accès distant) — VLAN, adressage, règles de pare-feu, impact sur l'existant.
argument-hint: <besoin>
---

# Plan d'intégration

Besoin : $ARGUMENTS

Produire un **plan**, rien d'autre : aucune modification n'est exécutée.

1. Si le besoin n'est pas donné ou est ambigu (qui doit joindre quoi, depuis où, exposé à Internet ou non), poser les questions nécessaires avant de planifier.
2. Lire dans `~/.claude/homelab-net/topology.md`, s'il existe, seulement les sections utiles (le résumé de début de session donne la ligne de chaque section : `Read` avec `offset`/`limit`), sans relire ce qui a déjà été lu dans la session si le fichier n'a pas changé, pour s'insérer dans l'existant (ID de VLAN libres, plan d'adressage, conventions de nommage, règles en place). Absent : le dire et planifier sur des hypothèses explicites, avec des valeurs d'exemple (`10.0.X.0/24`).
3. Charger le skill `reseau-homelab` et les références concernées.

## Contenu du plan

1. **Décision** : nouveau VLAN ou VLAN existant, et pourquoi (niveau de confiance).
2. **VLAN et switch** : ID, nom, ports access et trunks à modifier, effet côté hyperviseur (bridge, tag).
3. **Adressage** : sous-réseau, passerelle, IP fixes ou DHCP statique, pool, DNS.
4. **Règles de pare-feu** : tableau par interface, dans l'ordre d'évaluation, avec les aliases à créer. Partir de « tout bloqué » et n'ouvrir que le nécessaire.
5. **Accès distant et exposition** : ce qui change pour le VPN et le reverse proxy, s'il y a lieu.
6. **Impact** : ce qui peut casser, coupures prévisibles, ce qui change pour les autres VLAN.
7. **Ordre d'exécution** : étapes numérotées, chacune avec sa vérification (commande en lecture seule) et son retour arrière.
8. **Mise à jour de `topology.md`** : les lignes à ajouter dans le fichier privé, par l'utilisateur ou via `/lab:net-add` une fois le changement fait.

Chaque étape qui modifie une config reste une proposition : elle n'est exécutée qu'après validation explicite, étape par étape.
