# homelab-net

Plugin [Claude Code](https://claude.com/claude-code) pour concevoir, auditer et dépanner le réseau d'un homelab.

- **Rien n'est modifié sans votre « oui ».** Claude lance seul les commandes d'observation ; toute commande qui modifie une config est proposée, expliquée, puis attend votre validation.
- **Votre topologie reste chez vous.** Elle vit dans un fichier privé hors de tout repo. Ce dépôt ne contient que des exemples fictifs.

## Installation

Le dépôt s'appelle `homelab-net`, le plugin `lab` : ses commandes sont donc `/lab:...`.

```
/plugin marketplace add Juyuroto/homelab-net
/plugin install lab@homelab-net
```

Test d'une copie locale, sans installer : `claude --plugin-dir /chemin/vers/homelab-net`.

## Démarrage rapide

**1. Votre topologie** (le plugin fonctionne sans, mais devient utile avec) :

```bash
mkdir -p ~/.claude/homelab-net
curl -o ~/.claude/homelab-net/topology.md https://raw.githubusercontent.com/Juyuroto/homelab-net/main/templates/topology.example.md
chmod 600 ~/.claude/homelab-net/topology.md
```

Remplacez les valeurs d'exemple par les vôtres et gardez les titres de sections (`## VLANs` en particulier). Pas de secrets dedans, seulement la structure du réseau.

**2. Proxmox** (pour `pve-create`, `pve-manage`, `net-debug`) : créez un jeton d'API (Datacenter > Permissions > API Tokens) et rangez-le à côté de la topologie :

```bash
nano ~/.claude/homelab-net/proxmox.env
```

et mettre dans un `.env`

```.env
PVE_HOST=192.168.1.1 ou pve1.example.lan
PVE_TOKEN_ID=utilisateur@pve!jeton
PVE_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Définir des droits sur le fichier

```bash
chmod 600 ~/.claude/homelab-net/proxmox.env
```

- Rôle le plus étroit possible : `PVEAuditor` pour observer, `PVEVMAdmin` pour créer et gérer.
- Sans `PVE_CACERT=/chemin/pve-root-ca.pem`, le certificat du nœud n'est pas vérifié.
- Sans ce fichier, les commandes sont proposées et c'est vous qui les lancez.

## Commandes

| Commande | Rôle |
|----------|------|
| `/lab:net-audit` | Risques de la topologie (exposition, segmentation, VPN trop large…), par gravité |
| `/lab:net-debug <symptôme>` | Dépannage couche par couche, diagnostic en lecture seule |
| `/lab:net-plan <besoin>` | Plan d'intégration d'un besoin (ex. VLAN caméras) : adressage, pare-feu, impact |
| `/lab:net-conseil [besoin]` | Conseil d'évolution : quoi installer et sur quelle machine, quoi réutiliser, retirer ou acheter d'occasion |
| `/lab:net-add <élément>` | Ajoute une machine ou un service à `topology.md` |
| `/lab:net-check` | Contrôle `topology.md` : contradictions, IP en double, références manquantes |
| `/lab:net-fw <source> -> <destination>:<port>` | Simule un flux contre les règles pfSense : passe ou bloqué, et pourquoi |
| `/lab:net-backup` | Liste ce qui n'a pas de sauvegarde récente (Proxmox, pfSense, topologie) |
| `/lab:net-version [version]` | Historique de `topology.md` : lister, enregistrer, comparer, revenir en arrière |
| `/lab:pve-create <ressource>` | Prépare une VM, un LXC ou un clone ; exécution après validation |
| `/lab:pve-manage <action> <vmid>` | Démarrer, arrêter, modifier, snapshot, sauvegarde, migration, suppression ; exécution après validation |

La forme courte (`/net-audit`…) fonctionne tant qu'aucune autre commande ne porte ce nom.

## Fonctionnement

- **Skill `reseau-homelab`** : se charge seul dès qu'une question porte sur le réseau ; ses fiches (`skills/reseau-homelab/references/`) ne sont lues qu'à la demande.
- **Hook de démarrage** : si `~/.claude/homelab-net/topology.md` existe, un résumé (sections avec numéro de ligne, tableau des VLAN, 2000 caractères max) est ajouté au contexte. Le fichier complet n'est lu qu'au besoin.
- **Versions** : `net-add` garde une copie avant et après chaque ajout dans `~/.claude/homelab-net/versions/<date>/`. `net-version` réactive celle que vous choisissez, après avoir sauvegardé l'état courant : une modification manuelle n'est jamais écrasée.