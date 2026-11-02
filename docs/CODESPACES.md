# Faire tourner FlowPulse dans GitHub Codespaces

Un Codespace est une machine Linux dans le cloud de GitHub, ouverte dans le navigateur. FlowPulse y tourne en entier (interface, backend, service IA, PostgreSQL, Ollama) et un lien permet de tester l'application depuis n'importe quel ordinateur ou téléphone.

Avec le GitHub Student Developer Pack, l'usage est gratuit dans la limite du quota mensuel (environ 180 heures-cœur, soit environ 45 heures sur la machine 4 cœurs utilisée ici). La machine s'arrête toute seule quand personne ne s'en sert : ce n'est pas un serveur permanent.

## 1. Avant de commencer (une fois)

1. Avoir le **GitHub Student Developer Pack** actif sur son compte : <https://education.github.com/pack>.
2. Être membre de l'organisation **Mboa-Labs** avec accès aux cinq dépôts.
3. Régler le délai de mise en veille : <https://github.com/settings/codespaces> → *Default idle timeout* : **120 minutes** pendant les séances de test (30 par défaut).

## 2. Créer le Codespace (première fois : 15 à 25 minutes)

1. Ouvrir <https://github.com/Mboa-Labs/flowpulse>.
2. **Code** → onglet **Codespaces** → **…** → **New with options**.
3. Choisir la machine **4-core, 16 GB** (minimum demandé par le projet), puis **Create codespace**.
4. GitHub demande d'**autoriser l'accès aux autres dépôts** (frontend, backend, service IA, base de connaissances) : accepter. Sans cela, l'installation ne peut pas les cloner.
5. L'installation démarre seule dans le terminal (`scripts/codespace.sh`) :
   - clone des quatre autres dépôts ;
   - création du `.env` avec des mots de passe aléatoires ;
   - construction et démarrage des conteneurs ;
   - téléchargement des modèles `llama3.2:3b` et `nomic-embed-text` (environ 2,5 Go) ;
   - indexation de la base de connaissances.
6. À la fin, le terminal affiche **les identifiants** (administrateur et comptes de démonstration). Ils restent dans `flowpulse/.env`.

Si le terminal de création a été fermé : `cat /workspaces/.codespaces/.persistedshare/creation.log` pour revoir le journal, ou relancer `bash scripts/codespace.sh`.

## 3. Ouvrir l'application

- Onglet **Ports** (en bas) → ligne **8081 FlowPulse** → icône globe « Ouvrir dans le navigateur ».
- Le lien a la forme `https://<nom-du-codespace>-8081.app.github.dev`.

### Partager le lien avec l'équipe

Par défaut, le lien n'est accessible qu'au propriétaire du Codespace. Pour les coéquipiers ou le jury :

- Onglet **Ports** → clic droit sur 8081 → **Port Visibility** → **Public**.
- Ou en ligne de commande : `gh codespace ports visibility 8081:public -c $CODESPACE_NAME`

Un lien public est ouvert à quiconque le connaît : l'application demande un compte, et les mots de passe générés sont aléatoires. Repasser en **Private** après la séance.

## 4. Tester

Suivre le scénario de test de [HEBERGEMENT_MAC.md](HEBERGEMENT_MAC.md#scénario-de-test), avec les identifiants affichés à la fin de l'installation.

Vérification rapide dans le terminal du Codespace :

```bash
cd /workspaces/flowpulse
bash scripts/verifier.sh
```

## 5. Au quotidien

| Action | Commande (dans `/workspaces/flowpulse`) |
| --- | --- |
| Reprendre un Codespace arrêté | github.com/codespaces → ouvrir le Codespace ; l'application redémarre seule |
| Récupérer les dernières versions et redémarrer | `bash scripts/mettre-a-jour.sh` |
| Voir les journaux | `docker compose logs -f backend` (ou `ai-service`, `frontend`, `ollama`) |
| Revoir les identifiants | `grep -E 'ADMIN_|DEMO_PASSWORD' .env` |
| Réindexer la base de connaissances | `docker compose exec ai-service python /kb/scripts/ingest.py --all` |
| Changer de modèle | `LLM_MODEL=qwen2.5:3b` dans `.env`, `docker compose exec ollama ollama pull qwen2.5:3b`, puis `docker compose up -d` |
| Arrêter tout de suite (économise le quota) | github.com/codespaces → **…** → **Stop codespace** |

Les données (comptes, recommandations, simulations, modèles téléchargés) sont conservées tant que le Codespace existe, même arrêté. Le supprimer efface tout.

## 6. Quota et limites

- Suivre sa consommation : <https://github.com/settings/billing> → *Codespaces*. Une heure sur la machine 4 cœurs consomme 4 heures-cœur.
- Le stockage est aussi compté (environ 20 Go inclus pour les étudiants) : supprimer les Codespaces inutiles.
- Pas de carte graphique : le superviseur répond en 20 à 60 secondes avec `llama3.2:3b`. C'est suffisant pour les tests ; pour la démonstration au jury, prévoir le Mac ou une machine plus puissante.
- Un seul Codespace par personne suffit : celui qui l'a créé partage le lien public.

## 7. Dépannage

| Symptôme | Solution |
| --- | --- |
| `git clone` échoue pendant l'installation (403, « Repository not found ») | L'accès aux autres dépôts n'a pas été autorisé : supprimer le Codespace et le recréer en acceptant l'autorisation, ou vérifier l'appartenance à l'organisation |
| La machine 4 cœurs n'est pas proposée | Le quota du mois est épuisé ou le compte n'a pas le Student Pack |
| « Service IA indisponible » | `docker compose ps` : le conteneur `ollama` doit tourner ; sinon `docker compose up -d` |
| Le superviseur ne répond pas | Le modèle n'est pas téléchargé : `docker compose exec ollama ollama pull llama3.2:3b` |
| Le lien affiche une page de connexion GitHub | Le port est en *Private* : passer en *Public* (section 3) |
