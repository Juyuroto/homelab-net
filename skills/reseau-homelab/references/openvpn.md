# Accès distant OpenVPN — moindre privilège

Principe : un client VPN n'est pas un poste du LAN. Il n'obtient que ce dont il a besoin, et rien par défaut.

## Ce qui rend un VPN trop large

- Règle « pass any → any » sur l'onglet OpenVPN (c'est ce que crée l'assistant).
- Tous les réseaux internes poussés aux clients alors qu'un seul sert.
- Accès au VLAN de gestion pour tous les profils.
- Un seul certificat partagé entre plusieurs personnes ou appareils.
- Communication entre clients activée sans besoin.

## Configuration côté serveur

- **Réseau du tunnel** dédié, hors des plages internes (ex. `10.0.200.0/24`).
- **IPv4 Local Network(s)** : seulement les sous-réseaux réellement utiles. C'est ce qui est routé chez le client.
- **Redirect gateway** désactivé sauf besoin de faire sortir tout le trafic par le homelab.
- **Authentification** : certificat par utilisateur/appareil **et** identifiant ; clé TLS (`tls-crypt`) ; CRL tenue à jour pour révoquer un appareil perdu.
- **Inter-client communication** désactivée.
- DNS poussé : le résolveur interne, si les noms locaux sont nécessaires.

## Règles sur l'onglet OpenVPN

La route poussée ne protège rien : un client peut ajouter une route à la main. Seules les règles filtrent.

| # | Action | Source | Destination | Port | But |
|---|--------|--------|-------------|------|-----|
| 1 | pass | IP tunnel de l'admin | MGMT net | 443, 22 | Administration, profil admin seulement |
| 2 | pass | réseau tunnel | serveur applicatif | 443 | Usage courant |
| 3 | pass | réseau tunnel | DNS interne | 53 | Résolution |
| 4 | block (log) | réseau tunnel | any | any | Tout le reste, journalisé |

## Différencier les profils

- **Client Specific Overrides** : attribuer une IP de tunnel fixe à un certificat (par son CN), puis écrire des règles sur cette IP.
- Ou deux serveurs OpenVPN (admin / usage courant) avec deux réseaux de tunnel : plus simple à auditer.

## Vérifier (lecture seule)

Depuis un client connecté :

```bash
ip route                      # quelles routes ont été poussées ?
nc -vz 10.0.99.1 443          # le réseau de gestion doit être injoignable pour un profil normal
dig @10.0.10.1 fw.example.lan # le DNS interne répond-il ?
```

Sur pfSense : Status > OpenVPN (clients connectés, IP attribuées), journaux du pare-feu filtrés sur le réseau du tunnel.
