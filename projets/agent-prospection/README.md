# Agent de Prospection Automatisé — Kawanah Tourisme

Plateforme de prospection B2B pour le secteur de l'hospitalité : elle transforme une simple liste de noms d'établissements en campagnes d'emails personnalisés, argumentés à partir d'un audit réel de la présence web de chaque prospect.

---

## Le problème résolu

Vendre de la création de site web à des hôtels, campings, gîtes ou prestataires d'activités suppose un travail préalable long et répétitif : identifier les établissements d'une zone, retrouver leur site (quand il existe), remonter jusqu'à un décideur, constater ce qui cloche dans leur présence en ligne, puis rédiger un message qui parle de *leur* situation et non d'un argumentaire générique.

Fait à la main, ce cycle prend plusieurs dizaines de minutes par prospect, et l'essentiel de ce temps est de la collecte, pas de la vente. Résultat : soit on prospecte peu, soit on envoie des messages génériques qui ne convertissent pas.

Cet outil industrialise la collecte et l'analyse, et réserve l'humain aux décisions : valider un lead, relire un message, autoriser un envoi. Chaque message généré s'appuie sur des observations vérifiables (site absent ou lent, référencement faible, avis Google, ancienneté de la structure), ce qui rend l'approche commerciale concrète plutôt que déclarative.

---

## Fonctionnement

### Vue d'ensemble du flux

```
   Sources de leads                Traitement                    Sortie
 ─────────────────────      ────────────────────────      ────────────────────
  CSV / Excel
  Google Places        ┐                                    Message email
  DATAtourisme         │    ┌──────────────┐                personnalisé
  SIRENE / Pappers     ├──► │  Import &    │                     ▲
  BODACC               │    │ dédoublonnage│                     │
  data.gouv.fr         ┘    └──────┬───────┘                     │
                                   ▼                             │
                            ┌──────────────┐            ┌────────┴────────┐
                            │Enrichissement│            │   Séquenceur    │
                            │ site, contact│            │ file + quotas   │
                            │ email, tél.  │            │ + relances      │
                            └──────┬───────┘            └────────▲────────┘
                                   ▼                             │
                            ┌──────────────┐            ┌────────┴────────┐
                            │  Audit web   │            │  Génération IA  │
                            │ SEO, contenu ├───────────►│ argumentaire    │
                            │ avis Google  │            │ basé sur l'audit│
                            └──────┬───────┘            └────────▲────────┘
                                   ▼                             │
                            ┌──────────────┐                     │
                            │   Scoring    ├─────────────────────┘
                            │ chaud/tiède/ │
                            │    froid     │
                            └──────────────┘
```

### L'agent autonome

Le cœur du produit (`app/agent/`) est un agent bâti sur Claude (Anthropic) via le mécanisme de **Tool Use**. Il ne suit pas un script figé : on lui expose un catalogue d'outils et il décide lui-même de l'enchaînement à mener sur un lead donné.

| Outil exposé | Rôle |
|--------------|------|
| `search_leads` | Sélectionner des leads par segment, statut ou score |
| `get_lead_details` | Lire la fiche complète d'un lead |
| `verify_website` | Vérifier qu'un site trouvé appartient bien à l'établissement |
| `analyze_lead_website` | Auditer le site (existence, structure, référencement) |
| `analyze_google_reviews` | Exploiter la réputation Google du prospect |
| `generate_message` | Rédiger le message à partir de l'audit |
| `queue_email` | Placer l'envoi dans la file planifiée |
| `update_lead_status` | Faire avancer le lead dans le pipeline |
| `get_campaign_stats` | Mesurer les performances d'une campagne |
| `request_human_decision` | Rendre la main à l'opérateur |

Deux modes d'exécution :

- **Autonome** : l'agent enchaîne les actions de bout en bout.
- **Human-in-the-loop** : les actions sensibles passent par une validation dans le dashboard, via `request_human_decision`.

### Architecture

Le backend suit une **architecture en couches**, avec une séparation stricte entre transport HTTP, logique métier et persistance :

```
app/
├── api/         Routes FastAPI — validation d'entrée, auth, codes HTTP.
│                Aucune logique métier.
├── schemas/     Contrats Pydantic v2 (entrée/sortie de l'API).
├── services/    Logique métier, une classe par domaine et par source.
│                Testable sans serveur HTTP.
├── agent/       Boucle de raisonnement Claude et définition des outils.
│                Consomme les services, jamais les routes.
├── models/      Modèles SQLAlchemy 2.0 (Lead, Contact, Campaign, Message…).
├── database.py  Session asynchrone, initialisation du schéma.
├── config.py    Settings Pydantic — source unique de vérité pour l'environnement.
└── main.py      Assemblage : middlewares, CORS, rate limiting, scheduler.
```

Trois points structurants :

**Sources de données enfichables.** Chaque source de leads est un service isolé et interchangeable (`google_places_source_service`, `datatourisme_source_service`, `sirene_source_service`, `pappers_source_service`, `bodacc_service`, `gouv_data_service`). Ajouter une source revient à écrire un service exposant la même interface, sans toucher au reste du pipeline. Une source dont la clé API est absente reste simplement inactive.

**Dégradation contrôlée.** Chaque étape dispose d'un comportement de repli : sans `ANTHROPIC_API_KEY`, la génération bascule en mode démonstration ; sans clé d'enrichissement, le lead reste exploitable avec les données déjà connues. Le pipeline ne s'interrompt pas sur l'indisponibilité d'un service tiers.

**Scheduler d'envoi.** Une tâche de fond déclarée dans `main.py` traite la file des emails planifiés toutes les 5 minutes, dans la limite du quota journalier. Elle ne démarre que si `ENABLE_AUTO_QUEUE` **et** `ENABLE_EMAIL_DELIVERY` sont explicitement activés — désactivés par défaut.

### API

Routes principales, toutes protégées par JWT sauf `/api/auth` :

`/api/leads` · `/api/contacts` · `/api/campaigns` · `/api/messages` · `/api/enrichment` · `/api/scoring` · `/api/ai` · `/api/agent` · `/api/reviews` · `/api/sources` · `/api/gouv` · `/api/settings`

Documentation OpenAPI générée automatiquement sur `/docs`.

---

## Stack technique

### Backend

| Technologie | Rôle |
|-------------|------|
| Python 3.11+ | Langage |
| FastAPI + Uvicorn | API REST asynchrone, OpenAPI automatique |
| SQLAlchemy 2.0 (async) | ORM, accès base non bloquant |
| SQLite / PostgreSQL | Persistance (développement / production) |
| Pydantic v2 + pydantic-settings | Validation des données et de la configuration |
| Anthropic (Claude API) | Agent Tool Use, génération de messages, scoring |
| httpx · BeautifulSoup · lxml | Appels d'API et scraping |
| pandas · openpyxl | Import et normalisation CSV/Excel |
| Celery + Redis | Traitement asynchrone (dépendances et configuration en place, module worker à venir) |
| python-jose · passlib/bcrypt | Authentification JWT, hachage des mots de passe |
| slowapi | Rate limiting |
| loguru | Journalisation |
| pytest · ruff · black | Tests et qualité de code |

### Frontend

| Technologie | Rôle |
|-------------|------|
| React 19 + Vite 7 | Dashboard et outillage de build |
| React Router 7 | Navigation (Dashboard, Leads, Campagnes, Agent, Messages, Import, Enrichissement, Paramètres) |
| Tailwind CSS 3 | Styles |
| Recharts | Graphiques et statistiques de campagne |
| Framer Motion | Animations d'interface |
| axios | Client HTTP vers l'API |
| Vitest + Testing Library | Tests de composants |

### Sources de données

| Source | Apport |
|--------|--------|
| Google Places | Établissements, coordonnées, avis |
| DATAtourisme | Gîtes, chambres d'hôtes, activités (données publiques) |
| SIRENE | Identité légale, SIREN/SIRET |
| Pappers | Dirigeants, données légales |
| BODACC | Créations et évolutions de structures |
| data.gouv.fr | Jeux de données publics complémentaires |
| DataForSEO | Positionnement et trafic organique réels |
| Hunter.io · Dropcontact | Emails professionnels |

### Qualité

Husky et lint-staged exécutent `ruff`/`black` sur le code Python et `eslint`/`prettier` sur le frontend avant chaque commit.

---

## Prérequis

- **Python 3.11+**
- **Node.js 18+** (dashboard)
- **Redis** — optionnel, prévu pour le traitement asynchrone Celery
- **Clé API Anthropic** — sans elle, la génération de messages tourne en mode démonstration
- Clés API optionnelles selon les sources activées (Google Places, Pappers, DATAtourisme, DataForSEO, Hunter.io, Dropcontact)
- Un compte SMTP si l'envoi réel doit être activé

---

## Installation

### 1. Backend

```bash
python -m venv venv
source venv/bin/activate          # Linux / macOS
pip install -r requirements.txt
```

### 2. Configuration

```bash
cp .env.example .env
```

Deux valeurs sont **obligatoires** et doivent être générées :

```bash
# Clé secrète JWT
python -c "import secrets; print(secrets.token_hex(32))"

# Hash du mot de passe admin
python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('votre-mdp'))"
```

Reporter les résultats dans `SECRET_KEY` et `ADMIN_PASSWORD_HASH`, puis renseigner `ANTHROPIC_API_KEY`. Les autres clés sont optionnelles : une source sans clé reste inactive.

### 3. Frontend

```bash
cd frontend
npm install
```

### 4. Hooks de qualité (optionnel)

```bash
npm install        # à la racine du dépôt
npm run prepare    # installe les hooks Husky
```

---

## Lancement

### Mode développement (par défaut)

Aucun email n'est réellement envoyé : les garde-fous d'envoi sont à `false`. Deux terminaux.

**Terminal 1 — API**

```bash
source venv/bin/activate
uvicorn app.main:app --reload
```

- API : http://127.0.0.1:8000
- Documentation interactive : http://127.0.0.1:8000/docs
- Santé : http://127.0.0.1:8000/health

> Si `uvicorn: command not found`, lancer `venv/bin/uvicorn app.main:app --reload`.

**Terminal 2 — Dashboard**

```bash
cd frontend
npm run dev
```

Dashboard sur http://localhost:5173. Connexion avec `ADMIN_USERNAME` et le mot de passe correspondant au hash configuré.

### Mode envoi réel

À n'activer qu'après relecture des messages et vérification de la configuration SMTP :

```bash
# dans .env
ENABLE_EMAIL_DELIVERY=true    # autorise l'envoi effectif via SMTP
ENABLE_AUTO_QUEUE=true        # active le scheduler de la file (cycle de 5 minutes)
```

Le scheduler ne démarre que si les deux variables sont à `true`. Le quota s'applique dans tous les cas : 50 emails par jour au maximum, avec un délai minimal de 60 secondes entre deux envois.

### Build de production du dashboard

```bash
cd frontend
npm run build       # génère frontend/dist
npm run preview     # sert le build localement
```

---

## Développement

```bash
# Tests backend
pytest tests/ -v

# Qualité backend
ruff check .
black --check .

# Tests et qualité frontend
cd frontend
npm run test
npm run lint
```

---

## Structure du projet

```
.
├── app/
│   ├── main.py            Point d'entrée FastAPI, middlewares, scheduler
│   ├── config.py          Settings Pydantic (.env)
│   ├── database.py        Session SQLAlchemy asynchrone
│   ├── auth.py            Authentification JWT
│   ├── models/            Modèles de données
│   ├── schemas/           Schémas Pydantic
│   ├── api/               Routes REST
│   ├── agent/             Agent autonome (Tool Use Claude)
│   └── services/          Logique métier et sources de données
├── frontend/              Dashboard React + Vite
│   └── src/pages/         Dashboard, Leads, Campaigns, Agent, Messages…
├── tests/                 Tests backend (pytest)
├── data/                  Base SQLite locale et fichiers d'import
├── docs/                  Documentation détaillée
├── requirements.txt
└── .env.example
```

---

## Sécurité

**Jamais versionné.** Le fichier `.env` est ignoré par git et concentre l'intégralité des secrets : `ANTHROPIC_API_KEY`, `SECRET_KEY`, `ADMIN_PASSWORD_HASH`, identifiants SMTP, clés des sources tierces. La base SQLite (`data/*.db`), les logs et les fichiers d'import sont également ignorés : aucune donnée de prospect ne part dans le dépôt. Seul `.env.example`, sans valeur réelle, est suivi.

**Authentification.** JWT obligatoire sur toutes les routes hors `/api/auth`. Mot de passe admin stocké uniquement sous forme de hash bcrypt ; durée de validité du jeton réglée par `JWT_EXPIRE_MINUTES`.

**Garde-fous.** Quatre interrupteurs, tous à `false` par défaut, encadrent les actions irréversibles :

| Variable | Effet une fois activée |
|----------|------------------------|
| `ENABLE_EMAIL_DELIVERY` | Autorise l'envoi effectif d'emails |
| `ENABLE_AUTO_QUEUE` | Démarre le scheduler de la file d'envoi |
| `ENABLE_ADMIN_PURGE` | Autorise la purge de données |
| `ENABLE_RUNTIME_SETTINGS` | Autorise la modification des paramètres à chaud |

**Surface d'attaque.** Rate limiting (slowapi) côté API, CORS restreint via `ALLOWED_ORIGINS`, et filtrage des requêtes sortantes (`app/services/http_safety.py`) pour les appels de scraping.

**Conformité.** Traitement aligné sur le RGPD (opt-out, pas de données sensibles), respect des conditions d'utilisation des plateformes tierces et des quotas d'envoi.

---

## Documentation

- [Manuel utilisateur](docs/MANUEL_UTILISATEUR.md) — utilisation du dashboard
- [Documentation technique](docs/DOCUMENTATION_TECHNIQUE.md) — architecture, API, sécurité
- [Plan de développement et de test](docs/PLAN_DEVELOPPEMENT_TEST.md)
- [Guide de lancement rapide](LANCEMENT.md)
- API interactive : http://127.0.0.1:8000/docs (backend démarré)
