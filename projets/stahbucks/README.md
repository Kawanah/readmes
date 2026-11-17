# Stahbucks — Carte digitale & Wi-Fi social

Application web pour cafés et restaurants : une **carte des consommations modifiable en temps réel**, accessible par QR code, doublée d'un **Wi-Fi social** (le code Wi-Fi se révèle après un clic sur les réseaux sociaux de l'établissement).

> POC développé pour un café en Tunisie. Le code est générique et multi-établissement (`businessId` sur toutes les tables métier) : « Stahbucks » désigne le premier client, pas le produit.

## Le problème résolu

Les cartes papier sont coûteuses à réimprimer et vite obsolètes : une rupture de stock, un changement de prix ou une nouvelle boisson imposent une réédition. En parallèle, les cafés cherchent à développer leur présence sociale mais disposent de peu de leviers concrets pour y inciter leurs clients sur place.

Stahbucks répond aux deux :

- **Carte toujours à jour** — le gérant modifie catégories, produits, variantes et prix depuis un back-office ; la carte publique reflète les changements immédiatement, sans réimpression.
- **Wi-Fi qui travaille pour le café** — le client scanne le QR code, découvre la carte, puis obtient le mot de passe Wi-Fi après un clic déclaratif vers la page Facebook ou Instagram du lieu. Chaque connexion devient une occasion de visibilité sociale.

## Fonctionnement

Le parcours s'articule autour d'une URL publique unique (`/[slug]`), cible du QR code affiché en salle.

1. **Carte publique** — le client accède à la carte du café. Seuls les éléments visibles et disponibles sont affichés ; un produit sans variante disponible est masqué. Les prix sont formatés en dinars tunisiens (millimes entiers, jamais de float).
2. **Wi-Fi social** — sous la carte, un bloc invite à suivre l'établissement. Après un clic sur Facebook ou Instagram, le code Wi-Fi (SSID + mot de passe) est révélé. La vérification du like/follow n'est pas réelle : le geste est déclaratif, par choix de simplicité pour le POC.
3. **Back-office propriétaire** — protégé par authentification (email + mot de passe), non indexable. Le gérant y gère la carte (CRUD catégories / produits / variantes, disponibilité, visibilité, réordonnancement, archivage) et les réglages (Wi-Fi, réseaux sociaux, message d'accueil).

**Sécurité** — chaque mutation admin vérifie côté serveur que l'utilisateur est bien propriétaire de l'établissement (`requireOwner`), sans jamais faire confiance au `businessId` transmis par le client. Les requêtes publiques ne renvoient que les données visibles, jamais le mot de passe Wi-Fi. Toute saisie est validée et assainie côté serveur (bornes de longueur, URLs sociales en `https://` sur hôte attendu).

## Stack technique

| Domaine | Technologie |
| --- | --- |
| Framework | Next.js 16 (App Router) · React 19 |
| Langage | TypeScript (strict) |
| Styles | Tailwind CSS 4 |
| Backend & base de données | Convex 1.42 |
| Authentification | Convex Auth (email + mot de passe) |
| Tests | Vitest (logique métier pure) |
| Gestionnaire de paquets | Bun |
| Déploiement | Vercel (front) + Convex (backend) |

### Architecture

Règle directrice : **l'UI ne porte pas de logique métier lourde**. Les règles testables vivent hors de Convex et de React.

```
src/
  app/(public)/   pages publiques (carte /[slug], Wi-Fi)
  app/(admin)/    pages admin protégées, en noindex
  features/       orchestration UI par domaine (menu, admin, wifi)
  domain/         règles métier PURES et testables (pricing, visibilité) — zéro dépendance Convex/React
  lib/            helpers transverses (formatage prix, sanitisation, URLs sociales)
convex/           schéma, auth, queries/mutations (1 fichier = 1 domaine)
```

Modèle de données (Convex) : `businesses`, `businessMembers` (liaison utilisateur ↔ café), `settings`, `categories`, `subcategories`, `products`, `variants`, `events` (analytics anonymes).

## Prérequis

- [Bun](https://bun.sh) (gestionnaire de paquets et runtime)
- Un compte [Convex](https://convex.dev) (backend + base de données)
- Node.js 20+ (utilisé par certaines dépendances)

## Installation

```bash
# 1. Installer les dépendances
bun install

# 2. Configurer Convex (connexion requise la première fois)
bun run dev:convex
```

Le premier lancement de `dev:convex` guide la création/liaison du projet Convex et provisionne les variables d'environnement nécessaires (`.env.local`). Renseigner également le slug du café par défaut :

```bash
# .env.local
NEXT_PUBLIC_DEFAULT_CAFE_SLUG=stahbucks
```

## Lancement

Deux processus tournent en parallèle en développement :

```bash
bun run dev:convex   # backend Convex (base de données + fonctions)
bun run dev          # front Next.js — http://localhost:3000
```

- **Carte publique** : `http://localhost:3000/<slug>` (ex. `/stahbucks`)
- **Back-office** : `http://localhost:3000/admin` (redirige vers `/admin/login`)

Le compte propriétaire se crée depuis la page de connexion admin ; il est automatiquement rattaché à l'établissement côté serveur à la création.

## Scripts

```bash
bun run dev          # serveur de développement Next.js
bun run dev:convex   # backend Convex en développement
bun run build        # build de production
bun run test         # tests Vitest (logique domaine)
bun run lint         # ESLint
bun run typecheck    # vérification TypeScript (tsc --noEmit)
bun run format       # formatage Prettier
```

Un hook pre-commit (Husky + lint-staged) lint et formate automatiquement les fichiers indexés avant chaque commit.

## Conventions figées

- **Prix** en millimes entiers (`7500` = 7.500 DT), formatés via un unique helper — jamais de nombre à virgule flottante.
- **Multi-café** : `businessId` présent sur toutes les tables métier.
- **Langue** : français uniquement, modèle prêt pour FR/AR ultérieurement.
- **Auth** : email + mot de passe, un seul rôle (propriétaire).
