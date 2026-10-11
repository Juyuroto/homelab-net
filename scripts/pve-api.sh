#!/usr/bin/env bash
# Appel de l'API Proxmox avec le jeton de proxmox.env : pve-api.sh <MÉTHODE> <chemin> [clé=valeur…]
# Le jeton passe par l'entrée standard de curl : ni dans la commande, ni dans la liste des processus.
set -eu
e="${HOMELAB_NET_DIR:-$HOME/.claude/homelab-net}/proxmox.env"
[ -r "$e" ] || { echo "pas de $e (PVE_HOST, PVE_TOKEN_ID, PVE_TOKEN_SECRET)" >&2; exit 1; }
. "$e"
m="${1:?méthode manquante}"
p="${2:?chemin manquant}"
shift 2

# shortcut: sans PVE_CACERT le certificat n'est pas vérifié (auto-signé par défaut), renseigner PVE_CACERT=/chemin/pve-root-ca.pem dans proxmox.env
if [ -n "${PVE_CACERT:-}" ]; then a=(--cacert "$PVE_CACERT"); else a=(-k); fi
[ "$m" = GET ] && a+=(--get)
for kv in "$@"; do a+=(--data-urlencode "$kv"); done

case "$PVE_HOST" in *:*) h="$PVE_HOST" ;; *) h="$PVE_HOST:8006" ;; esac
printf 'header = "Authorization: PVEAPIToken=%s=%s"\n' "$PVE_TOKEN_ID" "$PVE_TOKEN_SECRET" |
  curl -sS --fail-with-body --max-time 30 -K - -X "$m" "${a[@]}" "https://$h/api2/json$p"
echo
