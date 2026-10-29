-- Schémas FlowPulse (créés au premier démarrage du conteneur)
-- PostGIS sera ajouté avec le pipeline géographique (image multi-architecture à choisir pour les Mac Apple).

CREATE SCHEMA IF NOT EXISTS app;       -- Spring Boot : utilisateurs, alertes, flotte, audit
CREATE SCHEMA IF NOT EXISTS mobility;  -- Service IA : flux, indicateurs, prédictions, traces d'agents
