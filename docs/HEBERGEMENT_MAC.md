# Héberger FlowPulse sur un MacBook et le tester depuis un autre PC

Le MacBook fait office de serveur : il fait tourner FlowPulse (Docker) et le modèle de langage (Ollama). Depuis votre PC, sur le même réseau Wi-Fi, vous pilotez le Mac en SSH et vous testez l'application dans votre navigateur.

```
 Votre PC ── SSH (commandes) ──────────────►  MacBook
          └─ navigateur http://IP-du-Mac:8081 ─►  ├─ Ollama (natif, utilise la puce graphique Apple)
                                                 └─ Docker : interface · backend · service IA · PostgreSQL
```

Ollama est installé directement sur le Mac, pas dans Docker : dans Docker, il n'aurait pas accès à la puce graphique et serait 3 à 5 fois plus lent.

## 1. Ce qu'il faut sur le MacBook

| Élément | Minimum | Recommandé |
| --- | --- | --- |
| Puce | Apple M1 | M2 ou plus récent |
| Mémoire | 8 Go (modèle `llama3.2:3b`) | **16 Go** (modèle `qwen2.5:7b`) |
| Espace disque libre | 20 Go | 30 Go |
| Système | macOS 13 | macOS 14 ou plus récent |

Temps de réponse attendu du superviseur sur un Mac M1/M2 de 16 Go avec `qwen2.5:7b` : environ 5 à 20 secondes.

## 2. Préparation du Mac (une seule fois, devant le Mac)

1. **Installer les outils**
   - Docker Desktop pour puce Apple : <https://www.docker.com/products/docker-desktop/>. Le lancer une fois et accepter les autorisations.
   - Ollama pour macOS : <https://ollama.com/download>. Le lancer : une icône de lama apparaît dans la barre des menus.
   - Git : dans le Terminal, `xcode-select --install`.
   - GitHub CLI (les dépôts sont privés) : `brew install gh` si Homebrew est installé, sinon <https://cli.github.com/>.
2. **Régler la mémoire de Docker** : Docker Desktop → Réglages → Ressources → Mémoire : **4 Go** sur un Mac de 8 Go, **6 Go** sur un Mac de 16 Go. Le reste sert au modèle de langage.
3. **Activer l'accès à distance (SSH)** : Réglages Système → Général → Partage → **Session à distance** : activer, et autoriser l'utilisateur du Mac.
4. **Noter l'adresse IP du Mac** : dans le Terminal, `ipconfig getifaddr en0` (exemple : `192.168.1.42`). Noter aussi le nom d'utilisateur : `whoami`.
5. **Empêcher la mise en veille pendant les tests** : Réglages Système → Écran verrouillé → « Ne jamais » pendant la session, ou lancer `caffeinate -d` dans un Terminal laissé ouvert.
6. Si le pare-feu macOS est actif (Réglages → Réseau → Coupe-feu), autoriser Docker à recevoir des connexions entrantes.

## 3. Installation, depuis votre PC

Votre PC et le Mac doivent être sur le même réseau.

1. **Se connecter au Mac** depuis PowerShell ou le terminal de VS Code (remplacer par le nom et l'IP notés) :
   ```bash
   ssh prenom@192.168.1.42
   ```
   Astuce : l'extension VS Code « Remote - SSH » permet d'ouvrir les dossiers du Mac comme s'ils étaient sur votre PC.
2. **Se connecter à GitHub sur le Mac** (le coéquipier doit être membre de l'organisation Mboa-Labs) :
   ```bash
   gh auth login        # GitHub.com → HTTPS → Login with a web browser
   ```
   Un code s'affiche : ouvrez <https://github.com/login/device> sur votre PC, connectez-vous avec le compte du coéquipier et saisissez le code.
3. **Cloner les dépôts et préparer la configuration** :
   ```bash
   mkdir -p ~/flowpulse-workspace && cd ~/flowpulse-workspace
   gh repo clone Mboa-Labs/flowpulse
   bash flowpulse/scripts/installer.sh
   ```
   Le script clone les quatre autres dépôts à côté et crée `flowpulse/.env` avec une clé de sécurité aléatoire. Les comptes de démonstration sont activés.
4. **Télécharger les modèles** (environ 5 Go, 10 à 30 minutes selon la connexion) :
   ```bash
   ollama pull qwen2.5:7b          # sur un Mac de 8 Go : ollama pull llama3.2:3b
   ollama pull nomic-embed-text
   ```
   Sur un Mac de 8 Go, mettre aussi `LLM_MODEL=llama3.2:3b` dans `flowpulse/.env`.
5. **Démarrer FlowPulse** (premier lancement : 10 à 20 minutes, le temps de construire les images) :
   ```bash
   cd ~/flowpulse-workspace/flowpulse
   docker compose up -d --build
   docker compose ps                # les 4 services doivent être « running »
   ```
6. **Indexer la base de connaissances** (les textes de loi, environ 5 à 15 minutes) :
   ```bash
   docker compose exec ai-service python /kb/scripts/ingest.py --all
   ```
   `--all` indexe aussi les documents pas encore vérifiés par l'équipe : c'est voulu pour les tests. La loi n° 2024/017 est un PDF scanné : elle sera ignorée tant qu'elle n'est pas passée en reconnaissance de caractères.
7. **Vérifier que tout répond** :
   ```bash
   bash scripts/verifier.sh
   ```
   Le script affiche OK ou KO pour Ollama, le service IA, le backend et l'interface, et l'adresse à ouvrir.

## 4. Tester depuis votre PC

Ouvrez **http://192.168.1.42:8081** (l'IP du Mac) dans votre navigateur. Vous pouvez aussi l'ouvrir sur votre téléphone, connecté au même Wi-Fi, pour tester l'affichage mobile.

| Compte | Mot de passe | Écran d'arrivée |
| --- | --- | --- |
| `admin@flowpulse.local` | valeur `ADMIN_PASSWORD` du `.env` | Administration |
| `gestionnaire@flowpulse.local` | `demo1234` | Tableau de bord |
| `operateur@flowpulse.local` | `demo1234` | Flotte |
| `urbaniste@flowpulse.local` | `demo1234` | Simulation (écran à venir) |

### Scénario de test

Cocher chaque point ; noter tout écart avec l'heure et le compte utilisé.

- [ ] **Connexion** : chaque compte arrive sur son écran et ne voit que son menu. Un mauvais mot de passe affiche un message clair.
- [ ] **Tableau de bord** (gestionnaire) : 4 indicateurs et 3 zones de Dakar, triées de la plus à la moins congestionnée.
- [ ] **Surveillance** (gestionnaire) : « Lancer une surveillance » → 2 alertes saturées (Grand Dakar, Dakar Plateau). « Voir le raisonnement » liste les étapes.
- [ ] **Recommandations** (opérateur, écran Flotte) : 2 recommandations « En attente de décision », avec leur verdict de conformité et les textes cités (après indexation de la base de connaissances).
- [ ] **Rejet sans motif** : « Rejeter » sans motif → message demandant le motif. Avec un motif → statut « Rejetée ».
- [ ] **Application** : « Appliquer la recommandation » → statut « Appliquée ». Impossible de l'appliquer une deuxième fois.
- [ ] **Superviseur** (gestionnaire ou opérateur) : « Vérifie le trafic à Grand Dakar et propose des bus si besoin » → réponse chiffrée, outils utilisés, une nouvelle recommandation à valider dans Flotte, raisonnement consultable.
- [ ] **Question réglementaire** : « Qui est compétent pour organiser le transport urbain ? » → réponse qui cite un texte (après indexation).
- [ ] **Manques réglementaires** : les décisions sans texte applicable apparaissent dans la liste.
- [ ] **Droits** : l'urbaniste ne voit pas le bouton de surveillance ; le gestionnaire ne peut pas appliquer une recommandation.
- [ ] **Administration** (admin) : créer un compte, s'y connecter, le désactiver.
- [ ] **Mobile** : sur téléphone, barre d'onglets en bas, aucune zone qui déborde.
- [ ] **Thème** : le bouton de thème passe en clair, sombre, puis automatique.

Les données de trafic et de flotte sont des données de démonstration : elles seront remplacées par le dataset.

## 5. Au quotidien

| Action | Commande (dans `~/flowpulse-workspace/flowpulse`) |
| --- | --- |
| Récupérer les dernières versions et redémarrer | `bash scripts/mettre-a-jour.sh` |
| Voir les journaux d'un service | `docker compose logs -f backend` (ou `ai-service`, `frontend`) |
| Arrêter (les données sont conservées) | `docker compose down` |
| Repartir de zéro (efface comptes et base) | `docker compose down -v` |
| Superviseur en mode console | `docker compose exec ai-service python -m app.cli` |

## 6. Dépannage

| Symptôme | Cause probable | Solution |
| --- | --- | --- |
| La page ne s'ouvre pas depuis le PC | IP changée, Mac en veille, pare-feu | Revérifier `ipconfig getifaddr en0` ; réveiller le Mac ; autoriser Docker dans le coupe-feu |
| « Le service IA est indisponible » | Ollama arrêté | Relancer l'application Ollama sur le Mac ; `bash scripts/verifier.sh` |
| Le superviseur met plus d'une minute | Modèle trop lourd pour la mémoire du Mac | Passer à `LLM_MODEL=llama3.2:3b` dans `.env`, puis `docker compose up -d` |
| Verdict toujours « Aucun texte applicable » | Base de connaissances non indexée | Relancer l'étape 6 de l'installation |
| `docker compose up` échoue sur la mémoire | Mémoire Docker trop basse | Docker Desktop → Ressources → au moins 4 Go |
| Le Mac et le PC ne sont pas sur le même réseau | Wi-Fi différents | Installer Tailscale (gratuit) sur les deux machines et utiliser l'adresse Tailscale du Mac |
