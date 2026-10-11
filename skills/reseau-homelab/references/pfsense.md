# pfSense

Toute modification ci-dessous se propose à l'utilisateur et attend sa validation. Avant un changement de règles : sauvegarde de la config (Diagnostics > Backup & Restore) et accès console disponible.

## Ordre d'évaluation

1. Règles **Floating** (avec *quick*, la première correspondance gagne ; sans *quick*, la dernière).
2. Règles de **groupes d'interfaces** (dont l'onglet OpenVPN, qui est un groupe).
3. Règles de l'**interface**.
4. Refus implicite.

Dans un onglet : de haut en bas, **première correspondance gagnante**. Une règle large placée au-dessus rend inutiles celles du dessous.

## Règles par interface

- Une règle se place sur l'interface où le paquet **entre** dans le pare-feu. Pour bloquer IOT → LAN, la règle va sur IOT, pas sur LAN.
- Le filtrage est à états : le retour d'une connexion autorisée passe tout seul.
- Seul LAN reçoit une règle « allow any » par défaut. Une nouvelle interface (VLAN) n'a **aucune** règle : tout est bloqué, y compris DNS et DHCP… sauf que le service DHCP activé ajoute ses règles automatiques.
- `<IF> net` = le sous-réseau, `<IF> address` = l'IP du pare-feu dans ce réseau, `This Firewall` = toutes ses IP.

Gabarit pour un VLAN isolé avec accès Internet :

| # | Action | Source | Destination | Port | But |
|---|--------|--------|-------------|------|-----|
| 1 | pass | VLAN net | VLAN address | 53, 123 | DNS et NTP du pare-feu |
| 2 | block | VLAN net | This Firewall | any | Pas d'accès à l'interface web ni au SSH |
| 3 | block | VLAN net | alias RFC1918 | any | Pas d'accès aux autres réseaux internes |
| 4 | pass | VLAN net | any | any | Internet |

Les exceptions (ex. vers un serveur précis) se placent **au-dessus** de la règle 3.

## Aliases

- Hosts, Networks, Ports, URL tables. Un alias `RFC1918` (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) sert à toutes les règles d'isolation.
- Nommer par rôle (`ADMIN_HOSTS`, `PORTS_WEB`), jamais par adresse.
- Une règle qui cite une IP en dur est un candidat à l'alias.

## NAT

- **Port forward** : traduit *avant* le filtrage. La règle WAN associée doit donc viser l'IP **interne** de destination. Laisser pfSense créer la règle liée.
- Ne rediriger que les ports nécessaires, vers une machine en DMZ, jamais vers le LAN ou MGMT.
- **Outbound** : mode automatique tant qu'il suffit ; hybride pour ajouter une exception ; manuel seulement en connaissance de cause (oublier un nouveau VLAN = pas d'Internet).
- **NAT reflection** : à éviter ; préférer le split DNS (un host override qui résout le nom public vers l'IP interne).
- Ne jamais ouvrir l'interface web ou le SSH du pare-feu sur WAN : passer par le VPN.

## DNS Resolver (Unbound)

- Écoute sur les interfaces internes uniquement. Les *access lists* se déduisent des interfaces ; vérifier qu'un VLAN ajouté peut résoudre.
- *Host overrides* pour les noms locaux et le split DNS ; *domain overrides* pour déléguer une zone.
- Enregistrer les baux DHCP statiques dans le DNS donne des noms locaux sans maintenance.
- Forcer le DNS local : règle pass vers `<IF> address:53`, puis block vers any:53 et 853.

## DHCP

- Un serveur par interface, pool dans la plage dynamique prévue par le plan d'adressage.
- *Static mappings* par MAC, hors du pool. Préciser le nom d'hôte pour l'enregistrement DNS.
- Options à vérifier par VLAN : passerelle, serveur DNS, domaine.
- Le backend change selon la version (ISC historique, Kea ensuite) : vérifier lequel est actif avant de chercher une option.

## Observer sans rien modifier

- Status > System Logs > Firewall : paquets bloqués, avec la règle responsable.
- Diagnostics > States : une connexion a-t-elle un état ?
- Diagnostics > Packet Capture : le paquet arrive-t-il sur l'interface ?
- Diagnostics > Routes, ARP Table, DNS Lookup.
- En console : `pfctl -sr` (règles chargées), `pfctl -ss` (états), `pfctl -sn` (NAT).
