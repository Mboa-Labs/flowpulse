#!/usr/bin/env bash
# Récupère les dernières versions de tous les dépôts et reconstruit les services.
set -euo pipefail
cd "$(dirname "$0")/../.."
for repo in flowpulse flowpulse-frontend flowpulse-backend flowpulse-ai-service flowpulse-knowledge-base; do
  echo "• $repo"; git -C "$repo" pull --ff-only
done
cd flowpulse && docker compose up -d --build && docker compose ps
