# Segmentation VLAN et plan d'adressage

## Découper

Un VLAN par niveau de confiance, pas par type d'appareil. Découpage type :

| VLAN | Contenu | Peut joindre |
|------|---------|--------------|
| MGMT | Interfaces d'admin (pare-feu, switch, hyperviseur, AP) | rien d'initié depuis lui, sauf mises à jour |
| SERVEURS | VM, conteneurs, NAS | Internet, rien vers MGMT |
| LAN | Postes de confiance | SERVEURS (ports utiles), Internet |
| DMZ | Ce qui reçoit du trafic d'Internet | uniquement ses backends, port par port |
| IOT / INVITÉS | Non maîtrisé | Internet seulement |

Le routage inter-VLAN passe par le pare-feu : c'est lui qui filtre. Un switch L3 qui route entre VLAN contourne les règles.

## Taggé / non taggé

- **Trunk** (taggé 802.1Q) : transporte plusieurs VLAN. Entre switch et pare-feu, entre switches, vers un AP multi-SSID, vers un hyperviseur VLAN-aware.
- **Access** (non taggé) : un seul VLAN, la machine ne sait pas qu'il existe. Le PVID du port doit correspondre au VLAN voulu.
- **Hyperviseur sans tag** : branché sur un port access, il envoie des trames non taggées. Son bridge et toutes ses VM sont dans le VLAN du port. Pour plusieurs VLAN : soit un port physique + un bridge par VLAN, soit passer le port en trunk et le bridge en VLAN-aware (voir [proxmox.md](proxmox.md)).
- **VLAN natif** d'un trunk : le laisser sur un VLAN inutilisé plutôt que sur le VLAN 1 par défaut. Un PVID différent aux deux bouts mélange deux VLAN sans erreur visible.
- Ne pas utiliser le VLAN 1 pour du trafic utile ; ports inutilisés dans un VLAN mort.

Symptômes d'une erreur de tag : lien montant mais aucun ARP, DHCP qui donne une adresse d'un autre réseau, machine joignable depuis un seul VLAN.

## Plan d'adressage

- Un /24 par VLAN, troisième octet égal à l'ID du VLAN (`10.0.X.0/24` pour le VLAN X) : lisible et suffisant.
- Même découpage dans chaque sous-réseau, par exemple : `.1` passerelle, `.2–.49` IP fixes, `.50–.99` DHCP statique, `.100–.199` pool dynamique.
- Choisir une plage peu commune : un réseau identique à celui du site distant casse le VPN.
- Réseau du tunnel VPN hors des plages LAN.

## IP fixe ou DHCP statique

| | IP fixe (configurée sur la machine) | DHCP statique (réservation par MAC) |
|---|---|---|
| Pour | Pare-feu, switch, hyperviseur, DNS, tout ce qui doit démarrer sans DHCP | Serveurs applicatifs, imprimantes, postes à adresse stable |
| Avantage | Aucune dépendance au DHCP | Géré en un seul endroit, DNS local automatique |
| Risque | Dérive entre la doc et la réalité | Une MAC qui change (VM recréée, carte remplacée) fait perdre l'adresse |

Règle : l'infrastructure dont dépend le DHCP est en IP fixe ; le reste en DHCP statique. Les réservations se placent hors du pool dynamique.
