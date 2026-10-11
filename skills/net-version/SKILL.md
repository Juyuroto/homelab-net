---
name: net-version
description: Liste les versions datées de la topologie privée du homelab, en enregistre une nouvelle, compare deux versions ou revient à une version précédente — l'équivalent de git log / commit / diff / checkout pour topology.md. À utiliser quand l'utilisateur veut voir l'historique de sa topologie, revenir en arrière, annuler un ajout ou changer de version.
argument-hint: [liste | save | diff <version> | <version>]
---

# Versions de la topologie

Demande : $ARGUMENTS

`~/.claude/homelab-net/topology.md` est **toujours** le fichier actif : c'est lui que lisent les autres skills, y compris après une modification à la main. Chaque version est une copie dans `~/.claude/homelab-net/versions/<AAAA-MM-JJ_HH-MM-SS>/topology.md`. Ne jamais modifier ni supprimer un dossier de version.

Tout passe par le script (ne pas copier les fichiers à la main) :

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/topo-version.sh" list            # « * » = identique à la topologie active
bash "${CLAUDE_PLUGIN_ROOT}/scripts/topo-version.sh" save            # nouvelle version si le fichier a changé
bash "${CLAUDE_PLUGIN_ROOT}/scripts/topo-version.sh" use <version>   # sauvegarde l'état courant, puis active <version>
```

1. Sans argument, ou `liste` : lancer `list` et afficher les versions, la plus récente en premier, en marquant celle qui est active. Aucune `*` : la topologie a été modifiée depuis la dernière sauvegarde, le dire et proposer `save`.
2. `save` : lancer `save` et dire le nom du dossier créé.
3. `diff <version>` : `diff -u ~/.claude/homelab-net/versions/<version>/topology.md ~/.claude/homelab-net/topology.md`, puis résumer ce qui a changé (machines, IP, règles), pas le diff brut.
4. Changer de version :
   - version non précisée ou ambiguë (« celle d'hier », « avant le NAS ») : lancer `list`, proposer les candidates avec `AskUserQuestion`, au besoin en regardant leur diff ;
   - montrer en deux ou trois lignes ce que le retour va défaire (diff avec la version visée) ;
   - lancer `use <version>` sans autre question : l'état courant est sauvegardé d'abord, le retour est donc toujours annulable ;
   - dire quelle version est active et le nom de la sauvegarde qui permet de revenir.
5. Après un changement de version, la topologie lue plus tôt dans la session est périmée : la relire avant de s'en servir. Rappeler que le fichier décrit le réseau, il ne le modifie pas : si la version activée ne correspond plus au réel, proposer `/homelab-net:net-check`.
