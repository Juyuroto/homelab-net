# Topologie du homelab — MODÈLE (valeurs fictives)

> Copier ce fichier vers `~/.claude/homelab-net/topology.md` puis remplacer **toutes** les valeurs.
> Le fichier rempli ne doit jamais être commité, où que ce soit.
> Ne pas y mettre de secrets (mots de passe, clés, tokens) : seulement la structure du réseau.
> Convention : `?` = à compléter, `—` = sans objet. Mieux vaut un `?` qu'une valeur devinée.

## Équipements

| Nom | Rôle | Modèle | IP de gestion | Notes |
|-----|------|--------|---------------|-------|
| fw.example.lan | Pare-feu / routeur (pfSense) | boîtier 4 ports | 10.0.99.1 | WAN sur port 1, trunk sur port 2 |
| sw1.example.lan | Switch manageable | 24 ports | 10.0.99.2 | Trunk vers fw sur le port 1 |
| ap1.example.lan | Point d'accès Wi-Fi | — | 10.0.99.3 | SSID mappés sur les VLAN 20 et 40 |

## Hyperviseurs

| Nom | Type | IP de gestion | Port switch | Mode | Bridges |
|-----|------|---------------|-------------|------|---------|
| pve1.example.lan | Proxmox VE | 10.0.10.10 | sw1 port 5, access VLAN 10 | sans tag | vmbr0 (non VLAN-aware) |

Gestion hors bande (iDRAC, iLO, IPMI) :

| Serveur | Type | Branché | IP | VLAN | Accès autorisé depuis |
|---------|------|---------|----|------|-----------------------|
| pve1.example.lan | iDRAC | oui, sw1 port 8 | 10.0.99.10 | 99 | ADMIN_HOSTS |

## VLANs

| ID | Nom | Sous-réseau | Passerelle | DHCP | Usage |
|----|-----|-------------|------------|------|-------|
| 10 | SERVEURS | 10.0.10.0/24 | 10.0.10.1 | non (IP fixes) | VM et conteneurs |
| 20 | LAN | 10.0.20.0/24 | 10.0.20.1 | oui | Postes de confiance |
| 30 | DMZ | 10.0.30.0/24 | 10.0.30.1 | non | Reverse proxy exposé |
| 40 | IOT | 10.0.40.0/24 | 10.0.40.1 | oui | Objets connectés, sans accès aux autres VLAN |
| 99 | MGMT | 10.0.99.0/24 | 10.0.99.1 | non | Interfaces d'administration |

## Switch

| Port | Branché sur | Mode | VLAN(s) |
|------|-------------|------|---------|
| 1 | fw.example.lan port 2 | trunk | 10, 20, 30, 40, 99 |
| 2-4 | Postes | access | 20 |
| 5 | pve1.example.lan | access | 10 |
| 6 | proxy.example.lan | access | 30 |
| 7 | ap1.example.lan | trunk | 20, 40, 99 |
| 8 | iDRAC de pve1 | access | 99 |

## Plan d'adressage

| Plage | Usage |
|-------|-------|
| .1 | Passerelle (pfSense) |
| .2 – .49 | IP fixes configurées sur les machines (infra) |
| .50 – .99 | Réservations DHCP statiques |
| .100 – .199 | Pool DHCP dynamique |
| .200 – .254 | Réserve |

| Machine | Hôte | VLAN | IP | Attribution |
|---------|------|------|----|-------------|
| proxy.example.lan | physique | 30 | 10.0.30.10 | fixe |
| docker1.example.lan | pve1.example.lan (VM 100) | 10 | 10.0.10.20 | fixe |
| nas.example.lan | pve1.example.lan (VM 101) | 10 | 10.0.10.30 | fixe |
| mon.example.lan | pve1.example.lan (VM 102) | 10 | 10.0.10.40 | fixe |
| poste-admin.example.lan | physique | 20 | 10.0.20.50 | DHCP statique |

## Firewall

Aliases : `RFC1918` (réseaux privés), `ADMIN_HOSTS` (10.0.20.50), `PORTS_WEB` (80, 443).

WAN : IP fixe 203.0.113.10, « Block private networks » et « Block bogon networks » cochés.
Règles flottantes : aucune. NAT sortant : automatique.

| Interface | Ordre | Action | Source | Destination | Port | But |
|-----------|-------|--------|--------|-------------|------|-----|
| WAN | 1 | pass | any | 10.0.30.10 | PORTS_WEB | Règle liée au NAT vers le reverse proxy |
| LAN | 1 | pass | ADMIN_HOSTS | MGMT net | 443, 22 | Administration |
| LAN | 2 | block | LAN net | MGMT net | any | Pas d'accès gestion pour les autres |
| LAN | 3 | pass | LAN net | any | any | Sortie générale |
| DMZ | 1 | pass | 10.0.30.10 | 10.0.10.20 | 8080 | Proxy vers le backend |
| DMZ | 2 | block | DMZ net | RFC1918 | any | Isolation de la DMZ |
| DMZ | 3 | pass | DMZ net | any | PORTS_WEB | Mises à jour |
| IOT | 1 | pass | IOT net | IOT address | 53, 123 | DNS et NTP locaux |
| IOT | 2 | block | IOT net | RFC1918 | any | Isolation |
| IOT | 3 | pass | IOT net | any | any | Internet seulement |

NAT (port forward) : WAN 203.0.113.10 ports 80 et 443 → 10.0.30.10.

## VPN

| Élément | Valeur |
|---------|--------|
| Type | OpenVPN, accès distant, certificat + utilisateur |
| Écoute | WAN, UDP 1194 |
| Réseau tunnel | 10.0.200.0/24 |
| Réseaux poussés | 10.0.10.0/24 |
| Règles (onglet OpenVPN) | pass tunnel → 10.0.10.20 port 443 ; pass ADMIN (IP fixe 10.0.200.10) → MGMT net ; block le reste |

| Certificat / utilisateur | IP tunnel | Accès |
|--------------------------|-----------|-------|
| admin | 10.0.200.10 (fixe) | gestion + application |
| invite | pool dynamique | application seulement |

## Services exposés

| Service | Nom public | IP publique | Port | Cible interne | Authentification |
|---------|------------|-------------|------|---------------|------------------|
| Application web | app.example.com | 203.0.113.10 | 443 | proxy.example.lan → docker1:8080 | SSO |
| VPN | vpn.example.com | 203.0.113.10 | 1194/udp | fw.example.lan | certificat + mot de passe |

## Services internes

Une ligne par service qui écoute sur le réseau, y compris les interfaces d'administration.

| Service | Hôte | Port | Adresse d'écoute | Accès autorisé depuis | Authentification |
|---------|------|------|------------------|-----------------------|------------------|
| GUI pfSense | fw.example.lan | 443 | 10.0.99.1 | ADMIN_HOSTS | compte local |
| GUI Proxmox | pve1.example.lan | 8006 | 10.0.10.10 | LAN | compte + 2FA |
| Backend de l'application | docker1.example.lan | 8080 | 10.0.10.20 | proxy.example.lan | SSO en amont |
| Partages du NAS | nas.example.lan | 445 | 10.0.10.30 | LAN | comptes nominatifs |
| CrowdSec LAPI | proxy.example.lan | 8080 | 127.0.0.1 | local | clé machine |

## DNS

| Élément | Valeur |
|---------|--------|
| Domaine local | `example.lan` |
| Résolveur | DNS Resolver (Unbound) sur toutes les interfaces internes |
| Host overrides | app.example.com → 10.0.30.10 (résolution interne directe) |
| DNS distribué par le DHCP | passerelle du VLAN |
| Enregistrements publics | chez le registrar : app et vpn → 203.0.113.10 |

## Reverse proxy

- Traefik sur `proxy.example.lan` (VLAN 30), entrypoints 80 (redirection) et 443.
- Dashboard non exposé, accessible seulement depuis ADMIN_HOSTS.
- CrowdSec : agent et LAPI sur le même hôte, LAPI en écoute sur 127.0.0.1:8080, bouncer Traefik en local.
- Certificats : ACME via challenge DNS.

## Monitoring

| Outil | Hôte | Écoute | Accès |
|-------|------|--------|-------|
| Métriques + tableaux de bord | mon.example.lan (10.0.10.40) | 10.0.10.40:3000 | LAN et VPN admin uniquement |
| Logs pare-feu | fw.example.lan → syslog vers mon.example.lan | 514/udp | interne |
