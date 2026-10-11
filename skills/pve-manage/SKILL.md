---
name: pve-manage
description: Agit sur une VM ou un conteneur LXC existant sur Proxmox VE — démarrer, arrêter, redémarrer, modifier (cœurs, mémoire, disque, réseau, démarrage automatique), snapshot et retour à un snapshot, sauvegarde, migration, suppression. Observe sans demander, récapitule, demande « Appliquer ? oui/non » et n'exécute une modification qu'après un oui. À utiliser quand l'utilisateur veut démarrer, éteindre, redimensionner, snapshotter, sauvegarder, déplacer ou supprimer une VM ou un conteneur.
argument-hint: <action> <vmid ou nom>
---

# Gestion d'une ressource Proxmox

Demande : $ARGUMENTS

Même accès à Proxmox et mêmes règles que `pve-create` : l'observation se lance sans demander, **rien n'est modifié avant le « oui »**, et ce « oui » ne vaut que pour les commandes du récapitulatif.

1. **Identifier la cible** : `qm list ; pct list`, puis `qm config <vmid>` ou `pct config <ctid>`. Nom donné sans ID, ou plusieurs correspondances : demander. Ne jamais deviner un VMID.
2. Lire dans `~/.claude/homelab-net/topology.md`, s'il existe, seulement les sections utiles (le résumé de début de session donne la ligne de chaque section), sans relire ce qui a déjà été lu dans la session : ce que la cible héberge et qui en dépend.
3. **Observation seule** (état, config, liste des snapshots, tâches, journaux) : lancer et répondre, sans question.
4. **Modification** : afficher le récapitulatif — cible (VMID et nom), commandes exactes, ce qui est interrompu et pour qui, le retour arrière — puis **une seule question** avec `AskUserQuestion` : « Appliquer ? ».
   - **Oui** : exécuter sans autre question, vérifier en lecture seule (`qm status`, `qm config`, `qm listsnapshot`…) et dire le résultat. Une commande qui échoue arrête la suite : montrer l'erreur, ne rien rattraper par une autre commande non validée.
   - **Non** : ne rien exécuter, demander ce qu'il faut changer.
   - Plusieurs cibles : un seul récapitulatif qui les liste toutes, une seule question.
5. Si la ressource a été supprimée, renommée, ou a changé d'IP, de VLAN ou de nœud : renvoyer vers `/homelab-net:net-add` pour mettre la topologie à jour.

## Ce que le récapitulatif doit dire

| Action | À dire avant le « oui » |
|--------|-------------------------|
| Démarrer, snapshot, cœurs/mémoire à chaud, `onboot` | Rien n'est interrompu. Retour arrière : la commande inverse |
| Arrêter, redémarrer, migrer hors ligne, changer le réseau | Quels services tombent et pour combien de temps |
| Retour à un snapshot | Tout ce qui a été écrit depuis le snapshot est perdu. Proposer un snapshot de l'état courant d'abord |
| Agrandir un disque | Irréversible : un disque ne se réduit pas. Le système de fichiers reste à étendre dans l'invité |
| Supprimer un snapshot, un disque, une VM ou un conteneur | **Irréversible.** L'option « oui » reprend le VMID et le nom (`Oui, supprimer 105 (nas)`). Proposer une sauvegarde `vzdump` avant, et dire s'il en existe déjà une |

- La cible porte le pare-feu, le DNS, le VPN, le reverse proxy, ou la machine depuis laquelle Claude atteint Proxmox : le dire en premier. L'arrêter coupe le réseau, et peut-être l'accès qui permettrait de la redémarrer.
- `qm shutdown` / `pct shutdown` (arrêt propre) par défaut. `stop` (coupure brutale) seulement si l'arrêt propre a échoué ou si l'utilisateur le demande, en le disant.
- Jamais `--skiplock`, `--force` ou `--purge` sans que l'utilisateur l'ait demandé et que le récapitulatif explique ce que l'option contourne.
- Changement de bridge ou de `/etc/network/interfaces` sur le nœud : suivre la section « Modifier » de [proxmox.md](../reseau-homelab/references/proxmox.md).

## Modèles de commande

`qm` pour une VM, `pct` pour un conteneur ; les sous-commandes ci-dessous existent pour les deux sauf mention.

```bash
# Observer (sans question)
qm status <vmid> --verbose ; qm config <vmid> ; qm listsnapshot <vmid>
pvesh get /cluster/tasks --limit 20     # dernières tâches et leurs erreurs
pvesm list <stockage> --content backup  # sauvegardes existantes

# Cycle de vie
qm start <vmid> ; qm shutdown <vmid> --timeout 120 ; qm reboot <vmid> ; qm stop <vmid>

# Modifier
qm set <vmid> --cores 4 --memory 4096 --onboot 1
qm set <vmid> --net0 virtio,bridge=vmbr0,tag=<vlan>   # garder la MAC existante : la recopier depuis qm config
qm resize <vmid> scsi0 +10G                           # pct resize <ctid> rootfs +10G

# Snapshot et sauvegarde
qm snapshot <vmid> <nom> --description "<pourquoi>"
qm rollback <vmid> <nom>
qm delsnapshot <vmid> <nom>
vzdump <vmid> --storage <stockage> --mode snapshot --compress zstd

# Déplacer, supprimer
qm migrate <vmid> <nœud> --online 1                   # pct migrate <ctid> <nœud> --restart 1
qm destroy <vmid>                                     # pct destroy <ctid>
```

Commande refusée (jeton d'API sans droit) : dire **une fois** quel droit manque et la commande qui le donne (`pveum acl modify /vms/<vmid> --tokens '<utilisateur>!<jeton>' --roles PVEVMAdmin`), sans élargir les droits soi-même.
