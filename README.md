# FlowPulse

**Optimisation intelligente des transports urbains et prédiction du trafic par données mobiles**

Projet de l'équipe **Mboa Labs** pour le *AI for Good Lab Hackathon : United Arab Emirates* (ITU).

FlowPulse exploite les flux de mobilité issus des antennes mobiles pour anticiper la congestion et recommander des réaffectations de bus. Ses agents IA vérifient chaque recommandation au regard des textes réglementaires, citent leurs sources et signalent les manques réglementaires.

Ce dépôt est le point d'entrée du projet : conception, documentation et orchestration. Chaque composant a son propre dépôt.

## Dépôts

| Dépôt | Contenu |
| --- | --- |
| [flowpulse](https://github.com/Mboa-Labs/flowpulse) | Ce dépôt : conception, documentation, `docker-compose`, infrastructure |
| [flowpulse-frontend](https://github.com/Mboa-Labs/flowpulse-frontend) | Interface React |
| [flowpulse-backend](https://github.com/Mboa-Labs/flowpulse-backend) | Spring Boot : authentification, rôles, alertes, flotte, audit |
| [flowpulse-ai-service](https://github.com/Mboa-Labs/flowpulse-ai-service) | FastAPI : pipeline de données, modèles, agents, recherche dans la base de connaissances |
| [flowpulse-knowledge-base](https://github.com/Mboa-Labs/flowpulse-knowledge-base) | Base de connaissances réglementaire : textes, inventaire, registre des manques, ingestion |
| [ITUAIReadiness](https://github.com/Mboa-Labs/ITUAIReadiness) | Fork du code de référence ITU (AI Readiness, Y.3172) |

## Démarrer

Prérequis : Git, Docker Desktop (16 Go de RAM recommandés pour le modèle de langage local).

Les dépôts doivent être clonés côte à côte :

```bash
mkdir flowpulse-workspace && cd flowpulse-workspace
for r in flowpulse flowpulse-frontend flowpulse-backend flowpulse-ai-service flowpulse-knowledge-base; do
  git clone https://github.com/Mboa-Labs/$r.git
done

cd flowpulse
cp .env.example .env                       # puis adapter les mots de passe
docker compose up -d --build
docker compose exec ollama ollama pull qwen2.5:14b
docker compose exec ollama ollama pull nomic-embed-text
docker compose exec ai-service python /kb/scripts/ingest.py   # indexe la base de connaissances
```

| Service | Adresse |
| --- | --- |
| Application | <http://localhost:8081> (compte initial : `ADMIN_EMAIL` / `ADMIN_PASSWORD` du `.env`) |
| API backend (Swagger) | <http://localhost:8080/swagger-ui.html> |
| Service IA (Swagger) | <http://localhost:8000/docs> |

## Contenu de ce dépôt

| Dossier | Contenu |
| --- | --- |
| [`conception/architecture/`](conception/architecture/) | Architecture v2 (source HTML + image) |
| [`conception/diagrammes/`](conception/diagrammes/) | Diagrammes UML (sources PlantUML + PNG/SVG) |
| [`docs/`](docs/) | Fiches projet et description des cas d'utilisation |
| [`infra/`](infra/) | Initialisation de PostgreSQL / PostGIS |

## Équipe

- KAMDEM FOSSO Emile Cabrel
- DJAHA TCHESSEU Yvanna
- TIOMELA ZANGUE Jorel
- TSEMEGNE Martin Yvan

Mentor : Valery MONTHE
