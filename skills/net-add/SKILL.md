---
name: net-add
description: Ajoute ou met à jour un élément dans la topologie privée du homelab (nouveau serveur, VM, conteneur, équipement réseau, service) — propose une IP libre, vérifie les conflits, puis écrit les lignes dans topology.md après validation. À utiliser quand l'utilisateur dit avoir acheté, installé, créé ou déplacé une machine ou un service.
argument-hint: <élément à ajouter>
---

# Ajout à la topologie

Élément : $ARGUMENTS

Ce skill ne modifie **que** le fichier `~/.claude/homelab-net/topology.md` (et en garde une copie datée dans `versions/`). Il ne touche à aucune config réseau.

1. Lire `~/.claude/homelab-net/topology.md` en entier, sauf s'il a déjà été lu en entier dans cette session et n'a pas été modifié depuis.
   - Absent : le dire et expliquer comment le créer depuis `${CLAUDE_PLUGIN_ROOT}/templates/topology.example.md`. Ne pas le créer à partir de rien.
2. Demander **en une fois** ce qui manque pour décrire l'élément : nom, rôle, modèle, physique ou virtuel (et sur quel hyperviseur), VLAN, IP souhaitée ou à proposer, port du switch, gestion hors bande (iDRAC/iLO), services en écoute (port, adresse d'écoute, authentification), exposé à Internet ou non.
   - Ce que l'utilisateur ne sait pas encore s'écrit `?`. Ne jamais deviner une valeur.
3. Si aucune IP n'est donnée, proposer la première libre dans la plage que le plan d'adressage réserve à ce type d'attribution.
4. Vérifier les conflits avec l'existant et les signaler avant d'écrire : IP déjà prise ou hors plage, nom ou ID de VM déjà utilisé, port du switch déjà occupé, VLAN absent du tableau.
5. Montrer **toutes** les lignes à ajouter ou modifier, section par section. Un même élément apparaît souvent à plusieurs endroits (équipements ou hyperviseurs, ports du switch, plan d'adressage, services) : suivre les sections et les colonnes du fichier tel qu'il est, ne pas en imposer d'autres.
6. Attendre la validation explicite, lancer `bash "${CLAUDE_PLUGIN_ROOT}/scripts/topo-version.sh" save` (garde l'état d'avant, modifications à la main comprises), puis écrire avec des modifications ciblées, sans réécrire le fichier.
7. Relire le fichier pour confirmer que les lignes y sont. Si elles ont disparu, le fichier est probablement ouvert dans un éditeur qui l'a réenregistré : le dire, faire recharger, recommencer.
8. Relancer `bash "${CLAUDE_PLUGIN_ROOT}/scripts/topo-version.sh" save` : chaque ajout laisse un dossier daté dans `~/.claude/homelab-net/versions/`. Donner son nom, et rappeler que `/lab:net-version` permet de revenir en arrière.

## Ce que l'ajout implique sur le réseau

Terminer par la liste de ce qui reste à faire **en vrai** pour que la topologie soit exacte : port du switch à configurer, réservation DHCP, règle de pare-feu, entrée DNS. Ce sont des propositions, rien n'est exécuté. Si l'élément demande un nouveau VLAN ou de nouvelles règles, renvoyer vers `/lab:net-plan`.
