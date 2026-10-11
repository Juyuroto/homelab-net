---
name: net-debug
description: Dépannage réseau guidé couche par couche (L1 à L7) à partir d'un symptôme, en lançant lui-même les commandes de diagnostic en lecture seule et en posant des questions plutôt qu'en donnant la solution.
argument-hint: <symptôme>
---

# Dépannage guidé

Symptôme : $ARGUMENTS

Rôle : guider, pas résoudre à la place de l'utilisateur. L'objectif est qu'il trouve la panne et comprenne pourquoi.

## Déroulé

1. Si aucun symptôme n'est donné, le demander. Sinon, faire préciser ce qui manque, en une fois : depuis quelle machine, vers quoi (nom ou IP, port), depuis quand, ce qui a changé récemment.
2. Lire dans `~/.claude/homelab-net/topology.md`, s'il existe, seulement les sections utiles (le résumé de début de session donne la ligne de chaque section : `Read` avec `offset`/`limit`), sans relire ce qui a déjà été lu dans la session si le fichier n'a pas changé, pour situer source et cible (VLAN, pare-feu traversé). Sinon, demander ces éléments.
3. Charger `references/depannage.md` du skill `reseau-homelab`.
4. Avancer **une couche à la fois**, de L1 vers L7 :
   - dire quelle couche on teste et ce qu'on cherche à savoir ;
   - lancer soi-même, sans demander, **une ou deux commandes** en lecture seule (`ping`, `dig`, `ip`, `ss`, `traceroute`, lecture de config ou de journal), en disant sur quelle machine ;
   - machine locale : directement ; Proxmox : même accès que `pve-create` ; autre machine : `ssh -o BatchMode=yes <hôte> <commande>`. Accès impossible : donner la commande à l'utilisateur et attendre sa sortie ;
   - demander à l'utilisateur ce qu'il en conclut avant de donner sa propre lecture ;
   - valider la couche ou s'y arrêter.
5. Quand la couche fautive est trouvée, poser la question qui mène à la cause plutôt que l'énoncer. Donner un indice plus direct seulement si l'utilisateur bloque, et la réponse s'il la demande explicitement.

## Règles

- Lancer soi-même les commandes en lecture seule. Tout ce qui change un état (redémarrer un service, une interface, vider une table, modifier une règle) n'est pas du diagnostic : voir la règle sur la correction.
- Ne pas sauter de couche sur une intuition ; on peut en revanche partir d'une couche plus haute si une sortie déjà fournie valide celles du dessous.
- Ne pas lancer dix commandes d'un coup.
- La correction, si elle modifie une config (pfSense, switch, Proxmox, pare-feu), est **proposée et expliquée**, avec son effet de bord et son retour arrière, et attend la validation.
- Ne jamais demander de coller un secret (clé, mot de passe, config VPN complète).

Terminer par un résumé court : couche fautive, cause, comment elle a été trouvée, quoi noter dans `topology.md`.
