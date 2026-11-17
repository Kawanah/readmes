# 🤖 LinkedIn Auto-poster — Kawanah

Publie automatiquement des posts LinkedIn générés par Claude, selon un planning hebdomadaire.

---

## Architecture

```
linkedin-automation/
├── main.py                 → Orchestrateur (lance la publication)
├── content_generator.py   → Génère les posts avec Claude API
├── linkedin_client.py     → Client LinkedIn API (OAuth2 + publication)
├── content_themes.json    → Tes thèmes, ton style, ton planning
├── setup_oauth.py         → Script de connexion LinkedIn (à faire 1 fois)
├── requirements.txt       → Dépendances Python
├── .env                   → Tes clés API (à créer depuis .env.example)
└── posts_log.json         → Historique des posts publiés (créé automatiquement)
```

---

## 1. Créer ton app LinkedIn Developer

1. Va sur [LinkedIn Developer Portal](https://developer.linkedin.com/apps)
2. Clique **Create App**
3. Remplis les infos :
   - **App name** : Kawanah Auto-poster
   - **Company** : Kawanah (ou ton profil LinkedIn)
   - **App logo** : optionnel
4. Dans l'onglet **Auth**, note le **Client ID** et **Client Secret**
5. Dans **OAuth 2.0 Settings**, ajoute l'URL de redirect :
   ```
   http://localhost:8765/callback
   ```
6. Dans l'onglet **Products**, demande l'accès à **Share on LinkedIn**
   (approbation quasi-instantanée pour les posts texte)

---

## 2. Obtenir une clé Anthropic API

1. Va sur [console.anthropic.com](https://console.anthropic.com)
2. Crée une clé API dans **API Keys**

---

## 3. Configurer le projet

```bash
# Copier le fichier de config
cp .env.example .env

# Remplir les valeurs dans .env :
# LINKEDIN_CLIENT_ID=...
# LINKEDIN_CLIENT_SECRET=...
# ANTHROPIC_API_KEY=...
```

---

## 4. Installer les dépendances

```bash
cd linkedin-automation
pip install -r requirements.txt
```

---

## 5. Autoriser l'app LinkedIn (une seule fois)

```bash
python setup_oauth.py
```

Ce script va :
1. Ouvrir ton navigateur vers LinkedIn
2. Te demander d'autoriser l'app
3. Récupérer et sauvegarder le token automatiquement

Le token est valide **60 jours**. Relance ce script quand il expire.

---

## 6. Tester

```bash
# Voir un post généré sans publier
python main.py --preview

# Publier immédiatement (ignore le planning)
python main.py --now

# Publier avec un thème précis
python main.py --now --theme tips_ia

# Voir l'historique des publications
python main.py --log
```

---

## 7. Automatiser avec cron (macOS)

### Option A — Cron simple

Ouvre le crontab :
```bash
crontab -e
```

Ajoute cette ligne (remplace le chemin) :
```
0 9 * * 1,4 cd /chemin/vers/linkedin-automation && /usr/bin/python3 main.py >> logs/cron.log 2>&1
```

Cela lancera le script **tous les lundi, mercredi et vendredi à 9h**.
Le script vérifie lui-même si c'est un jour de publication — pas de doublon possible.

### Option B — Mode daemon (pour Mac Mini toujours allumé)

```bash
python main.py --daemon
```

Le daemon tourne en continu et publie à l'heure configurée dans `.env` (`POSTING_TIME`).

---

## Personnaliser le contenu

Modifie **`content_themes.json`** pour :
- Changer les hooks et formats par thème
- Modifier le planning hebdomadaire (`planning_semaine`)
- Ajuster les règles de rédaction (`regles_redaction`)
- Ajouter de nouveaux thèmes

### Thèmes disponibles

| ID | Thème | Jour par défaut |
|----|-------|-----------------|
| `show_work` | Show your work | Lundi |
| `tips_ia` | Tips & astuces IA | Jeudi |
| `hot_take` | Opinion / Hot take | Rotation |
| `cas_client` | Cas client / Résultats | Rotation |
| `behind_scenes` | Coulisses Kawanah | Rotation |
| `sectoriel_hotellerie` | IA & Hôtellerie | Rotation |

---

## Commandes utiles

```bash
python main.py --preview               # Voir le post sans publier
python main.py --now                   # Publier maintenant
python main.py --now --theme hot_take  # Publier avec un thème précis
python main.py --daemon                # Mode continu
python main.py --log                   # Historique des posts
python content_generator.py            # Tester la génération seule
```

---

## Renouveler le token LinkedIn

Le token expire après 60 jours. Quand c'est le cas :

```bash
python setup_oauth.py
```

Le script te prévient 7 jours avant l'expiration dans les logs.

---

*Kawanah — kawanah.com*
