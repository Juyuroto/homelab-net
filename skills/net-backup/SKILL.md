---
name: net-backup
description: Vérifie que pfSense, Proxmox, les VMs et conteneurs, et la topologie ont une sauvegarde récente et restaurable, et liste ce qui n'en a pas. À utiliser avant un changement risqué ou pour contrôler que rien d'important n'est sans sauvegarde.
---

# Contrôle des sauvegardes

Contrôle **en lecture seule** : lancer soi-même les commandes d'observation, ne rien créer, ne rien supprimer, ne rien restaurer.

## Déroulé

1. Lire dans `~/.claude/homelab-net/topology.md` les sections `Équipements`, `Hyperviseurs`, `Proxmox` et `Monitoring` (`Read` avec `offset`/`limit`, d'après le résumé de début de session) pour dresser la liste de ce qui doit être sauvegardé. Absent : le dire et demander la liste.
2. Observer, sans demander :
   - **Proxmox** : même accès que `pve-manage` (API par `pve-api.sh` si `proxmox.env` existe, sinon commande donnée à l'utilisateur). `pvesm status` (stockages de sauvegarde), `pvesm list <stockage> --content backup` (date et taille de la dernière sauvegarde de chaque VMID), `GET /cluster/backup` (tâches planifiées), `GET /cluster/tasks` (échecs récents de `vzdump`).
   - **Topologie** : dernière version dans `~/.claude/homelab-net/versions/` (voir `net-version`) et date de modification de `topology.md`.
   - **pfSense** : pas d'accès sans l'utilisateur. Demander la date du dernier export de `config.xml` (Diagnostics > Backup & Restore), ou si AutoConfigBackup est actif.
3. Croiser et classer chaque élément :
   - **Aucune sauvegarde** ;
   - **Trop ancienne** (plus de 7 jours pour ce qui change souvent, 30 jours pour le reste, à annoncer) ;
   - **Dernière tâche en échec** ;
   - **Sauvegarde sur le même stockage ou le même hôte que la source** : pas de protection contre la perte de l'hôte ;
   - **OK**.
4. Signaler à part ce qui n'est pas vérifiable : une sauvegarde jamais restaurée n'est pas prouvée ; proposer un test de restauration (VMID de test, jamais sur la VM d'origine).

## Format de sortie

| Élément | Dernière sauvegarde | Où | État |
|---------|---------------------|----|------|

Puis les trois actions à faire en premier. Les corrections (planifier une tâche `vzdump`, ajouter un stockage distant, exporter `config.xml`) sont des **propositions** ; l'exécution passe par `pve-manage` et attend un « oui ».

Ne jamais demander de coller un secret, ni le contenu de `config.xml` ou d'une sauvegarde.

$ARGUMENTS
