---
name: pve-create
description: Prépare la création d'une ressource sur Proxmox VE — VM (qm create), conteneur LXC (pct create), clone depuis un template, téléchargement d'un template ou autre objet créé par qm/pct/pvesh — vérifie VMID, IP, stockage et cohérence bridge/VLAN, pose toutes les questions nécessaires, puis demande « Créer ? oui/non » et n'exécute qu'après un oui. À utiliser quand l'utilisateur veut créer, cloner ou déployer une VM ou un conteneur sur Proxmox.
argument-hint: <ressource à créer>
---

# Création sur Proxmox

Ressource : $ARGUMENTS

Les règles du skill `reseau-homelab` s'appliquent : observation en lecture seule, **rien n'est créé avant le « oui » final**. Ici, ce « oui » vaut pour les commandes de création affichées dans le récapitulatif, et pour elles seules.

1. Lire dans `~/.claude/homelab-net/topology.md`, s'il existe, seulement les sections utiles (le résumé de début de session donne la ligne de chaque section : `Read` avec `offset`/`limit`), sans relire ce qui a déjà été lu dans la session si le fichier n'a pas changé : hyperviseur, montage du bridge (sans tag, un bridge par VLAN, VLAN-aware), VLAN, plan d'adressage, ID déjà pris. Absent : le dire et travailler avec ce que dit l'utilisateur.
2. **Questionner l'utilisateur** avant toute commande, avec le questionnaire ci-dessous, **jusqu'au bout** : enchaîner les lots sans s'arrêter tant qu'une valeur nécessaire à la commande manque. Ne poser que ce qui n'a pas déjà été dit, ne jamais deviner une valeur.
3. Lancer avant et pendant le questionnaire les commandes d'observation utiles (voir plus bas) pour proposer de vraies options : prochain ID libre, stockages, images disponibles.
4. Vérifier avant le récapitulatif (un problème trouvé = une question de plus, pas un arrêt) :
   - VMID libre, sur le nœud et dans la topologie ;
   - IP libre et dans la plage que le plan d'adressage réserve à ce type d'attribution ;
   - le stockage accepte le contenu visé (`images`, `rootdir`, `iso`, `vztmpl`) ;
   - tag VLAN cohérent avec le montage du bridge — un tag derrière un port access fait perdre le trafic, voir [proxmox.md](../reseau-homelab/references/proxmox.md).
5. Afficher le récapitulatif : tableau des réponses, commandes exactes qui seront lancées, ce qu'elles consomment (disque, mémoire) et le retour arrière (`qm destroy <vmid>`, `pct destroy <ctid>`).
6. Poser **une seule question finale** avec `AskUserQuestion` : « Créer ? » — options `Oui, créer` et `Non`.
   - **Oui** : exécuter les commandes du récapitulatif, sans autre question, puis vérifier en lecture seule (`qm config`, `pct config`, `qm status`, `pct status`) et dire le résultat. Une commande qui échoue arrête la suite : montrer l'erreur, ne rien supprimer.
   - **Non** : ne rien exécuter, demander ce qu'il faut changer.
7. Terminer en renvoyant vers `/homelab-net:net-add` pour inscrire la ressource dans la topologie, et lister ce qui reste à faire sur le réseau (réservation DHCP, DNS, règle de pare-feu).

## Questionnaire

Poser les questions avec l'outil **`AskUserQuestion`** (menu de choix à l'écran), pas en liste de texte : 4 questions par appel, 2 à 4 options chacune, la valeur recommandée en premier, tirée de la topologie ou des commandes d'observation. L'utilisateur tape une valeur libre via « Other ». Ne retomber sur une liste numérotée que si l'outil n'est pas disponible.

| Lot | Question | Options à proposer |
|-----|----------|--------------------|
| 1 | Type | VM, conteneur LXC, clone d'un template |
| 1 | Nom | 2 ou 3 noms suivant la convention de la topologie |
| 1 | Nœud | les nœuds du cluster |
| 1 | VMID | le prochain libre, le suivant dans la plage du rôle |
| 2 | Cœurs | 1, 2, 4 |
| 2 | Mémoire | 1 Go, 2 Go, 4 Go, 8 Go |
| 2 | Disque | 8 Go, 16 Go, 32 Go, 64 Go |
| 2 | Stockage | les stockages qui acceptent ce contenu |
| 3 | Système | les ISO ou templates présents |
| 3 | Réseau | les couples bridge / VLAN possibles |
| 3 | Adresse | première IP fixe libre, DHCP |
| 3 | Démarrage | ne pas démarrer, démarrer après création, démarrer + automatique avec l'hôte |
| 4 | Clé SSH (conteneur, cloud-init) | les clés publiques trouvées |
| 4 | Conteneur non privilégié | oui, non |

Sauter les questions déjà répondues ou sans objet (lot 4 pour une VM installée depuis une ISO). Un besoin particulier (second disque, GPU, cloud-init, autre objet) ajoute les questions qu'il faut. La mémoire se convertit en Mo dans `--memory` (2 Go = 2048).

## Observer (lecture seule)

```bash
pvesh get /cluster/nextid          # prochain VMID libre
qm list ; pct list                 # ID et noms existants
pvesm status                       # stockages, espace, état
pvesm list <stockage>              # ISO, templates et disques présents
pveam available --section system   # templates LXC téléchargeables
ip -d link show vmbr0              # vlan_filtering 1 = VLAN-aware
```

Lecture refusée (jeton d'API sans droit) : prendre la valeur de la topologie si elle y figure, et dire **une fois** quel droit manque et la commande qui le donne — lire le réseau d'un nœud demande `Sys.Audit` sur `/nodes/<nœud>` (`pveum acl modify / --tokens '<utilisateur>!<jeton>' --roles PVEAuditor`). Ne pas le répéter à chaque création.

## Modèles de commande

Valeurs d'exemple : les remplacer par celles de la topologie. `,tag=<vlan>` seulement sur un bridge VLAN-aware.

**VM depuis une ISO**

```bash
qm create <vmid> --name <nom> --ostype l26 \
  --cores 2 --memory 2048 \
  --scsihw virtio-scsi-single --scsi0 <stockage>:32 \
  --ide2 <stockage-iso>:iso/<image>.iso,media=cdrom \
  --net0 virtio,bridge=vmbr0,tag=<vlan> \
  --boot order='scsi0;ide2' --agent 1
```

**Conteneur LXC**

```bash
pct create <ctid> <stockage>:vztmpl/<template>.tar.zst --hostname <nom> \
  --cores 1 --memory 512 --swap 512 --rootfs <stockage>:8 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.10.21/24,gw=10.0.10.1,tag=<vlan> \
  --unprivileged 1 --features nesting=1 \
  --ssh-public-keys <fichier.pub>
```

- Non privilégié par défaut ; un conteneur privilégié se justifie et se signale comme un risque.
- Template absent : `pveam update` puis `pveam download <stockage> <template>`, à inclure dans le récapitulatif.

**Clone depuis un template**

```bash
qm clone <id-template> <vmid> --name <nom> --full 1
qm set <vmid> --ipconfig0 ip=10.0.10.22/24,gw=10.0.10.1 --sshkeys <fichier.pub>   # si cloud-init
pct clone <id-template> <ctid> --hostname <nom> --full 1
```

Un clone garde le bridge et le tag du template : les relire avec `qm config` / `pct config` avant de démarrer.

## Secrets

Jamais de mot de passe dans une commande (historique du shell, liste des processus) : clé SSH publique, ou `--password` sans valeur pour une saisie interactive. Ne rien écrire de réel dans un fichier versionné.

## Autres créations

Agir sur une ressource existante (démarrer, arrêter, modifier, snapshot, sauvegarde, suppression) : `/homelab-net:pve-manage`. Disque supplémentaire, pool : même démarche (questionner, récapituler, « Créer ? ») avec `qm`, `pct` ou `pvesh`. Un bridge ou un changement de `/etc/network/interfaces` peut couper l'accès à l'hyperviseur : suivre la section « Modifier » de [proxmox.md](../reseau-homelab/references/proxmox.md).
