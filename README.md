# FlowPulse

**Policy-grounded AI agents for urban mobility in Yaoundé, Cameroon**

Submission of team **Mboa Labs** to the ITU *AI for Good Lab Hackathon: United Arab Emirates* (public services domain).

FlowPulse turns aggregated mobile-network activity into an hourly tension index for each of the 7 communes of Yaoundé, forecasts saturation 1 and 2 hours ahead, and lets AI agents propose actions: reinforce a bus line, warn the police, inform passengers, test a road closure before it happens. A Policy agent checks every proposal against a knowledge base of Cameroonian laws, national strategies, ITU standards and international references, and cites the document and article. When no text applies, it records a regulatory gap instead of inventing a rule. No agent ever applies a decision: a human approves or rejects it, and every step is traced.

| | Link |
| --- | --- |
| Live prototype | <https://flowpulse2.duckdns.org> (demo accounts on request) |
| Technical report (5 pages, official template) | [PDF](docs/soumission/FlowPulse_Technical_Report.pdf) · [DOCX](docs/soumission/FlowPulse_Technical_Report.docx) |
| User guide (French, 15 pages, screenshots) | [PDF](docs/soumission/FlowPulse-Guide-utilisation.pdf) |
| Knowledge base | [flowpulse-knowledge-base](https://github.com/Mboa-Labs/flowpulse-knowledge-base) |
| Regulatory gap register | [manques_reglementaires.csv](https://github.com/Mboa-Labs/flowpulse-knowledge-base/blob/main/registres/manques_reglementaires.csv) |

## How FlowPulse answers the evaluation criteria

| Criterion | What we built | Where to look |
| --- | --- | --- |
| Knowledge base quality | 21 texts inventoried with official reference, authority, date and source URL; 10 indexed (601 passages of national and international texts, 135 of ITU-T Y.3172 and the AI Readiness Framework 2.0); split by article; built with the ITU reference pipeline | `flowpulse-knowledge-base/sources.csv`, `scripts/ingest.py` |
| Agent capability | 5 agents (Watcher, Optimizer, Policy, Simulator, Orchestrator); verdicts *compliant*, *compliant with reservations*, *non-compliant*, *not covered*, each with citations; error scenarios in section 5 of the report | `flowpulse-ai-service/app/agents/` |
| Policy, strategy and standards gaps | 7 domain-level gaps, each with the texts examined and a global policy example; new gaps logged by the agent at runtime | `registres/manques_reglementaires.csv`, *Regulatory gaps* screen |
| Auditability | Trace of every answer, alert and simulation (agent, tool, inputs, outputs, duration, cited passages); audit log of human decisions, exportable as CSV | *See the reasoning* button, *Audit log* screen, `flowpulse-backend/.../audit/` |
| Alignment with ITU standards | Components mapped to the Y.3172 nodes (SRC, C, PP, M, P, D, SINK, sandbox) and to the AI Readiness Framework 2.0 dimensions | Report section 4, [design document](docs/FlowPulse_Document_de_conception.md) |

## Repositories

| Repository | Content |
| --- | --- |
| [flowpulse](https://github.com/Mboa-Labs/flowpulse) | This repository: design, documentation, Docker Compose, infrastructure, submission documents |
| [flowpulse-frontend](https://github.com/Mboa-Labs/flowpulse-frontend) | React interface (Leaflet maps, one workspace per role) |
| [flowpulse-backend](https://github.com/Mboa-Labs/flowpulse-backend) | Spring Boot: authentication (JWT), roles, alerts, fleet decisions, audit log |
| [flowpulse-ai-service](https://github.com/Mboa-Labs/flowpulse-ai-service) | FastAPI: data pipeline, LightGBM forecasts, agents, knowledge base search, traces |
| [flowpulse-knowledge-base](https://github.com/Mboa-Labs/flowpulse-knowledge-base) | Regulatory knowledge base: texts, inventory, gap register, ingestion |

```text
React (browser) ──► Spring Boot (/api, JWT, roles, audit) ──► FastAPI AI service (/ai, internal network only)
                                    │                              │  agents · LightGBM · RAG
                                    ▼                              ▼
                               PostgreSQL                 ChromaDB + Ollama (local LLM, nomic-embed-text)
```

## Data and responsible use

- **Mobility data.** No Cameroonian operator data is available yet. The pipeline processes the real D4D-Senegal dataset (Orange/Sonatel, Dakar, 2013) and transposes the hourly profiles of 7 Dakar districts onto the 7 communes of Yaoundé; volumes are not transposed. Only aggregates by zone and hour are kept (no individual data). Source: Y.-A. de Montjoye et al., *D4D-Senegal: The Second Mobile Phone Data for Development Challenge*, 2014.
- **Places and boundaries.** OpenStreetMap (© OpenStreetMap contributors, ODbL) and geoBoundaries.
- **Bus fleet, lines and stops.** Demonstration data, clearly labelled in the interface.
- **Language model.** Runs locally through Ollama: no data is sent to an external AI service.

## Run it

Requirements: Git, Docker, [Ollama](https://ollama.com/download) (16 GB of RAM recommended).

```bash
mkdir flowpulse-workspace && cd flowpulse-workspace
git clone https://github.com/Mboa-Labs/flowpulse.git
bash flowpulse/scripts/installer.sh            # clones the other repositories, creates .env

ollama pull qwen2.5:7b && ollama pull nomic-embed-text
cd flowpulse
docker compose up -d --build
docker compose exec ai-service python /kb/scripts/ingest.py --all   # indexes the knowledge base
bash scripts/verifier.sh
```

Application: <http://localhost:8081>. Demo accounts: `gestionnaire@`, `operateur@`, `urbaniste@flowpulse.local` (password `DEMO_PASSWORD` from `.env`) and the administrator `ADMIN_EMAIL`.

Other guides (in French): hosting on a Mac and testing from another PC ([docs/HEBERGEMENT_MAC.md](docs/HEBERGEMENT_MAC.md)), shared VPS with resource limits, HTTPS and backups ([docs/DEPLOIEMENT_VPS.md](docs/DEPLOIEMENT_VPS.md)), GitHub Codespaces ([docs/CODESPACES.md](docs/CODESPACES.md)).

## Contents of this repository

| Folder | Content |
| --- | --- |
| [`docs/soumission/`](docs/soumission/) | Technical report and user guide |
| [`conception/architecture/`](conception/architecture/) | Architecture (HTML source and image) |
| [`conception/diagrammes/`](conception/diagrammes/) | UML diagrams (PlantUML sources, PNG and SVG) |
| [`docs/`](docs/) | Project sheets, use case description, design document, deployment guides |
| [`infra/`](infra/) | PostgreSQL initialisation |
| [`scripts/`](scripts/) | Installation, update and health checks |

## Team

- KAMDEM FOSSO Emile Cabrel (team leader)
- DJAHA TCHESSEU Yvanna
- TIOMELA ZANGUE Jorel
- TSEMEGNE Martin Yvan

## License

Code: [MIT](LICENSE). Documents reproduced in the knowledge base keep their own rights (see the knowledge base README).
