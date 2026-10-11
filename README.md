# homelab-net

Plugin [Claude Code](https://claude.com/claude-code) pour concevoir, auditer et dépanner le réseau d'un homelab : VLAN et plan d'adressage, pfSense, accès distant OpenVPN, reverse proxy Traefik + CrowdSec, bridges Proxmox.

Deux principes :

- **Rien n'est modifié sans votre « oui ».** Claude lance lui-même les commandes d'observation ; toute commande qui modifie une config (pfSense, switch, Proxmox, pare-feu) est proposée, expliquée, et attend votre validation.
- **Votre topologie reste chez vous.** Elle vit dans un fichier privé hors de tout repo. Ce dépôt ne contient que des exemples fictifs.

## Installation

Dans Claude Code :

```
/plugin marketplace add Juyuroto/homelab-net
/plugin install homelab-net@homelab-net
```

Pour tester une copie locale sans l'installer : `claude --plugin-dir /chemin/vers/homelab-net`.

## Créer votre topology.md

Le plugin fonctionne sans, mais devient utile avec :

```bash
mkdir -p ~/.claude/homelab-net
cp templates/topology.example.md ~/.claude/homelab-net/topology.md
chmod 600 ~/.claude/homelab-net/topology.md
```

Remplacez ensuite toutes les valeurs d'exemple par les vôtres. Gardez les titres de sections (`## VLANs` en particulier) : le résumé injecté au démarrage s'appuie dessus. N'y mettez pas de secrets (mots de passe, clés, tokens), seulement la structure du réseau.

Après installation par marketplace, le modèle se trouve dans le dossier du plugin sous `~/.claude/plugins/` ; le plus simple est de le copier depuis ce dépôt.

## Commandes

| Commande | Rôle |
|----------|------|
| `/homelab-net:net-audit` | Lit `topology.md` et liste les risques (exposition, segmentation, VPN trop large, services en `0.0.0.0`) par gravité, avec la correction proposée |
| `/homelab-net:net-debug <symptôme>` | Dépannage guidé couche par couche : il lance lui-même les commandes de diagnostic en lecture seule et pose des questions |
| `/homelab-net:net-plan <besoin>` | Plan d'intégration d'un besoin (ex. VLAN caméras) : VLAN, adressage, règles de pare-feu, impact |
| `/homelab-net:net-diagram` | Schéma Mermaid de la topologie |
| `/homelab-net:net-add <élément>` | Ajoute une machine ou un service à `topology.md` : IP libre proposée, conflits vérifiés, écriture après validation |
| `/homelab-net:net-check` | Vérifie `topology.md` lui-même : contradictions entre sections, IP en double ou hors plage, références non déclarées, champs manquants |
| `/homelab-net:pve-create <ressource>` | Prépare la création d'une VM, d'un conteneur LXC ou d'un clone sur Proxmox : VMID, IP, stockage et bridge/VLAN vérifiés, commande proposée, exécution après validation |
| `/homelab-net:pve-manage <action> <vmid>` | Agit sur une VM ou un conteneur existant : démarrer, arrêter, modifier, snapshot, sauvegarde, migration, suppression. Récapitulatif puis exécution après validation |
| `/homelab-net:net-version [version]` | Historique de `topology.md` : lister les versions datées, en enregistrer une, comparer, revenir à une version précédente |

La forme courte (`/net-audit`, etc.) fonctionne aussi tant qu'aucune autre commande ne porte ce nom.

Le skill `reseau-homelab` se charge de lui-même dès qu'une question porte sur le réseau ; ses fiches détaillées (`skills/reseau-homelab/references/`) ne sont lues qu'à la demande.

## Hook de démarrage

À chaque début de session, si `~/.claude/homelab-net/topology.md` existe, un court résumé est ajouté au contexte : titres des sections avec leur numéro de ligne et tableau des VLAN, 2000 caractères au plus. Le fichier complet n'est lu que lorsqu'une commande en a besoin. Sans fichier, le hook ne fait rien.

## Versions de la topologie

`topology.md` est toujours le fichier actif. `/net-add` en garde une copie avant et après chaque ajout dans `~/.claude/homelab-net/versions/<date>/topology.md` ; `/net-version` liste ces copies et réactive celle que vous choisissez, après avoir sauvegardé l'état courant. Une modification faite à la main est donc suivie comme les autres, et jamais écrasée.

## Ce qu'il ne faut jamais commiter

- `topology.md` ou toute copie remplie du modèle ;
- des IP, noms d'hôtes, noms de domaine, ports ou adresses MAC réels, y compris dans une issue, un exemple ou une capture d'écran ;
- des exports de configuration (pfSense `config.xml`, `/etc/network/interfaces`, profils `.ovpn`) ;
- des secrets : `.env`, clés et certificats VPN, clés de bouncer CrowdSec, tokens d'API ;
- un schéma généré par `/net-diagram`.

Le `.gitignore` bloque `topology.md`, `*.local.md` et `.env`, mais ce n'est qu'un filet : relisez `git diff --staged` avant chaque commit. Dans ce dépôt, les exemples n'utilisent que `10.0.X.0/24`, les plages RFC 5737 (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`) et les noms `*.example.lan` / `*.example.com`.

## Contribuer / mettre à jour

`claude plugin validate .` vérifie la structure. Le champ `version` de `.claude-plugin/plugin.json` doit être incrémenté pour que les installations existantes reçoivent une mise à jour.