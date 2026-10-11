---
name: net-fw
description: Simule un flux (source → destination:port) contre les règles pfSense de la topologie privée et dit s'il passe ou est bloqué, en citant la règle qui décide. À utiliser avant d'ajouter une règle, ou pour comprendre pourquoi un flux passe ou ne passe pas.
argument-hint: <source> -> <destination>:<port>
---

# Simulation d'un flux

Flux : $ARGUMENTS

**Lecture seule** : rien n'est exécuté sur le réseau, rien n'est modifié. C'est un raisonnement sur la topologie déclarée, pas un test réel (pour tester pour de vrai : `net-debug`).

## Déroulé

1. Si source, destination ou port manque, le demander en une fois. Accepter un nom de machine, une IP, un VLAN ou « Internet ».
2. Lire dans `~/.claude/homelab-net/topology.md` seulement les sections utiles (`Firewall`, `VLANs`, `Plan d'adressage`, `VPN` si le flux vient du tunnel, `Services exposés` si le flux vient d'Internet) : `Read` avec `offset`/`limit` d'après le résumé de début de session. Absent : le dire et s'arrêter, ne pas inventer de règles.
3. Charger `references/pfsense.md` du skill `reseau-homelab` pour l'ordre d'évaluation.
4. Situer la source (VLAN, interface) et la destination (VLAN, IP). Résoudre les aliases (`RFC1918`, `ADMIN_HOSTS`, `<IF> net`, `This Firewall`).
5. Dérouler, dans l'ordre pfSense :
   - même VLAN : le trafic ne traverse pas le pare-feu, le dire ;
   - règles flottantes, puis groupes d'interfaces (dont OpenVPN), puis règles de l'**interface où le paquet entre** (celle de la source) ;
   - de haut en bas, première correspondance gagnante ;
   - aucune correspondance : refus implicite ;
   - flux depuis Internet : règle WAN et port forward (traduit avant le filtrage, la règle vise l'IP interne).
6. Conclure **passe / bloqué**, avec la règle qui décide (interface, ordre) et celles qui ont été écartées sur le chemin.

## À signaler

- Le retour est autorisé par l'état de la connexion : ne pas chercher de règle inverse.
- Un flux qui passe mais ne devrait pas : règle trop large, ou règle large placée au-dessus d'un blocage.
- Un flux qui est bloqué mais devrait passer : la règle à ajouter, **au-dessus** de la règle qui bloque, avec son effet de bord.
- Ce que la topologie ne dit pas (règle manquante, alias non défini) : le dire, ne pas conclure à tort. Pare-feu de la machine cible (nftables, ufw) et service à l'écoute ne sont pas couverts.

Toute règle proposée est une **proposition** : jamais appliquée sans validation, et `net-plan` ou `net-add` prennent le relais si l'utilisateur la veut.
