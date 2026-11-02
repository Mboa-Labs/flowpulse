#!/usr/bin/env bash
# Sauvegarde de la base FlowPulse (comptes, journal d'audit, recommandations, simulations, traces).
# Garde les 14 dernières sauvegardes. À planifier chaque nuit (docs/DEPLOIEMENT_VPS.md, étape 6) :
#   30 2 * * * bash ~/flowpulse-workspace/flowpulse/scripts/sauvegarde.sh >> ~/flowpulse-sauvegardes/journal.txt 2>&1
set -euo pipefail
cd "$(dirname "$0")/.."
dossier="${SAUVEGARDES:-$HOME/flowpulse-sauvegardes}"
mkdir -p "$dossier" && chmod 700 "$dossier"
fichier="$dossier/flowpulse_$(date +%Y-%m-%d_%H%M).sql.gz"
utilisateur=$(grep '^DB_USER=' .env | cut -d= -f2-)
docker compose exec -T postgres pg_dump -U "${utilisateur:-flowpulse}" -d flowpulse --no-owner | gzip > "$fichier"
chmod 600 "$fichier"
ls -1t "$dossier"/flowpulse_*.sql.gz | tail -n +15 | xargs -r rm --
echo "$(date '+%F %T') sauvegarde : $fichier ($(du -h "$fichier" | cut -f1))"
