#!/usr/bin/env bash
# Clone les dépôts FlowPulse côte à côte dans le dossier parent, puis prépare le .env.
# Usage (depuis le dossier qui contiendra les dépôts) :
#   git clone https://github.com/Mboa-Labs/flowpulse.git && bash flowpulse/scripts/installer.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
for repo in flowpulse-frontend flowpulse-backend flowpulse-ai-service flowpulse-knowledge-base; do
  if [ -d "$repo/.git" ]; then
    echo "• $repo déjà présent"
  else
    git clone "https://github.com/Mboa-Labs/$repo.git"
  fi
done
cd flowpulse
if [ ! -f .env ]; then
  cp .env.example .env
  secret=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48)
  sed -i.bak "s/^JWT_SECRET=.*/JWT_SECRET=$secret/" .env && rm -f .env.bak
  echo "• .env créé (clé JWT générée). Changez ADMIN_PASSWORD avant une démo publique."
fi
echo "Terminé. Étape suivante : ollama pull qwen2.5:7b && ollama pull nomic-embed-text, puis docker compose up -d --build"
