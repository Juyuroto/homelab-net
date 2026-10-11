---
name: net-check
description: Vérifie le fichier privé topology.md lui-même — contradictions entre sections, IP en double ou hors plage, références vers une machine ou un VLAN non déclaré, champs manquants — sans juger la sécurité du réseau. À utiliser après une modification de la topologie, ou avant un audit, un plan ou un schéma.
---

# Vérification de la topologie

Contrôle **du fichier**, pas du réseau : ne rien exécuter, ne rien modifier. Les risques de sécurité relèvent de `/homelab-net:net-audit`.

1. Lire `~/.claude/homelab-net/topology.md` en entier, sauf s'il a déjà été lu en entier dans cette session et n'a pas été modifié depuis.
   - Absent : le dire et expliquer comment le créer depuis `${CLAUDE_PLUGIN_ROOT}/templates/topology.example.md`.
2. Chercher les **incohérences** :
   - **Adressage** : IP en double ; IP hors du sous-réseau de son VLAN ; IP « fixe » dans le pool DHCP ou réservation hors de sa plage ; passerelle différente d'une section à l'autre ; sous-réseaux qui se chevauchent.
   - **Références** : IP, nom de machine, VLAN, alias ou hyperviseur cité dans une section (règles, NAT, VPN, services, switch) mais déclaré nulle part dans l'inventaire.
   - **Sections qui se contredisent** : même service décrit avec une IP ou un port différent selon l'endroit ; NAT sans règle correspondante, ou l'inverse ; résumé d'une section qui ne dit pas la même chose que son tableau.
   - **Pare-feu** : adresse d'hôte écrite avec un masque de réseau (`10.0.30.10/24`) ; règle jamais atteinte parce qu'une règle plus haute couvre déjà le trafic ; même numéro d'ordre pour deux règles dont l'ordre compte.
   - **Câblage** : port du switch utilisé deux fois ; mode du port (access, trunk) incompatible avec le bridge de l'hyperviseur ; machine dans un VLAN que son port ne transporte pas.
   - **Structure** : section du modèle absente ; plus d'un tableau sous le titre contenant « VLAN » (le résumé de démarrage reprend tous les tableaux de cette section).
   - **Secrets** : tout ce qui ressemble à un mot de passe, une clé ou un token n'a rien à faire dans ce fichier.
3. Relever les **manques** : cellules à `?` ou vides, et ce qu'ils empêchent — adresse d'écoute inconnue pour `net-audit`, port du switch inconnu pour `net-debug`.
4. Entre deux valeurs qui se contredisent, **ne pas choisir** : citer les deux et demander laquelle est vraie. Seul l'utilisateur sait ce qui tourne réellement.

## Format de sortie

| Type | Où (section, ligne) | Constat | Question ou correction proposée |
|------|---------------------|---------|---------------------------------|

Incohérences d'abord, manques ensuite regroupés par commande pénalisée. Terminer par les trois points à régler en premier.

Les corrections sont des propositions : l'utilisateur les applique, ou les valide une par une pour qu'elles soient écrites dans le fichier.

$ARGUMENTS
