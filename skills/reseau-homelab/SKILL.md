---
name: reseau-homelab
description: Conception, audit et dépannage d'un réseau de homelab — segmentation VLAN et plan d'adressage, pfSense (règles, NAT, DNS Resolver, DHCP), accès distant OpenVPN au moindre privilège, reverse proxy Traefik + CrowdSec, bridges Proxmox, dépannage couche par couche. À utiliser dès qu'une question touche au réseau du homelab, à un VLAN, à une règle de pare-feu, à un service injoignable ou à l'exposition d'un service.
---

# Réseau de homelab

## Règles non négociables

1. **Lecture seule par défaut.** Sur le réseau réel, n'exécuter que des commandes d'observation (`ip`, `ss`, `ping`, `dig`, `tcpdump`, lecture de config).
2. **Toute modification se propose, ne s'exécute pas.** Pour chaque commande ou action qui change une config (pfSense, switch, Proxmox, pare-feu d'un hôte, service réseau) :
   - donner la commande ou le chemin de menu exact ;
   - expliquer ce qu'elle change et pourquoi ;
   - dire ce qui peut casser (perte d'accès à distance en premier) et comment revenir en arrière ;
   - **attendre la validation explicite de l'utilisateur** avant toute exécution. Une validation vaut pour une action, pas pour les suivantes.
3. **La topologie réelle est privée.** Elle vit dans `~/.claude/homelab-net/topology.md`. Si elle existe, en lire seulement les sections utiles (le résumé de début de session donne la ligne de chaque section : `Read` avec `offset`/`limit`), sans relire ce qui a déjà été lu dans la session si le fichier n'a pas changé ; sinon travailler avec ce que dit l'utilisateur et proposer `templates/topology.example.md` comme point de départ. Ne jamais inventer d'équipement, d'IP ou de règle.
4. **Rien de réel dans un repo.** Ne jamais écrire d'IP, de nom d'hôte, de port ou de secret réels dans un fichier versionné. Dans la documentation et les exemples : `10.0.X.0/24`, plages RFC 5737 (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), `*.example.lan`, `*.example.com`.

## Repères essentiels

**VLAN et adressage** — Un VLAN par niveau de confiance (gestion, serveurs, postes, DMZ, IoT). Trunk taggé entre switch et pare-feu, ports access vers les machines. Un hyperviseur branché sur un port access ne voit pas de tag : tout ce qui est sur son bridge est dans ce VLAN. IP fixes pour l'infrastructure, DHCP statique pour ce qui doit rester joignable, pool dynamique pour le reste.
→ [references/vlan-adressage.md](references/vlan-adressage.md)

**pfSense** — Les règles s'évaluent sur l'interface où le trafic *entre*, de haut en bas, première correspondance gagnante, refus implicite à la fin. Le NAT entrant s'applique avant le filtrage. Aliases pour tout ce qui se répète.
→ [references/pfsense.md](references/pfsense.md)

**OpenVPN** — Moindre privilège : ne pousser que les routes nécessaires, règles restrictives sur l'onglet OpenVPN, jamais de « tunnel → any » par défaut, accès gestion réservé à un profil admin identifié.
→ [references/openvpn.md](references/openvpn.md)

**Traefik + CrowdSec** — Seuls 80/443 arrivent au proxy ; dashboard, API et socket Docker ne sont pas exposés ; la LAPI CrowdSec écoute en local sauf besoin précis. Attention aux ports Docker publiés sur `0.0.0.0`.
→ [references/traefik-crowdsec.md](references/traefik-crowdsec.md)

**Proxmox** — Bridge VLAN-aware + port trunk, ou bridge simple + port access : les deux côtés doivent dire la même chose. Un tag sur une VM derrière un port access = trafic perdu.
→ [references/proxmox.md](references/proxmox.md)

**Dépannage** — Toujours de bas en haut : lien → voisinage → routage → port → application. Ne pas sauter de couche, ne pas supposer.
→ [references/depannage.md](references/depannage.md)

Ne charger une référence que lorsque la question la concerne.

## Commandes du plugin

- `/homelab-net:net-audit` — risques de la topologie, classés par gravité.
- `/homelab-net:net-debug <symptôme>` — dépannage guidé couche par couche.
- `/homelab-net:net-plan <besoin>` — intégrer un nouveau besoin.
- `/homelab-net:net-diagram` — schéma Mermaid de la topologie.
- `/homelab-net:net-add <élément>` — ajouter une machine ou un service à la topologie.
- `/homelab-net:net-check` — contradictions et manques du fichier de topologie.
- `/homelab-net:pve-create <ressource>` — créer une VM, un conteneur ou un clone sur Proxmox.
