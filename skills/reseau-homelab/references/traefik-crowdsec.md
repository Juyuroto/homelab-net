# Reverse proxy Traefik + CrowdSec

Objectif : une seule porte d'entrée, la plus petite possible.

## Exposition minimale

- Seuls **80 et 443** sont redirigés depuis Internet, vers le proxy et rien d'autre. Le proxy est en DMZ.
- 80 ne sert qu'à rediriger vers 443 (ou est fermé si le challenge ACME est en DNS).
- Depuis la DMZ, le proxy ne joint que ses backends, port par port (règles pfSense), pas « SERVEURS net ».
- Un service à usage interne n'a pas de route publique : entrypoint interne distinct, ou middleware `ipAllowList` limité aux réseaux internes et VPN.
- Préférer le VPN à l'exposition publique pour tout ce qui est administration.

## Traefik

- `providers.docker.exposedByDefault=false` : un conteneur n'est publié que s'il le demande.
- **Dashboard / API** : `api.insecure=false`. S'il est utile, le router derrière une authentification et une liste d'IP, jamais sur un entrypoint public.
- **Socket Docker** : l'accès au socket équivaut à root sur l'hôte. Le passer par un proxy de socket en lecture seule plutôt que de le monter directement.
- **Ports publiés** : Docker publie sur `0.0.0.0` par défaut et écrit ses propres règles, ce qui contourne le pare-feu de l'hôte. Les backends n'ont pas besoin de `ports:` s'ils partagent un réseau Docker avec Traefik ; sinon lier à une IP précise (`127.0.0.1:8080:8080`).
- `forwardedHeaders.trustedIPs` limité aux proxys amont réels, sinon l'IP cliente est falsifiable et CrowdSec bannit la mauvaise adresse.
- TLS : version minimale 1.2, en-têtes de sécurité via middleware, certificats ACME (challenge DNS si l'on veut fermer 80).
- Journaux d'accès activés : CrowdSec en a besoin.

## CrowdSec

Trois rôles : l'**agent** lit les journaux et détecte, la **LAPI** stocke les décisions, le **bouncer** les applique (plugin ou middleware Traefik).

- **LAPI** : écoute sur `127.0.0.1:8080` par défaut, et doit y rester si agent et bouncer sont sur le même hôte.
- Si un bouncer ou un agent est sur une autre machine : écoute sur l'IP interne du bon VLAN (pas `0.0.0.0`), règle pare-feu limitée à cette source, TLS. **Jamais** de redirection de port depuis Internet vers la LAPI.
- En conteneur : ne pas publier le port de la LAPI ; le bouncer la joint par le réseau Docker.
- Même prudence pour le port de métriques.
- Clés de bouncer et identifiants d'agent : dans des secrets ou un `.env` non versionné.
- Mettre en liste blanche ses propres réseaux (LAN, tunnel VPN) pour ne pas se bannir soi-même.
- Vérifier que le bouncer échoue fermé ou ouvert selon ce qu'on veut si la LAPI est injoignable.

## Vérifier (lecture seule)

```bash
ss -tulpn                                  # qui écoute sur 0.0.0.0 ou [::] ?
docker ps --format '{{.Names}}\t{{.Ports}}' # ports publiés par conteneur
cscli lapi status                          # la LAPI répond-elle ?
cscli bouncers list                        # bouncers enregistrés
cscli decisions list                       # décisions actives
curl -sI https://app.example.com           # en-têtes et redirection
```

Depuis l'extérieur (réseau mobile, pas le LAN) : seuls 80/443 doivent répondre.
