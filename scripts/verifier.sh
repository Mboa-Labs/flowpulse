#!/usr/bin/env bash
# Vérifie que chaque brique répond : Ollama, service IA, backend, interface.
cd "$(dirname "$0")/.."
ok() { printf '  \033[32mOK\033[0m  %s\n' "$1"; }
ko() { printf '  \033[31mKO\033[0m  %s\n' "$1"; }
curl -sf http://localhost:11434/api/tags >/dev/null && ok "Ollama (modèles : $(curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | tr '\n' ' '))" || ko "Ollama ne répond pas sur le port 11434"
docker compose exec -T ai-service python -c "import httpx,sys; h=httpx.get('http://localhost:8000/health',timeout=10).json(); print(h); sys.exit(0 if h['ollama']['ok'] else 1)" >/dev/null 2>&1 && ok "Service IA (et accès à Ollama)" || ko "Service IA, ou le service IA n'atteint pas Ollama"
port=$(grep -E '^APP_PORT=' .env 2>/dev/null | cut -d= -f2); port=${port:-8081}
# Sans jeton, le backend répond 401 : c'est la preuve qu'il tourne derrière le proxy de l'interface
code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/api/auth/me")
[ "$code" = "401" ] && ok "Backend" || ko "Backend (code $code)"
curl -sf "http://localhost:$port/" >/dev/null && ok "Interface sur http://$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}'):$port" || ko "Interface sur le port $port"
