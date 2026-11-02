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

Prérequis : Git, Docker Desktop, [Ollama](https://ollama.com/download) installé sur la machine (16 Go de RAM recommandés).

```bash
mkdir flowpulse-workspace && cd flowpulse-workspace
git clone https://github.com/Mboa-Labs/flowpulse.git
bash flowpulse/scripts/installer.sh            # clone les autres dépôts, crée le .env

ollama pull qwen2.5:7b && ollama pull nomic-embed-text
cd flowpulse
docker compose up -d --build
docker compose exec ai-service python /kb/scripts/ingest.py --all   # indexe la base de connaissances
bash scripts/verifier.sh
```

Application : <http://localhost:8081>. Comptes de démonstration : `gestionnaire@`, `operateur@`, `urbaniste@flowpulse.local` (mot de passe `DEMO_PASSWORD` du `.env`), et l'administrateur `ADMIN_EMAIL`.

Guide complet pour héberger FlowPulse sur un MacBook et le tester depuis un autre PC, avec le scénario de test : [docs/HEBERGEMENT_MAC.md](docs/HEBERGEMENT_MAC.md).

Sur un serveur (VPS) partagé avec d'autres applications, avec limites de ressources, HTTPS et sauvegardes : [docs/DEPLOIEMENT_VPS.md](docs/DEPLOIEMENT_VPS.md).

Sans machine à disposition : FlowPulse tourne aussi dans **GitHub Codespaces** (Code → Codespaces → New with options, machine 4 cœurs / 16 Go), installation automatique : [docs/CODESPACES.md](docs/CODESPACES.md).

## Contenu de ce dépôt

| Dossier | Contenu |
| --- | --- |
| [`conception/architecture/`](conception/architecture/) | Architecture v2 (source HTML + image) |
| [`conception/diagrammes/`](conception/diagrammes/) | Diagrammes UML (sources PlantUML + PNG/SVG) |
| [`docs/`](docs/) | Fiches projet et description des cas d'utilisation |
| [`infra/`](infra/) | Initialisation de PostgreSQL |
| [`scripts/`](scripts/) | Installation, mise à jour et vérification de la stack |

## Équipe

- KAMDEM FOSSO Emile Cabrel
- DJAHA TCHESSEU Yvanna
- TIOMELA ZANGUE Jorel
- TSEMEGNE Martin Yvan

Mentor : Valery MONTHE
