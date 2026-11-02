#!/usr/bin/env bash
# Installe et lance FlowPulse dans un GitHub Codespace (machine Linux sans carte graphique) :
# dépôts voisins, .env, Ollama en conteneur, modèles, base de connaissances.
# Lancé automatiquement à la création du Codespace ; relançable à la main : bash scripts/codespace.sh
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/installer.sh

set_env() { grep -q "^$1=" .env && sed -i "s|^$1=.*|$1=$2|" .env || echo "$1=$2" >> .env; }
# Lecture finie de /dev/urandom : « tr < /dev/urandom | head » échoue avec pipefail (signal SIGPIPE, code 141)
random() { head -c 4096 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | cut -c1-"$1"; }

# Ollama dans Docker (profil « ollama ») et petit modèle : 4 cœurs sans carte graphique
set_env COMPOSE_PROFILES ollama
set_env OLLAMA_URL http://ollama:11434
set_env DEMO_USERS true
# La page est servie par le proxy de GitHub (https://<codespace>-8081.app.github.dev) : origine à autoriser
set_env CORS_ORIGINS "https://*.app.github.dev"

# Première installation seulement : modèle léger, et mots de passe aléatoires car le lien
# du Codespace peut être rendu public
if [ ! -f .codespace-done ]; then
  set_env LLM_MODEL "${LLM_MODEL:-llama3.2:3b}"
  set_env ADMIN_EMAIL admin@flowpulse.local
  set_env ADMIN_PASSWORD "$(random 14)"
  set_env DEMO_PASSWORD "$(random 10)"
fi
# Clé de signature des jetons : jamais la valeur d'exemple
grep -q '^JWT_SECRET=remplacer' .env && set_env JWT_SECRET "$(random 48)"
true

docker compose up -d --build
model=$(grep '^LLM_MODEL=' .env | cut -d= -f2)
docker compose exec -T ollama ollama pull "$model"
docker compose exec -T ollama ollama pull nomic-embed-text
docker compose exec -T ai-service python /kb/scripts/ingest.py --all || echo "Indexation incomplète : relancer « docker compose exec ai-service python /kb/scripts/ingest.py --all »"
touch .codespace-done

cat <<MSG

FlowPulse est prêt. Onglet « Ports » → port 8081 « FlowPulse » → ouvrir dans le navigateur.
  Administrateur : $(grep '^ADMIN_EMAIL=' .env | cut -d= -f2) / $(grep '^ADMIN_PASSWORD=' .env | cut -d= -f2)
  Démo           : gestionnaire@, operateur@, urbaniste@flowpulse.local / $(grep '^DEMO_PASSWORD=' .env | cut -d= -f2)
Ces valeurs restent lisibles dans flowpulse/.env.
MSG
