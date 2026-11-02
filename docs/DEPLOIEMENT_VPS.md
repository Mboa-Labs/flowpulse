# Déployer FlowPulse sur un serveur (VPS)

Ce guide installe FlowPulse sur un serveur Linux **déjà utilisé par d'autres applications**, sans les gêner :

- chaque conteneur a une **limite de mémoire et de processeur** (FlowPulse ne dépasse jamais 7 Go et 7 cœurs au total, Ollama compris) ;
- **rien n'est ouvert sur Internet** : l'interface écoute sur `127.0.0.1:8095`, la base de données n'est joignable que par les conteneurs ; seul le nginx du serveur sert le site, en HTTPS ;
- **secrets aléatoires** générés à l'installation, fichier `.env` lisible par son seul propriétaire, comptes de démonstration désactivés ;
- **sauvegarde quotidienne** de la base, journaux plafonnés, redémarrage automatique.

```
Internet ──HTTPS──► nginx du serveur ──► 127.0.0.1:8095 ──► interface ──/api──► backend ──► service IA ──► Ollama
                    (certificat Let's Encrypt)                (conteneurs Docker, réseau interne)   └──► PostgreSQL
```

Les commandes marquées **sudo** demandent le mot de passe de l'utilisateur du serveur.

## Ce qu'il faut

| Élément | Minimum | Vérifier avec |
| --- | --- | --- |
| Système | Ubuntu 22.04 ou 24.04, x86_64 | `cat /etc/os-release` |
| Mémoire libre | 8 Go (avec `llama3.2:3b`) | `free -h` |
| Processeurs | 4 | `nproc` |
| Disque libre | 30 Go | `df -h /` |
| Logiciels | Docker, Docker Compose, Git, nginx, certbot | `docker compose version`, `nginx -v`, `certbot --version` |
| Utilisateur | Membre du groupe `docker` | `id -nG` |
| Nom de domaine | Un enregistrement **A** vers l'adresse IP du serveur | `dig +short <domaine>` |

## Étape 1 : mémoire d'appoint (swap), une seule fois

Sans swap, un manque de mémoire fait arrêter brutalement un processus par Linux, parfois celui d'une autre application. Vérifier :

```bash
free -h
```

Si la ligne `Swap` affiche `0B`, créer 4 Go de swap (**sudo**) :

```bash
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Étape 2 : accès aux dépôts GitHub, une seule fois

Les dépôts de Mboa-Labs sont privés. Installer GitHub CLI (**sudo**) puis se connecter :

```bash
sudo apt install -y gh
```

```bash
gh auth login
```

Choisir *GitHub.com* → *HTTPS* → *Login with a web browser*, ouvrir <https://github.com/login/device> sur son ordinateur et saisir le code affiché. Puis :

```bash
gh auth setup-git
```

## Étape 3 : installer et démarrer FlowPulse

```bash
mkdir -p ~/flowpulse-workspace && cd ~/flowpulse-workspace
```

```bash
gh repo clone Mboa-Labs/flowpulse
```

```bash
bash flowpulse/scripts/serveur.sh
```

Le script :

1. clone les quatre autres dépôts à côté de `flowpulse` ;
2. crée `flowpulse/.env` avec des secrets aléatoires (base de données, jetons, administrateur) et active les réglages de production (`docker-compose.prod.yml`) ;
3. construit et démarre les conteneurs (10 à 20 minutes la première fois) ;
4. télécharge les modèles d'IA `llama3.2:3b` et `nomic-embed-text` (environ 2,3 Go) ;
5. indexe les textes de loi (10 à 20 minutes, **ne pas interrompre**).

Il est relançable : il ne régénère jamais un secret déjà créé.

Le mot de passe administrateur est dans le `.env` :

```bash
grep -E 'ADMIN_EMAIL|ADMIN_PASSWORD' ~/flowpulse-workspace/flowpulse/.env
```

## Étape 4 : vérifier

```bash
cd ~/flowpulse-workspace/flowpulse && bash scripts/verifier.sh
```

Les quatre lignes doivent être `OK`. L'interface ne doit écouter **que** sur la machine elle-même :

```bash
ss -tln | grep 8095
```

La réponse attendue commence par `127.0.0.1:8095`, jamais par `0.0.0.0`.

## Étape 5 : site nginx et HTTPS

Remplacer `flowpulse.exemple.com` par le vrai nom de domaine dans les commandes ci-dessous. L'enregistrement DNS doit déjà pointer vers le serveur (`dig +short flowpulse.exemple.com` doit afficher son adresse IP).

1. Installer le site (**sudo**) :

   ```bash
   sudo cp ~/flowpulse-workspace/flowpulse/deploy/nginx/flowpulse.conf /etc/nginx/sites-available/flowpulse
   ```

   ```bash
   sudo sed -i 's/DOMAINE/flowpulse.exemple.com/' /etc/nginx/sites-available/flowpulse
   ```

   ```bash
   sudo ln -s /etc/nginx/sites-available/flowpulse /etc/nginx/sites-enabled/flowpulse
   ```

2. Vérifier la configuration avant de recharger : **les autres sites ne doivent pas être affectés** (**sudo**) :

   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```

   Si `nginx -t` signale une erreur, ne pas recharger : supprimer le lien (`sudo rm /etc/nginx/sites-enabled/flowpulse`) et corriger.

3. Obtenir le certificat HTTPS. Certbot ajoute lui-même le HTTPS et la redirection depuis HTTP (**sudo**) :

   ```bash
   sudo certbot --nginx -d flowpulse.exemple.com --redirect
   ```

   Le renouvellement est automatique (tâche planifiée installée avec certbot). Vérifier : `sudo certbot renew --dry-run`.

4. Ouvrir `https://flowpulse.exemple.com` et se connecter en administrateur. **Changer le mot de passe administrateur** depuis l'écran Administration si celui du `.env` a été partagé.

## Étape 6 : sauvegardes quotidiennes

Tester une sauvegarde :

```bash
bash ~/flowpulse-workspace/flowpulse/scripts/sauvegarde.sh
```

Les fichiers vont dans `~/flowpulse-sauvegardes/` (14 derniers conservés). Planifier chaque nuit à 2 h 30 :

```bash
(crontab -l 2>/dev/null; echo "30 2 * * * bash $HOME/flowpulse-workspace/flowpulse/scripts/sauvegarde.sh >> $HOME/flowpulse-sauvegardes/journal.txt 2>&1") | crontab -
```

Restaurer une sauvegarde (efface les données actuelles de la base) :

```bash
cd ~/flowpulse-workspace/flowpulse && gunzip -c ~/flowpulse-sauvegardes/<fichier>.sql.gz | docker compose exec -T postgres psql -U flowpulse -d flowpulse
```

Pour une sécurité complète, copier régulièrement ce dossier hors du serveur.

## Étape 7 : déploiement automatique

Chaque dépôt a des tests qui tournent sur GitHub à chaque `git push` (GitHub Actions : tests du backend et du service IA, compilation de l'interface, vérification de la configuration Docker et de l'inventaire des textes). Toutes les 5 minutes, le serveur regarde s'il existe une nouvelle version **dont les tests ont réussi** ; si oui, il la récupère, reconstruit les services et vérifie que tout répond. Une version dont les tests échouent n'est jamais déployée.

Le serveur va lui-même chercher les versions (avec l'accès GitHub de l'étape 2) : aucune clé SSH du serveur n'est confiée à GitHub.

Activer (une seule fois, sans sudo) :

```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * bash $HOME/flowpulse-workspace/flowpulse/scripts/deploiement-auto.sh >> $HOME/flowpulse-deploiements.log 2>&1") | crontab -
```

Suivre les déploiements :

```bash
tail -f ~/flowpulse-deploiements.log
```

Désactiver temporairement (avant une démonstration, pour figer la version) : `crontab -e` et ajouter `#` devant la ligne `deploiement-auto.sh`.

Si les textes de loi changent dans `flowpulse-knowledge-base`, la base de connaissances est réindexée automatiquement après le déploiement.

## Au quotidien

Toutes les commandes se lancent dans `~/flowpulse-workspace/flowpulse`.

| Action | Commande |
| --- | --- |
| Mettre à jour tout de suite, sans attendre le déploiement automatique | `bash scripts/mettre-a-jour.sh` |
| Lancer une commande longue sans risquer la coupure SSH | `tmux new -s flowpulse`, lancer la commande, `Ctrl + B` puis `D` pour se détacher ; `tmux attach -t flowpulse` pour revenir |
| État des services | `docker compose ps` |
| Mémoire et processeur utilisés | `docker stats --no-stream` |
| Journaux d'un service | `docker compose logs -f --tail 100 backend` (ou `ai-service`, `frontend`, `ollama`) |
| Activer les comptes de démonstration pour une séance | `sed -i 's/^DEMO_USERS=.*/DEMO_USERS=true/' .env && docker compose up -d backend`, puis `grep DEMO_PASSWORD .env` |
| Les désactiver après la séance | Même commande avec `false` |
| Redémarrer un service | `docker compose restart ai-service` |
| Arrêter FlowPulse (les données sont gardées) | `docker compose down` |

## Sécurité : liste de contrôle

- [ ] `ss -tln | grep 8095` ne montre que `127.0.0.1`.
- [ ] Le port de la base n'apparaît pas dans `docker compose ps`.
- [ ] `ls -l .env` affiche `-rw-------` (lecture par le seul propriétaire).
- [ ] `DEMO_USERS=false` en dehors des séances de démonstration.
- [ ] Le site répond en `https://` et `http://` redirige vers `https://`.
- [ ] Le pare-feu du serveur n'autorise que SSH, HTTP et HTTPS (`sudo ufw status`). Ne pas le modifier sans vérifier les autres applications.
- [ ] Une sauvegarde de la nuit est présente dans `~/flowpulse-sauvegardes/`.

## Dépannage

| Symptôme | Cause probable | Solution |
| --- | --- | --- |
| `502 Bad Gateway` sur le site | FlowPulse arrêté ou en cours de démarrage | `docker compose ps`, puis `docker compose up -d` ; attendre une minute |
| `certbot` échoue | Le DNS ne pointe pas encore vers le serveur | `dig +short <domaine>` ; attendre la propagation (quelques minutes à quelques heures) |
| Un conteneur redémarre en boucle | Limite de mémoire atteinte | `docker compose logs <service>` ; `docker stats` ; augmenter la limite dans `docker-compose.prod.yml` si le serveur le permet |
| Le superviseur met plus de 2 minutes | Modèle trop lourd pour le processeur | `LLM_MODEL=qwen2.5:1.5b` dans `.env`, `docker compose exec ollama ollama pull qwen2.5:1.5b`, puis `docker compose up -d ai-service` |
| « Aucun texte applicable » partout | Textes de loi non indexés | `docker compose exec ai-service python /kb/scripts/ingest.py --all` |
| Les autres sites ralentissent | FlowPulse trop gourmand | `docker stats` ; baisser les limites de `ollama` dans `docker-compose.prod.yml` |
