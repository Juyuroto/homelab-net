# Proxmox : bridges et VLAN

Le bridge et le port du switch doivent décrire la même chose. La plupart des pannes viennent d'un désaccord entre les deux.

## Les trois montages

| Montage | Port du switch | Bridge | VM | Quand |
|---------|----------------|--------|----|-------|
| **Sans tag** | access, VLAN X | `vmbr0` simple | pas de tag | Un seul VLAN pour l'hôte et ses VM |
| **Un bridge par VLAN** | trunk | `vmbr10` sur `eno1.10`, `vmbr20` sur `eno1.20`… | pas de tag, on choisit le bridge | Peu de VLAN, lecture explicite |
| **VLAN-aware** | trunk | `vmbr0` avec `bridge-vlan-aware yes` | tag sur la carte de la VM | Plusieurs VLAN, montage courant |

### Sans tag (hyperviseur sur port access)

```
auto vmbr0
iface vmbr0 inet static
    address 10.0.10.10/24
    gateway 10.0.10.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
```

Tout ce qui est branché sur `vmbr0` est dans le VLAN du port. **Mettre un tag sur une VM dans ce montage fait perdre son trafic** : le port access rejette les trames taggées.

Pour d'autres VLAN sans toucher au trunk : une carte physique supplémentaire sur un autre port access, avec son propre bridge sans adresse IP.

### VLAN-aware

```
auto vmbr0
iface vmbr0 inet manual
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 10 20 30

auto vmbr0.10
iface vmbr0.10 inet static
    address 10.0.10.10/24
    gateway 10.0.10.1
```

- `bridge-vids` restreint aux VLAN utiles, comme la liste autorisée du trunk côté switch.
- L'IP de gestion de l'hôte passe sur une sous-interface `vmbr0.<id>`.
- Une VM sans tag se retrouve dans le VLAN natif du trunk : le choisir en conséquence.

## Interaction avec le switch

- Les VLAN autorisés sur le trunk doivent inclure tous ceux utilisés par les VM.
- PVID / VLAN natif identiques des deux côtés.
- pfSense virtualisé : soit le bridge tague et pfSense voit des interfaces simples, soit pfSense tague et la carte de la VM n'a pas de tag. Jamais les deux.
- Le pare-feu Proxmox (datacenter / nœud / VM) filtre en plus de pfSense : le vérifier quand « tout semble bon ».

## Observer (lecture seule)

```bash
cat /etc/network/interfaces      # config déclarée
ip -d link show vmbr0            # vlan_filtering 1 = VLAN-aware
bridge vlan show                 # VLAN par port du bridge
bridge link show                 # ports rattachés aux bridges
qm config <vmid> | grep ^net     # bridge et tag d'une VM
pct config <ctid> | grep ^net    # idem pour un conteneur
```

## Modifier : validation obligatoire

Passer un bridge en VLAN-aware ou changer un port en trunk peut couper l'accès à l'hyperviseur. Avant de proposer `ifreload -a` ou un changement côté switch :

1. confirmer qu'un accès console (écran, IPMI) existe ;
2. donner l'ordre des opérations des deux côtés et le moment de la coupure ;
3. garder une copie de `/etc/network/interfaces` ;
4. attendre la validation de l'utilisateur.
