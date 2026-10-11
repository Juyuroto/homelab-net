#!/usr/bin/env bash
# Résumé court de la topologie privée : titres de sections + tableau des VLANs.
# Silencieux et exit 0 si le fichier est absent : ne doit jamais bloquer une session.
f="$HOME/.claude/homelab-net/topology.md"
[ -r "$f" ] || exit 0

{
  echo "homelab-net : une topologie privée existe dans $f (résumé ci-dessous ; ne lire que les sections utiles avec Read offset/limit, une seule fois par session tant que le fichier ne change pas)."
  echo "Sections (ligne de début) : $(awk '/^## /{sub(/^## /, ""); printf "%s%s L%d", s, $0, NR; s=", "}' "$f")"
  echo "VLANs :"
  # lignes de tableau de la section dont le titre contient « vlan », sans la ligne de séparation
  awk '/^## /{v = tolower($0) ~ /vlan/} v && /^\|/ && !/^\|[ :|-]+$/' "$f" | head -n 20
} 2>/dev/null | head -c 2000
exit 0
