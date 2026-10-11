---
name: net-diagram
description: Génère un schéma Mermaid de la topologie du homelab à partir du fichier privé topology.md (équipements, VLAN, flux autorisés, points d'exposition).
---

# Schéma de la topologie

1. Lire `~/.claude/homelab-net/topology.md` en entier, sauf s'il a déjà été lu en entier dans cette session et n'a pas été modifié depuis.
   - Absent : le dire et indiquer comment le créer depuis `${CLAUDE_PLUGIN_ROOT}/templates/topology.example.md`. Ne pas dessiner une topologie inventée ; proposer à la place le schéma du modèle, clairement présenté comme fictif.
2. Produire un bloc ```` ```mermaid ```` de type `flowchart TB` :
   - Internet → pare-feu → switch en haut ;
   - un `subgraph` par VLAN (ID, nom, sous-réseau), contenant ses machines ;
   - liens physiques en trait plein, avec `trunk` ou `access` en étiquette ;
   - flux autorisés entre VLAN en pointillés, avec le port en étiquette ;
   - points d'exposition (NAT, VPN) mis en évidence par une classe dédiée.
3. Ne représenter que ce qui figure dans le fichier. Lister sous le schéma ce qui manquait pour le compléter.
4. Schéma trop chargé : en proposer deux (physique, puis logique avec les flux).

## Où va le résultat

Afficher le schéma dans la conversation. Il contient des informations réelles : ne l'écrire dans un fichier que si l'utilisateur le demande, et alors dans `~/.claude/homelab-net/`, jamais dans un repo.

$ARGUMENTS
