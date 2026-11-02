#!/usr/bin/env bash
# Déploiement continu, lancé toutes les 5 minutes par cron sur le serveur (docs/DEPLOIEMENT_VPS.md, étape 7).
#
# Pour chaque dépôt : si GitHub a une nouvelle version de main ET que ses tests (GitHub Actions) ont réussi,
# le serveur la récupère, puis reconstruit et redémarre les services. Une version dont les tests échouent
# n'est jamais déployée. Aucune clé n'est confiée à GitHub : c'est le serveur qui va chercher les versions.
set -euo pipefail
cd "$(dirname "$0")/../.."
ORG=Mboa-Labs
ETAT="$HOME/.flowpulse-deploiement"  # dernières versions refusées, pour ne pas répéter le même message
mkdir -p "$ETAT"

# Une seule exécution à la fois (un déploiement peut durer plus de 5 minutes)
exec 9>"$ETAT/verrou"
flock -n 9 || exit 0

journal() { echo "$(date '+%F %T') $*"; }

# Verdict des tests GitHub pour un commit : ok, echec ou attente (tests pas encore lancés ou en cours)
verdict() {
  gh api "repos/$ORG/$1/commits/$2/check-runs" --jq '
    if (.check_runs | length) == 0 then "attente"
    elif any(.check_runs[]; .status != "completed") then "attente"
    elif all(.check_runs[]; .conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral") then "ok"
    else "echec" end' 2>/dev/null || echo "attente"
}

deploye=()
reindexer=false
for repo in flowpulse flowpulse-frontend flowpulse-backend flowpulse-ai-service flowpulse-knowledge-base; do
  git -C "$repo" fetch -q origin main || { journal "$repo : GitHub injoignable"; continue; }
  local_sha=$(git -C "$repo" rev-parse HEAD)
  distant=$(git -C "$repo" rev-parse origin/main)
  [ "$local_sha" = "$distant" ] && continue

  case "$(verdict "$repo" "$distant")" in
    attente) continue ;;  # on réessaiera au prochain passage
    echec)
      if [ "$(cat "$ETAT/$repo.refuse" 2>/dev/null)" != "$distant" ]; then
        journal "$repo ${distant:0:7} : tests en échec sur GitHub, version NON déployée"
        echo "$distant" > "$ETAT/$repo.refuse"
      fi
      continue ;;
  esac

  # Textes de loi ou script d'indexation modifiés : la base de connaissances sera réindexée
  if [ "$repo" = flowpulse-knowledge-base ] && git -C "$repo" diff --name-only "$local_sha" "$distant" | grep -qE '^(sources\.csv|InputDocs/|scripts/ingest\.py|registres/)'; then
    reindexer=true
  fi
  git -C "$repo" merge -q --ff-only origin/main
  journal "$repo : ${local_sha:0:7} → ${distant:0:7} ($(git -C "$repo" log -1 --format=%s | cut -c1-80))"
  deploye+=("$repo")
done

[ ${#deploye[@]} -eq 0 ] && exit 0

cd flowpulse
journal "Reconstruction et redémarrage : ${deploye[*]}"
docker compose up -d --build --remove-orphans 2>&1 | tail -3
# Le backend met environ une minute à démarrer : attendre les contrôles de santé avant de vérifier
for _ in $(seq 1 30); do
  docker compose ps --format '{{.Status}}' | grep -q 'starting' || break
  sleep 10
done
if $reindexer; then
  journal "Réindexation de la base de connaissances"
  docker compose exec -T ai-service python /kb/scripts/ingest.py --all --reset | tail -2
fi
bash scripts/verifier.sh | sed 's/\x1b\[[0-9;]*m//g'
docker image prune -f >/dev/null  # images remplacées : libérer le disque
journal "Déploiement terminé"
