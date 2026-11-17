# Agent de Prospection — Kawanah Tourisme

Application web de prospection B2B pour le secteur de l'hospitalité (hôtels, campings, gîtes, prestataires d'activités).

Elle collecte des établissements depuis des sources publiques, retrouve leurs coordonnées, audite leur site web, note leur potentiel, puis rédige et envoie des messages de prospection personnalisés — le tout piloté depuis un tableau de bord.

---

## Ce que c'est

Un logiciel complet qui tourne en local, composé de deux serveurs :

| Composant | Techno | Rôle |
|-----------|--------|------|
| **Backend** | Python 3.11 · FastAPI · SQLAlchemy · SQLite | API REST, base de données, logique métier, agent IA |
| **Frontend** | React 19 · Vite · Tailwind · Recharts | Dashboard web, 9 écrans |

Accès protégé par login (JWT). API documentée automatiquement sur `/docs`.

---

## Le parcours d'un prospect

```
1. SOURCER      →  Import CSV/Excel, ou collecte via Google Places,
                   DATAtourisme, SIRENE, BODACC, Pappers, data.gouv.fr

2. ENRICHIR     →  Site web, email, téléphone, réseaux sociaux,
                   dirigeants, avis Google

3. AUDITER      →  Analyse du site existant (ou constat d'absence de site)
                   + données SEO réelles via DataForSEO

4. SCORER       →  Priorisation automatique par potentiel (chaud/tiède/froid)

5. RÉDIGER      →  Message personnalisé généré par Claude (email ou
                   LinkedIn), basé sur l'audit réel du site du prospect

6. ENVOYER      →  Campagne email séquencée, avec file d'attente,
                   quotas et relances (l'envoi LinkedIn reste manuel)

7. SUIVRE       →  Statuts, statistiques temps réel, réponses
```

---

## Écrans du dashboard

| Page | Ce qu'on y fait |
|------|-----------------|
| **Dashboard** | Vue d'ensemble, statistiques temps réel |
| **Import** | Charger un CSV/Excel de structures |
| **Leads** | Consulter, filtrer, enrichir, exporter les prospects |
| **Enrichment** | Lancer l'enrichissement et voir les résultats |
| **Campaigns** | Créer et piloter les campagnes d'envoi |
| **Messages** | Relire et éditer les messages générés |
| **Agent** | Dialoguer avec l'agent Claude, qui pilote les leads et campagnes via ses outils |
| **Settings** | Paramètres, clés API, garde-fous |

---

## Prérequis

- Python 3.11+
- Node.js 18+
- Une clé API Anthropic (Claude)

---

## Installation

Depuis la racine du projet :

```bash
# 1. Environnement Python
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Dépendances frontend
cd frontend && npm install && cd ..

# 3. Dossier de données (non versionné, à créer au premier clone)
mkdir -p data

# 4. Configuration
cp .env.example .env
# puis éditer .env (voir section Configuration)
```

---

## Lancer l'application

Deux terminaux, à chaque démarrage.

**Terminal 1 — Backend (API)**
```bash
source venv/bin/activate
uvicorn app.main:app --reload
```
→ API : http://127.0.0.1:8000 · Docs : http://127.0.0.1:8000/docs

**Terminal 2 — Frontend (dashboard)**
```bash
cd frontend
npm run dev
```
→ Dashboard : **http://localhost:5173**

> `uvicorn: command not found` ? Lancer `venv/bin/uvicorn app.main:app --reload`.

> **venv cassé après un déplacement du dossier** : `rm -rf venv` puis refaire l'étape 1 de l'installation.

---

## Configuration

### Obligatoire

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Clé API Claude — sans elle, la génération de messages tourne en mode démo |
| `SECRET_KEY` | Clé de signature JWT — `python -c "import secrets; print(secrets.token_hex(32))"` |
| `ADMIN_PASSWORD_HASH` | Hash bcrypt du mot de passe admin (voir ci-dessous) |

Générer le hash du mot de passe :
```bash
python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('votre-mdp'))"
```

### Sources de leads (optionnelles, activent des fonctions)

| Variable | Source | Coût |
|----------|--------|------|
| `GOOGLE_PLACES_API_KEY` | Établissements + avis Google | ~0,017 $/requête |
| `DATATOURISME_API_KEY` | Gîtes, chambres d'hôtes, activités | Gratuit |
| `PAPPERS_API_KEY` | Dirigeants, SIREN, nouvelles structures | 15 j gratuits |
| `DATAFORSEO_LOGIN` / `DATAFORSEO_PASSWORD` | Audit SEO réel (mots-clés, trafic) | Payant |
| `HUNTER_API_KEY` / `DROPCONTACT_API_KEY` | Recherche d'emails | Payant |

SIRENE, BODACC et data.gouv.fr fonctionnent sans clé.

### Envoi d'emails

| Variable | Description |
|----------|-------------|
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` | Serveur d'envoi |
| `EMAIL_FROM` | Adresse expéditrice |

### Garde-fous

Ces interrupteurs sont à `false` par défaut. **En développement, les laisser à `false`** : aucun email ne part réellement.

| Variable | Effet si `true` |
|----------|-----------------|
| `ENABLE_EMAIL_DELIVERY` | Envoie réellement les emails |
| `ENABLE_AUTO_QUEUE` | Traite la file d'envoi automatiquement |
| `ENABLE_RUNTIME_SETTINGS` | Autorise la modification des paramètres à chaud |
| `ENABLE_ADMIN_PURGE` | Autorise la purge complète de la base |

### Production

| Variable | Description |
|----------|-------------|
| `ALLOWED_ORIGINS` | Origines CORS autorisées (séparées par des virgules). Vide = origines de développement `localhost` |
| `DATABASE_URL` | SQLite par défaut ; passer à PostgreSQL en production |

---

## Tests & qualité

```bash
# Backend
source venv/bin/activate
pytest tests/ -v

# Frontend
cd frontend
npm run test:run
npm run lint

# Formatage Python
black .
ruff check .
```

---

## Structure du projet

```
Agent/
├── app/                      # Backend FastAPI
│   ├── main.py               # Point d'entrée, routes, CORS, sécurité
│   ├── config.py             # Variables d'environnement
│   ├── database.py           # Connexion base de données
│   ├── auth.py               # Authentification JWT
│   ├── models/               # Tables : lead, contact, campaign, message…
│   ├── schemas/              # Validation des données (Pydantic)
│   ├── api/                  # Routes REST (13 groupes)
│   ├── services/             # Métier : sources, enrichissement, scoring,
│   │                         #   audit web, IA, email, séquences
│   └── agent/                # Agent autonome et ses outils
├── frontend/                 # Dashboard React + Vite
│   └── src/pages/            # 9 écrans
├── tests/                    # Tests backend (pytest)
├── data/                     # Base SQLite + fichiers d'import
├── docs/                     # Documentation détaillée
├── requirements.txt
└── .env                      # Configuration locale (jamais commité)
```

---

## Documentation

- [Manuel Utilisateur](docs/MANUEL_UTILISATEUR.md) — utiliser le dashboard au quotidien
- [Documentation Technique](docs/DOCUMENTATION_TECHNIQUE.md) — architecture, API, sécurité
- [Plan de développement](docs/PLAN_DEVELOPPEMENT_TEST.md) — état d'avancement
- API interactive : http://localhost:8000/docs (backend démarré)

---

## Cadre légal & sécurité

- **RGPD** : opt-out simple, pas de données sensibles, base légale pour la prospection B2B.
- **Emails** : warm-up progressif, respect des quotas des fournisseurs.
- **LinkedIn** : les messages sont générés, mais l'envoi automatique n'est pas implémenté (copier-coller manuel). Respecter les conditions d'utilisation et la volumétrie si cela évolue.
- **Secrets** : `.env` n'est jamais commité. Ne jamais partager les clés API.
- **Accès** : le dashboard est protégé par authentification ; l'API l'est par JWT.

---

## État actuel

Application **locale** : elle tourne sur la machine de développement.

Pour la mettre en ligne, il faudra : construire le frontend (`npm run build`), héberger l'API, remplacer SQLite par PostgreSQL et renseigner `ALLOWED_ORIGINS`.
