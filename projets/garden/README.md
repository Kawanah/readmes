# GARDEN

Progressive Web App de gestion de jardin : documenter ses parcelles, son catalogue de plantes, ses semis et ses récoltes, saison après saison — y compris sans connexion.

![Statut](https://img.shields.io/badge/statut-en%20d%C3%A9veloppement-orange)
![React](https://img.shields.io/badge/React-19-61DAFB)
![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E)

---

## Le problème résolu

Un jardinier accumule chaque année des informations qu'il ne retrouve jamais : ce qui a été semé en mars, dans quelle parcelle, avec quel résultat. Les notes finissent sur du papier perdu, dans des photos non légendées ou dans la mémoire — qui, elle, ne tient pas trois saisons.

Cette perte d'historique a un coût concret. Sans traçabilité, on répète les mêmes erreurs : on replante une solanacée là où il y en avait déjà l'an dernier, on oublie quelle variété avait bien supporté la sécheresse, on rachète des semences déjà en stock. Les règles agronomiques qui demandent de la mémoire longue — rotation des cultures, compagnonnage, amendements du sol — deviennent inapplicables.

Les outils existants ne répondent pas au besoin : soit ce sont de simples calendriers génériques qui ignorent la configuration réelle du terrain (exposition, type de terre, zone climatique), soit ce sont des applications cloud inutilisables au fond du jardin, là où le réseau ne passe pas.

GARDEN adresse les trois points ensemble : un modèle de données qui décrit finement le jardin, un historique structuré et interrogeable, et un fonctionnement hors ligne assumé — la saisie se fait sur le terrain, la synchronisation attend le retour du réseau.

---

## Fonctionnement

L'utilisateur décrit son jardin une fois (type, méthode de culture, région), puis y déclare des parcelles caractérisées par leur exposition, leur orientation et leur type de terre. Il pioche ensuite dans un catalogue de plantes — communautaire ou personnel — pour y rattacher semis, plantations et récoltes. Chaque saisie est horodatée et rattachée à une parcelle : c'est cet historique qui rend possibles la rotation et le compagnonnage.

### Flux applicatif

```
  Inscription ──► Onboarding ──► Jardin ──► Parcelles ──► Plantations
                                    │           │              │
                                    │           │              ▼
                                    │           │          Récoltes
                                    │           │              │
                                    └───────────┴──────────────┘
                                                │
                                                ▼
                                    Historique du jardin
                                (rotation · compagnonnage · bilans)
```

### Architecture en couches

Le code impose une séparation stricte des responsabilités. Un composant React n'appelle jamais Supabase directement : il passe par un store, qui délègue à un service, qui seul parle à la couche d'accès aux données.

```
┌──────────────────────────────────────────────┐
│  UI — pages/ components/                     │  React 19, Tailwind
│  Composants sans logique métier              │
├──────────────────────────────────────────────┤
│  État global — store/                        │  Zustand
│  gardens · parcelles · plantes · auth        │
├──────────────────────────────────────────────┤
│  Métier — services/                          │  Validation Zod + règles
│  GardenService · ParcelleService · …         │
├──────────────────────────────────────────────┤
│  Accès données — services/supabase.ts        │  @supabase/supabase-js
├──────────────────────────────────────────────┤
│  PostgreSQL (Supabase) — RLS activé          │  + Service Worker (cache)
└──────────────────────────────────────────────┘
```

**Conséquences pratiques de ce découpage :**

- La validation est centralisée dans `src/utils/validation.ts` (schémas Zod) et rejouée côté serveur par les politiques RLS PostgreSQL. Aucune donnée n'entre en base sans avoir passé les deux barrières.
- Les services sont testables sans monter de composant React.
- Changer de backend revient à réécrire une seule couche.

### Modèle de données

Le schéma est normalisé (1NF/2NF/3NF) et repose sur **23 tables de référence** (`types_jardin`, `expositions`, `types_terre`, `familles_botaniques`, `zones_climatiques`…) plutôt que sur des ENUM PostgreSQL. Ce choix a trois effets : ajouter une valeur ne demande aucune migration de type, les libellés sont enrichissables (emoji, ordre d'affichage, description), et le code ne contient aucun littéral de chaîne codé en dur.

Autres partis pris : identifiants UUID, suppression logique via une colonne `archived`, coordonnées stockées en `latitude`/`longitude` séparées plutôt qu'en type `POINT`, relations multiples exprimées par tables de jointure et non par `TEXT[]`.

### Hors ligne

Le Service Worker est généré par Workbox via `vite-plugin-pwa`. La coquille applicative est précachée ; les appels à l'API Supabase suivent une stratégie **NetworkFirst** avec un cache de secours de 24 h. Les mises à jour de l'application ne s'appliquent pas en silence : `registerType: 'prompt'` affiche une invite de rechargement à l'utilisateur.

---

## Stack technique

| Technologie | Version | Rôle dans le projet |
|---|---|---|
| **React** | 19 | Couche de rendu, routes chargées en `lazy` pour alléger le bundle initial |
| **TypeScript** | 5.9 | Typage strict de bout en bout, types de base générés depuis Supabase |
| **Vite** | 7 | Serveur de développement (HMR) et build de production |
| **Tailwind CSS** | 4 | Système de styles, configuration dans `src/index.css` |
| **React Router** | 7 | Routage, routes privées via le composant `PrivateRoute` |
| **Zustand** | 5 | État global léger, un store par domaine métier |
| **React Hook Form** | 7 | Formulaires non contrôlés, peu de re-rendus |
| **Zod** | 4 | Schémas de validation partagés entre formulaires et services |
| **Supabase** | JS v2 | PostgreSQL, authentification, stockage de fichiers, Row Level Security |
| **vite-plugin-pwa** | 1.x | Manifeste PWA et Service Worker Workbox |
| **Vitest** + Testing Library | 4 / 16 | Tests unitaires et tests de composants (environnement jsdom) |
| **ESLint** + **Prettier** | 9 / 3 | Qualité et formatage, appliqués par un hook Git |
| **Husky** | 8 | Hooks `pre-commit` et `pre-push` |
| **Open-Meteo** | — | Données météo locales, API publique sans clé |
| **Vercel** | — | Hébergement, réécritures SPA et cache long des assets (`vercel.json`) |

---

## Prérequis

| Élément | Version / détail |
|---|---|
| Node.js | 20 LTS ou supérieur (version utilisée par la CI) |
| npm | 10 ou supérieur (fourni avec Node 20) |
| Compte Supabase | Un projet créé, avec son URL et sa clé anonyme |
| Git | Pour les hooks Husky |

Le schéma de base de données doit exister côté Supabase avant le premier lancement. Les migrations SQL vivent dans `supabase/migrations/` et sont à appliquer dans l'ordre chronologique de leurs noms de fichiers (extensions, tables de référence, tables métier, fonctions et triggers, RLS, données de référence, buckets de stockage).

> Le dossier `supabase/` est exclu du dépôt public. Pour un déploiement à partir d'un clone, récupérer les migrations depuis la source privée du projet.

---

## Installation

```bash
# 1. Cloner le dépôt et se placer à sa racine
git clone <url-du-depot> garden-pwa
cd garden-pwa

# 2. Installer les dépendances (installe aussi les hooks Husky via "prepare")
npm install

# 3. Créer le fichier d'environnement local
cp .env.example .env
```

Renseigner ensuite les deux variables dans `.env` (valeurs disponibles dans le tableau de bord Supabase, section *Project Settings → API*) :

```bash
VITE_SUPABASE_URL=https://<votre-projet>.supabase.co
VITE_SUPABASE_ANON_KEY=<votre-cle-anon>
```

Appliquer enfin les migrations sur le projet Supabase, via le *SQL Editor* du tableau de bord ou la CLI :

```bash
# Depuis la racine du projet, avec la CLI Supabase configurée
supabase db push
```

---

## Lancement

```bash
npm run dev              # Serveur de développement avec HMR → http://localhost:5173
npm run build            # Build de production : vérification des types (tsc -b) puis bundle Vite
npm run preview          # Sert le build de production en local (nécessaire pour tester la PWA)
```

Le Service Worker n'est actif que sur un build : tester le mode hors ligne demande `npm run build && npm run preview`, puis une coupure réseau depuis les outils de développement du navigateur.

### Qualité et tests

```bash
npm run lint             # ESLint sur l'ensemble du projet
npm run format           # Prettier en écriture sur src/
npx tsc --noEmit         # Vérification des types sans émission de fichiers
npm test                 # Suite Vitest, une passe
npm run test:watch       # Vitest en mode veille
npm run test:ui          # Interface graphique Vitest
npm run test:coverage    # Rapport de couverture
```

### Garde-fous automatiques

| Déclencheur | Vérifications |
|---|---|
| `pre-commit` (Husky) | Prettier, ESLint `--fix`, `tsc --noEmit`, tests unitaires |
| `pre-push` (Husky) | Build de production complet ; le push est bloqué en cas d'échec |
| CI GitHub Actions | Formatage, lint, types, tests, build, puis publication de l'artefact `dist/` |

La CI se déclenche sur chaque `push` et chaque `pull_request` visant la branche `PWA`.

---

## Sécurité

**Variables sensibles.** L'application n'a besoin que de `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`. Toute variable préfixée `VITE_` est injectée dans le bundle client et donc publique : la clé anonyme n'est pas un secret, mais **aucune clé `service_role` ne doit jamais être placée dans un fichier `.env` de ce projet** — elle contourne toutes les politiques de sécurité. En CI comme sur Vercel, ces deux valeurs sont fournies par les secrets de la plateforme, jamais par un fichier commité.

**Jamais commité.** `.env` et ses variantes locales, `node_modules/`, `dist/`, les journaux, et — par choix de ce dépôt — la documentation Markdown ainsi que le dossier `supabase/`. Seul `.env.example` est versionné, avec des valeurs vides.

**Isolation des données.** Row Level Security est activé sur toutes les tables utilisateur : une requête ne renvoie que les lignes appartenant à l'utilisateur authentifié, la règle étant appliquée par PostgreSQL et non par le client. Les tables de référence sont publiques en lecture seule. Conséquence importante : contourner le client web ne donne accès à rien de plus.

**Validation en deux temps.** Les entrées passent d'abord par un schéma Zod côté client (retour immédiat à l'utilisateur), puis par les contraintes et politiques PostgreSQL côté serveur. La première couche sert l'ergonomie, la seconde fait autorité.

**Gestion des erreurs.** Les erreurs Supabase sont interceptées dans les services ; l'utilisateur reçoit un message clair, et aucun détail technique — requête, structure de table, identifiant interne — n'est exposé dans l'interface.
