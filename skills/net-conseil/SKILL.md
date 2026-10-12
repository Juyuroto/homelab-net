---
name: net-conseil
description: Conseille sur l'évolution du homelab à partir de la topologie privée — quel logiciel ou service installer pour un besoin et sur quelle machine, quoi réutiliser, déplacer ou retirer, quel matériel acheter (occasion d'abord) — classé par utilité, sans notion de budget. À utiliser quand l'utilisateur demande quoi installer, où l'héberger, quoi acheter, quel serveur prendre, comment faire évoluer ou agrandir son infra.
---

# Conseil d'évolution

Besoin : $ARGUMENTS

Conseil **en lecture seule** : ne rien modifier, ne rien exécuter sur le réseau, ne rien installer, ne rien acheter.

1. Lire `~/.claude/homelab-net/topology.md` en entier, sauf s'il a déjà été lu en entier dans cette session et n'a pas été modifié depuis.
   - Absent : le dire, expliquer comment le créer depuis `${CLAUDE_PLUGIN_ROOT}/templates/topology.example.md`, et conseiller seulement sur ce que dit l'utilisateur. Ne pas inventer de topologie.
2. Selon le besoin donné :
   - **un service ou un logiciel** (« je veux un registre Docker local », « je veux superviser mes VM ») : suivre « Conseil de service » ;
   - **du matériel ou de la capacité** (« plus de stockage », « quel serveur prendre ») : suivre « Conseil matériel » pour ce besoin seulement ;
   - **aucun besoin** : faire le constat de l'existant et suivre « Conseil matériel », puis citer les services qui manquent visiblement à l'infra (sauvegarde, supervision, DNS interne…), sans les détailler.
3. Ne poser de question que si la réponse change le conseil et n'est pas dans la topologie.
4. **Ne pas parler de budget** : ne pas en demander, ne pas filtrer ni classer par prix, ne pas annoncer de prix. Le marché visé est l'occasion (serveurs et PC reconditionnés, petites annonces), où le prix dépend de l'annonce du jour.
5. Signaler séparément ce que la topologie **ne dit pas** et qui empêche de conclure (charge réelle CPU/RAM/disque, espace libre, consommation mesurée). Proposer la commande en lecture seule qui donnerait la mesure. Un conseil fondé sur les specs seules le dit.

## Conseil de service

1. **Quoi installer** : deux ou trois logiciels qui répondent au besoin, du plus simple au plus complet, avec ce que chacun apporte et coûte en entretien. En recommander un, et dire pourquoi pour cette infra. Préférer ce qui est déjà en place (un service existant qui sait le faire, la pile déjà utilisée) à un outil de plus.
2. **Où l'héberger** : le nœud, et la forme (VM, conteneur LXC, ou conteneur Docker sur une VM existante), justifiés par le rôle déjà donné à chaque nœud, sa capacité, et le stockage qu'il voit. Dire aussi où ne pas le mettre.
3. **Dimensionnement** : CPU, RAM, disque de départ, et le stockage des données s'il est séparé du disque système.
4. **Réseau** : VLAN, IP libre, nom DNS interne, port d'écoute, qui doit le joindre. Ne pas l'exposer sur Internet sauf besoin exprimé.
5. **Sauvegarde** : ce qu'il faut sauvegarder et vers où.
6. **Ce que ça change pour l'existant** : les machines ou services à reconfigurer pour s'en servir.

En cas de doute sur une option, une version ou un prérequis d'un logiciel, le dire ou vérifier dans sa documentation plutôt que l'affirmer.

Terminer par la suite : `/lab:net-plan` si le service demande une règle de pare-feu, un VLAN ou une exposition, `/lab:pve-create` pour créer la VM ou le conteneur, puis `/lab:net-add`.

## Conseil matériel

Constat de l'existant :

- **Capacité** : CPU, RAM et stockage par nœud ; nœud vide ou sous-utilisé ; nœud trop petit pour ce qu'il porte.
- **Points uniques de panne** : un seul pare-feu, un seul switch, un seul NAS, sauvegardes sur le même matériel que les données, pas d'onduleur.
- **Réseau** : ports libres du switch, débit des liens, absence de trunk, de PoE ou de Wi-Fi séparé si un besoin en dépend.
- **Âge et consommation** : génération du matériel, serveurs anciens qui chauffent, font du bruit et consomment pour peu de puissance.

Tableau trié par utilité, puis le détail de chaque ligne :

| Priorité | Action | Sur quoi | Pourquoi |
|----------|--------|----------|----------|

- **Action** : réutiliser, déplacer, retirer, ou acheter. Toujours chercher d'abord ce qui se règle sans achat (nœud vide, charge mal répartie).
- **Haute** : supprime un point unique de panne ou un risque de perte de données.
- **Moyenne** : lève une limite qui bloque un besoin exprimé.
- **Basse** : confort, consommation, bruit.

Pour chaque achat conseillé :

- les caractéristiques à viser (génération de CPU, RAM, baies, cartes réseau, format), pas un modèle unique ;
- deux ou trois familles de modèles courantes en occasion qui y répondent, et ce qu'il faut vérifier sur l'annonce (disques inclus ou non, rails, alimentations, licence de gestion hors bande, génération) ;
- ce qu'il ne faut pas prendre et pourquoi ;
- comment il s'insère : port du switch, VLAN, IP libre, rôle dans le cluster.

En cas de doute sur une caractéristique d'un modèle, le dire ou vérifier par une recherche web plutôt que l'affirmer.

Terminer par l'action à faire en premier. Une fois l'achat fait et la machine branchée : `/lab:net-plan` si le réseau change, puis `/lab:net-add`.
