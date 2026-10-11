#!/usr/bin/env bash
# Versions datées de la topologie privée : save | list | use <version>.
# topology.md reste toujours le fichier actif ; versions/<date>/topology.md en sont des copies.
set -eu
umask 077
d="${HOMELAB_NET_DIR:-$HOME/.claude/homelab-net}"
f="$d/topology.md"
v="$d/versions"

save() {
  [ -r "$f" ] || { echo "pas de $f" >&2; exit 1; }
  l=$(ls -1 "$v" 2>/dev/null | tail -n 1)
  if [ -n "$l" ] && cmp -s "$f" "$v/$l/topology.md"; then
    echo "déjà sauvegardé : $l"
    return
  fi
  n=$(date +%Y-%m-%d_%H-%M-%S)
  mkdir -p "$v/$n"
  cp -p "$f" "$v/$n/topology.md"
  echo "sauvegardé : $n"
}

case "${1:-}" in
  save) save ;;
  list)
    # « * » = identique à la topologie active
    for p in "$v"/*/topology.md; do
      [ -e "$p" ] || { echo "aucune version"; exit 0; }
      n=$(basename "$(dirname "$p")")
      if cmp -s "$f" "$p"; then echo "* $n"; else echo "  $n"; fi
    done ;;
  use)
    t="$v/${2:?version manquante}/topology.md"
    [ -r "$t" ] || { echo "version inconnue : $2" >&2; exit 1; }
    save # l'état courant, modifications à la main comprises, n'est jamais perdu
    cp "$t" "$f"
    echo "topologie active : $2" ;;
  *) echo "usage : $0 save | list | use <version>" >&2; exit 2 ;;
esac
