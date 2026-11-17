# Agent Éditorial

Agent autonome qui gère la présence réseaux sociaux de solopreneurs, depuis la collecte du besoin jusqu'à la publication validée.

---

## Le problème

Un solopreneur sait qu'il devrait publier régulièrement sur LinkedIn, mais n'en a ni le temps ni la constance : trouver des idées, rédiger, respecter une ligne éditoriale, tenir un rythme, valider avant de poster. La plupart des outils existants génèrent du contenu générique et exigent quand même un pilotage manuel permanent.

L'Agent Éditorial automatise la chaîne complète tout en gardant l'humain aux commandes sur ce qui compte — la validation avant publication :

1. **Onboarding** — 8 questions structurées définissent le profil et la stratégie éditoriale du client (piliers de contenu, fréquence, jours de publication).
2. **Génération** — l'agent rédige des brouillons alignés sur la stratégie, au fil de l'eau, sans jamais dépasser la cadence prévue.
3. **Validation** — chaque brouillon est proposé au client par WhatsApp (Valider / Refuser / Retoucher). Rien n'est publié sans accord explicite.
4. **Publication** — les posts validés partent sur LinkedIn au bon créneau, avec traçabilité et idempotence.

Google Sheets sert de source de vérité et de tableau de bord lisible par le client.

---

## Fonctionnement de l'agent

```text
Onboarding (8 points)  ──►  Stratégie éditoriale
        │                          │
        ▼                          ▼
   Génération IA  ──►  Brouillon (Google Sheets)
        │                          │
        ▼                          ▼
   Validation WhatsApp  ──►  Statut « Validé »
        │                          │
        ▼                          ▼
   Publication LinkedIn  ──►  Writeback Sheets (URN + date)
```

L'agent tourne selon deux cycles automatisés (crons) :

- **Cycle sortant (quotidien)** — complète les brouillons manquants jusqu'à la fréquence cible de la stratégie, puis envoie les demandes de validation. Ne génère que le manque, idempotent.
- **Cycle de publication (toutes les 30 min)** — repère les posts validés dont l'horaire est atteint et les publie. Un post déjà publié n'est jamais republié.

L'ensemble est **multi-client** : chaque client a son propre Google Sheet et sa propre configuration. Une erreur sur un client (Sheet inaccessible, token invalide) n'interrompt pas le traitement des autres.

### Architecture

Le socle suit une architecture **ports & adapters** (hexagonale), qui isole la logique métier des services externes :

```text
src/
├── domain/          Règles métier pures (profil, stratégie, planning, temps)
├── application/     Cas d'usage (génération, validation, publication)
├── ports/           Interfaces (repositories, notifiers, générateurs)
├── adapters/        Implémentations concrètes (Sheets, LinkedIn, Anthropic, WhatsApp)
├── orchestration/   Runners multi-client (isolation d'erreur)
├── tenancy/         Registre de clients, contexte par client
├── config/          Chargement et validation de la configuration
└── server/          Serveur webhook (handshake + réception WhatsApp)
```

Cette séparation permet de remplacer un service (par exemple migrer le stockage vers une autre base) sans toucher au métier.

---

## Stack technique

| Domaine            | Choix                                                          |
| ------------------ | -------------------------------------------------------------- |
| Langage            | TypeScript (mode strict)                                       |
| Runtime            | Node.js `>= 22.12.0` (ESM)                                     |
| IA                 | Anthropic Claude (`@anthropic-ai/sdk`)                         |
| Source de données  | Google Sheets (`googleapis`)                                   |
| Publication        | LinkedIn Posts API                                             |
| Validation         | WhatsApp Cloud API (webhook signé HMAC)                        |
| Validation données | Zod (aux frontières)                                           |
| Logs               | Pino (structurés, `clientId` + `runId`)                        |
| Tests              | Vitest                                                         |
| Qualité            | ESLint, Prettier, Husky, lint-staged                           |
| Hébergement        | O2switch (déploiement CI/CD via GitHub Actions + crons cPanel) |

---

## Prérequis

- **Node.js** `>= 22.12.0`
- **Google Cloud** : un projet avec l'API Google Sheets activée, et un compte de service disposant d'un accès éditeur au classeur.
- **LinkedIn** : une app avec le scope `w_member_social`, un token d'accès valide et l'URN de l'auteur.
- **Anthropic** : une clé API (`ANTHROPIC_API_KEY`).
- **WhatsApp Cloud API** (optionnel pour la beta) : token permanent, `phone_number_id`, secret d'application. En son absence, la validation bascule sur un canal console.

---

## Installation

```bash
git clone <url-du-repo>
cd agent-editorial
npm install
```

### Configuration

Copier le modèle d'environnement et le renseigner :

```bash
cp .env.example .env
```

Variables minimales :

```bash
# Google Sheets
GOOGLE_SHEETS_CREDENTIALS_PATH=/chemin/securise/google-service-account.json
GOOGLE_SHEETS_ID=...
GOOGLE_SHEETS_TAB_POSTS=Agent_editorial

# LinkedIn
LINKEDIN_ACCESS_TOKEN=...
LINKEDIN_AUTHOR_URN=urn:li:person:...
LINKEDIN_API_VERSION=202605

# Anthropic
ANTHROPIC_API_KEY=...
ANTHROPIC_MODEL=claude-sonnet-4-6

# Multi-client
CLIENTS_CONFIG_PATH=clients/clients.local.json
```

Créer ensuite la configuration client à partir du modèle :

```bash
cp clients/clients.example.json clients/clients.local.json
```

> **Sécurité** — ne jamais committer `.env`, `clients/clients.local.json`, les credentials Google ou le token LinkedIn. Les tokens sont référencés par variable d'environnement (`accessTokenEnv`), jamais stockés en clair dans le JSON.

### Le Google Sheet

L'onglet attendu (`Agent_editorial` par défaut) comporte les colonnes :

```text
id | reseau | date_publication | statut | texte | publication_lock | published_post_id | published_at | last_error | retry_count
```

`date_publication` est interprétée en **heure locale du client** (fuseau défini dans sa configuration). Les formats ISO et FR (`JJ/MM/AAAA HH:mm:ss`) sont acceptés.

---

## Lancer le projet

### Vérifications sans effet de bord

```bash
npm run build          # Compilation TypeScript
npm run lint           # Analyse statique
npm test               # Tests unitaires (Vitest)
npm run test:sheets    # Vérifie l'accès Google Sheets
npm run test:linkedin  # Vérifie le token LinkedIn (publie un post de test)
```

### Simulations (dry-run, sans publier)

```bash
npm run onboard:dry        # Simule l'onboarding d'un client
npm run generate:dry       # Simule la génération de brouillons
npm run outbound:once:dry  # Simule le cycle sortant complet
npm run publish:dry        # Simule le cycle de publication
```

### Exécution réelle

```bash
# Onboarding d'un client (écrit son profil + sa stratégie)
CLIENT_ID=mon-client npm run onboard

# Génère et notifie les brouillons manquants (cycle sortant)
npm run outbound:once

# Publie les posts validés dus (cycle de publication)
npm run publish:once

# Sert le webhook de validation WhatsApp
npm run serve:webhook
```

En production, les cycles `outbound:once` et `publish:once` sont déclenchés par des crons ; le webhook tourne en service persistant.

---

## Développement

Checklist avant tout commit ou push :

```bash
npm run build
npm run lint
npm test
npm run publish:dry   # si le flux de publication est touché
```

Vérifier également qu'aucun secret (`.env`, credentials, token, `clients.local.json`) n'est indexé par Git.

---

## Documentation

| Document                     | Rôle                                                        |
| ---------------------------- | ----------------------------------------------------------- |
| `docs/plan-courant.md`       | État réel du projet et prochaine action (source de vérité). |
| `docs/decoupage-paliers.md`  | Découpage des paliers P0 à P4.                              |
| `docs/architecture-p0.md`    | Architecture technique du socle.                            |
| `docs/architecture-cible.md` | Vision d'architecture à long terme.                         |

> En cas de contradiction entre documents, `docs/plan-courant.md` fait foi.
