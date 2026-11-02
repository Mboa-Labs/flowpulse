#!/usr/bin/env bash
# Installe et lance FlowPulse sur un serveur Linux (VPS) partagé avec d'autres applications.
# Sans sudo : à lancer par un utilisateur membre du groupe docker, depuis le dossier qui contient flowpulse/.
#   bash flowpulse/scripts/serveur.sh
# Relançable sans risque : ne régénère jamais un mot de passe déjà créé.
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/installer.sh

set_env() { grep -q "^$1=" .env && sed -i "s|^$1=.*|$1=$2|" .env || echo "$1=$2" >> .env; }
get_env() { grep "^$1=" .env | cut -d= -f2- || true; }
# Lecture finie de /dev/urandom : « tr < /dev/urandom | head » échoue avec pipefail (signal SIGPIPE)
random() { head -c 4096 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | cut -c1-"$1"; }

# Production : limites de ressources, interface sur 127.0.0.1 derrière le nginx de l'hôte, Ollama en conteneur
set_env COMPOSE_FILE docker-compose.yml:docker-compose.prod.yml
set_env COMPOSE_PROFILES ollama
set_env OLLAMA_URL http://ollama:11434
# Port local de l'interface (8081 par défaut ailleurs ; 8095 ici, libre sur le serveur et attendu par le site nginx)
case "$(get_env APP_PORT)" in ""|8081) set_env APP_PORT "${APP_PORT:-8095}" ;; esac
# Modèle de langage : 3b par défaut sur processeur (le 7b de l'exemple est trop lourd sans carte graphique)
case "$(get_env LLM_MODEL)" in ""|qwen2.5:7b) set_env LLM_MODEL "${LLM_MODEL:-llama3.2:3b}" ;; esac

# Secrets : générés une seule fois. Le mot de passe de la base doit l'être avant le tout premier démarrage.
if [ ! -f .serveur-secrets ]; then
  if docker volume inspect flowpulse_pgdata >/dev/null 2>&1; then
    echo "La base existe déjà : son mot de passe n'est pas changé."
  else
    set_env DB_PASSWORD "$(random 32)"
  fi
  set_env JWT_SECRET "$(random 64)"
  set_env ADMIN_EMAIL "${ADMIN_EMAIL:-admin@flowpulse.local}"
  set_env ADMIN_PASSWORD "$(random 20)"
  # Comptes de démonstration désactivés en production ; à activer seulement pour une séance de démo
  set_env DEMO_USERS "${DEMO_USERS:-false}"
  set_env DEMO_PASSWORD "$(random 14)"
  touch .serveur-secrets
fi
chmod 600 .env

echo "• Construction et démarrage (10 à 20 minutes la première fois)…"
docker compose up -d --build

model=$(get_env LLM_MODEL)
echo "• Modèles d'IA : $model et nomic-embed-text"
docker compose exec -T ollama ollama pull "$model"
docker compose exec -T ollama ollama pull nomic-embed-text

echo "• Indexation des textes de loi (10 à 20 minutes, ne pas interrompre)…"
docker compose exec -T ai-service python /kb/scripts/ingest.py --all \
  || echo "Indexation incomplète : relancer « docker compose exec ai-service python /kb/scripts/ingest.py --all »"

cat <<MSG

FlowPulse tourne sur http://127.0.0.1:$(get_env APP_PORT) (non exposé sur Internet).
Étape suivante, avec sudo : le site nginx et le certificat HTTPS (docs/DEPLOIEMENT_VPS.md, étape 5).
  Administrateur : $(get_env ADMIN_EMAIL)  (mot de passe : grep ADMIN_PASSWORD .env)
Le fichier .env n'est lisible que par $(whoami).
MSG
