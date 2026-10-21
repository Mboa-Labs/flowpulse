# Diagrammes de modélisation — FlowPulse

Sources PlantUML (`.puml`) et rendus PNG/SVG. Style commun dans `_style.iuml`.

| Fichier | Diagramme |
| --- | --- |
| 01_architecture | Architecture logique v2 (React, Spring Boot, service IA, Ollama, PostgreSQL) |
| 02_cas_utilisation | Cas d'utilisation révisés (4 acteurs humains + acteurs système) |
| 03_classes | Modèle de domaine (21 classes, 9 énumérations) |
| 04_sequence_alerte_recommandation | Détection → recommandation conforme → validation humaine |
| 05_sequence_superviseur | Question au superviseur conversationnel avec traces et sources |
| 06_sequence_authentification | Authentification JWT et redirection par rôle |
| 07_sequence_simulation | Simulation What-If (bac à sable Y.3172) |
| 08_activite_pipeline_y3172 | Pipeline de données et de décision par nœud Y.3172 |
| 09_etats_alerte_recommandation | Cycle de vie d'une alerte et d'une recommandation |
| 10_deploiement | Déploiement docker-compose |
| 11_agents | Système multi-agents : rôles, outils, garde-fous |

Régénérer les images :

```bash
java -jar plantuml.jar -charset UTF-8 -tpng *.puml
java -jar plantuml.jar -charset UTF-8 -tsvg *.puml
```
