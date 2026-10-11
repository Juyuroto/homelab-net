# Dépannage en couches

Monter de L1 à L7 et s'arrêter à la première couche qui échoue. Tout ce qui est en dessous est validé, tout ce qui est au-dessus est hors sujet pour l'instant.

Avant de commencer, faire préciser : **depuis où**, **vers quoi** (IP ou nom, port), **depuis quand**, **qu'est-ce qui a changé**. Tester aussi dans l'autre sens et depuis un autre VLAN : la différence localise souvent la panne.

Toutes les commandes ci-dessous sont en lecture seule.

## L1 — Physique

```bash
ip -br link                 # état UP/DOWN de chaque interface
ethtool eno1                # lien détecté, vitesse, duplex
ip -s link show eno1        # compteurs d'erreurs et de pertes
```

Échec : câble, port du switch désactivé, carte virtuelle déconnectée.

## L2 — Liaison (Ethernet, VLAN, ARP)

```bash
ip neigh                                # la passerelle a-t-elle une MAC ? (REACHABLE vs FAILED)
bridge vlan show                        # VLAN par port (bridges Linux, Proxmox)
tcpdump -eni eno1 arp                   # les requêtes ARP partent-elles, les réponses reviennent-elles ?
tcpdump -eni eno1 vlan                  # voit-on des trames taggées, avec quel ID ?
```

Échec typique : ARP sans réponse = mauvais VLAN (PVID, tag, VLAN absent du trunk).

## L3 — Réseau (IP, routage)

```bash
ip -br addr                             # adresse et masque corrects ?
ip route                                # route par défaut présente ?
ip route get 10.0.20.50                 # par quelle interface et passerelle ce trafic sort-il ?
ping -c 3 10.0.10.1                     # passerelle
ping -c 3 10.0.20.50                    # cible
traceroute -n 10.0.20.50                # où ça s'arrête
```

Passerelle joignable mais pas la cible : routage ou règle de pare-feu. Un ping bloqué ne prouve rien si l'ICMP est filtré : passer à L4.

## L4 — Transport (ports)

```bash
ss -tulpn                               # sur la cible : le service écoute-t-il, et sur quelle adresse ?
nc -vz 10.0.20.50 443                   # depuis la source : le port répond-il ?
tcpdump -ni any host 10.0.20.50 and port 443   # des deux côtés : le SYN arrive-t-il, le SYN-ACK repart-il ?
```

Lire le résultat de `nc` :
- *refused* : la machine répond, rien n'écoute (ou écoute sur `127.0.0.1` seulement) ;
- *timeout* : paquet perdu en route, presque toujours un pare-feu ;
- `ss` montre `127.0.0.1:port` : service local seulement ; `0.0.0.0:port` : toutes les interfaces.

`tcpdump` des deux côtés tranche : SYN vu à la source mais pas à la cible = bloqué entre les deux ; SYN vu à la cible sans réponse = pare-feu de l'hôte ou route de retour.

## L7 — Application (DNS, HTTP, TLS)

```bash
dig app.example.com                     # quelle IP, depuis quel résolveur ?
dig @10.0.10.1 app.example.com          # même question au résolveur interne
dig +short -x 10.0.20.50                # résolution inverse
curl -v https://app.example.com         # résolution, connexion, TLS, code HTTP
curl -vk --resolve app.example.com:443:10.0.30.10 https://app.example.com   # contourner le DNS
curl -v http://10.0.10.20:8080          # le backend directement, sans le proxy
```

« Ça marche par IP mais pas par nom » : DNS. 502/504 derrière un proxy : le proxy ne joint pas le backend, reprendre à L3 depuis le proxy. 404 du proxy : règle de routage (nom d'hôte, entrypoint).

## Côté pare-feu

Quand L3 ou L4 pointe vers pfSense : journaux du pare-feu (paquet bloqué, par quelle règle), table d'états, capture de paquets sur l'interface d'entrée puis de sortie. Voir [pfsense.md](pfsense.md).

## Pièges fréquents

- Routage asymétrique : l'aller passe par le pare-feu, le retour non (machine avec deux interfaces).
- Pare-feu de l'hôte (nftables, ufw, pare-feu Proxmox) oublié.
- MTU : petits paquets OK, gros transferts bloqués, souvent à travers un VPN. `ping -M do -s 1472 <cible>` pour tester.
- Cache DNS ou ARP périmé après un changement d'adresse.
- Test fait depuis le LAN pour valider un accès « depuis Internet ».
