#!/usr/bin/env bash
# Crée un compte administrateur personnel et désactive le compte administrateur de départ.
#   bash scripts/nouvel-admin.sh prenom@exemple.com "Prénom Nom"
# Le mot de passe est demandé au clavier (il n'apparaît ni à l'écran ni dans l'historique du terminal).
# Le compte de départ est désactivé, pas supprimé : ses actions restent dans le journal d'audit.
set -euo pipefail
cd "$(dirname "$0")/.."
email="${1:?Usage : bash scripts/nouvel-admin.sh email \"Prénom Nom\"}"
nom="${2:-Administrateur}"
get_env() { grep "^$1=" .env | cut -d= -f2- || true; }
api="http://127.0.0.1:$(get_env APP_PORT)/api"

read -r -s -p "Mot de passe du nouveau compte (8 caractères au moins) : " mdp; echo
read -r -s -p "Confirmer : " mdp2; echo
[ "$mdp" = "$mdp2" ] || { echo "Les deux saisies diffèrent."; exit 1; }
[ ${#mdp} -ge 8 ] || { echo "8 caractères au moins."; exit 1; }

export EMAIL="$email" NOM="$nom" MDP="$mdp" API="$api" \
       ANCIEN_EMAIL="$(get_env ADMIN_EMAIL)" ANCIEN_MDP="$(get_env ADMIN_PASSWORD)"
python3 - <<'PY'
import json, os, urllib.error, urllib.request

api = os.environ["API"]

def appel(methode, chemin, corps=None, jeton=None):
    req = urllib.request.Request(api + chemin, method=methode, data=json.dumps(corps).encode() if corps else None,
                                 headers={"Content-Type": "application/json", **({"Authorization": f"Bearer {jeton}"} if jeton else {})})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"Erreur {e.code} sur {chemin} : {e.read().decode()[:200]}")

jeton = appel("POST", "/auth/login", {"email": os.environ["ANCIEN_EMAIL"], "password": os.environ["ANCIEN_MDP"]})["accessToken"]
comptes = appel("GET", "/admin/users", jeton=jeton)
if any(c["email"] == os.environ["EMAIL"] for c in comptes):
    raise SystemExit("Un compte existe déjà avec cet email : changer son rôle depuis l'écran Administration.")
nouveau = appel("POST", "/admin/users", {"nom": os.environ["NOM"], "email": os.environ["EMAIL"],
                                          "password": os.environ["MDP"], "role": "ADMIN"}, jeton)
# Le nouveau compte doit fonctionner avant de désactiver l'ancien ; c'est lui qui le désactive (journal d'audit)
jeton_nouveau = appel("POST", "/auth/login", {"email": os.environ["EMAIL"], "password": os.environ["MDP"]})["accessToken"]
ancien = next(c for c in comptes if c["email"] == os.environ["ANCIEN_EMAIL"])
appel("PATCH", f"/admin/users/{ancien['id']}", {"actif": False}, jeton_nouveau)
print(f"Compte administrateur créé : {nouveau['email']}. Ancien compte {ancien['email']} désactivé.")
PY

# Le .env garde la trace du compte administrateur courant (utile aux scripts, jamais affiché)
sed -i "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=$email|" .env
python3 - "$mdp" <<'PY'
import re, sys
chemin = ".env"
texte = open(chemin, encoding="utf-8").read()
texte = re.sub(r"^ADMIN_PASSWORD=.*$", lambda _: "ADMIN_PASSWORD=" + sys.argv[1], texte, flags=re.M)
open(chemin, "w", encoding="utf-8").write(texte)
PY
echo "Fichier .env mis à jour."
