-- Schémas FlowPulse (créés au premier démarrage du conteneur)
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS app;       -- Spring Boot : utilisateurs, alertes, flotte, audit
CREATE SCHEMA IF NOT EXISTS mobility;  -- Service IA : flux, indicateurs, prédictions, traces d'agents
