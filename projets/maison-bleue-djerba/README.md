# La maison bleue Djerba

Landing page premium pour la location saisonnière d'une maison à Djerba (Tunisie), avec calendrier de disponibilités, tarification serveur, demande de réservation et espace d'administration. Projet Agence Kawanah / Laetitia Martin.

---

## Le problème résolu

Louer une maison de vacances en direct — sans passer par une plateforme de masse — pose deux difficultés symétriques :

- **Côté voyageur** : se projeter dans le lieu, vérifier que les dates sont libres, connaître le tarif et déposer une demande _en confiance_, sans compte à créer ni intermédiaire opaque.
- **Côté propriétaire** : recevoir des demandes qualifiées, éviter les doubles réservations, garder la main sur les tarifs et les dates bloquées, et être prévenu immédiatement d'une nouvelle demande.

Ce site répond aux deux : il présente honnêtement la maison, expose les disponibilités et les prix, et transforme la visite en **demande de réservation qualifiée** — tout en donnant au propriétaire un back-office simple et des notifications en temps réel.

---

## Fonctionnement

Le site est une application **Astro en SSR** : les pages publiques sont rendues côté serveur, et les traitements sensibles passent par des routes API dédiées (`src/pages/api`).

### Parcours de réservation (public)

1. Le visiteur consulte la maison, la galerie et les disponibilités (`/api/disponibilites`), avec une estimation de prix calculée à partir de la grille tarifaire (`/api/tarifs`).
2. Il soumet le formulaire de demande, traité par `POST /api/reservation` :
   - **honeypot** anti-bot (`_honey`) + rate limiting,
   - **validation stricte** des champs avec Zod (dates, séjour de 4 nuits minimum, nombre de voyageurs…),
   - **sanitisation** de toutes les entrées (anti-XSS),
   - **contrôle anti-double-réservation** : vérification des créneaux déjà occupés avant enregistrement,
   - **enregistrement** de la demande dans Supabase.
3. Le prix est **recalculé côté serveur** (jamais d'après le client) à partir de la grille tarifaire éditable en admin.
4. Trois notifications non bloquantes sont envoyées : e-mail interne au propriétaire (Brevo), e-mail de confirmation au client (Brevo) et message **WhatsApp** au propriétaire (CallMeBot). Un échec d'envoi n'annule jamais la demande.
5. Depuis l'administration, la propriétaire peut réserver atomiquement les dates et envoyer un lien **Stripe Checkout**. Le voyageur paie sur la page hébergée par Stripe ; le webhook signé confirme ensuite le paiement.

### Administration (privée)

Espace `/admin` protégé par **Supabase Auth** (compte créé manuellement, pas d'inscription publique) permettant de :

- consulter les demandes de réservation (`/api/admin/bookings`),
- bloquer des dates (`/admin/bloquer`),
- éditer la grille tarifaire (`/admin/tarifs`).
- envoyer ou annuler un lien de paiement Stripe, suivre les paiements reçus, expirés et remboursés.

Les mutations sont protégées par origine, jeton CSRF signé, cookies `HttpOnly`, liste blanche des comptes admin, Turnstile et rate limiting persistant dans Supabase.

### Synchronisation calendrier

Un module iCal (`src/lib/ical.ts`, migration `0005_ical.sql`) prépare la synchronisation des disponibilités avec des plateformes externes (ex. Airbnb) pour éviter les chevauchements.

---

## Stack technique

| Domaine                  | Technologie                                                                         |
| :----------------------- | :---------------------------------------------------------------------------------- |
| Framework                | **Astro 7** en SSR                                                                  |
| Adapter                  | `@astrojs/vercel` (sur Vercel) · repli `@astrojs/node` standalone en local/O2switch |
| Styles                   | **Tailwind 4** (design tokens via `@theme` uniquement)                              |
| Langage                  | **TypeScript strict**                                                               |
| Validation               | **Zod 4**                                                                           |
| Base de données          | **Supabase** (réservations, disponibilités, tarifs, auth admin)                     |
| E-mails                  | **Brevo** (fetch natif, sans SDK)                                                   |
| Paiement                 | **Stripe Checkout** hébergé + webhook signé et idempotent                           |
| Anti-abus                | **Cloudflare Turnstile** + rate limiting atomique Supabase                          |
| Notification instantanée | **WhatsApp via CallMeBot**                                                          |
| SEO / OG                 | Sitemap Astro, image Open Graph générée (Satori + Sharp)                            |
| i18n                     | i18n natif Astro — FR par défaut (sans préfixe), EN sous `/en`                      |
| Qualité                  | ESLint · Prettier · Husky · lint-staged · Vitest                                    |
| Package manager          | **bun**                                                                             |
| Hébergement              | **Vercel** (déploiement auto depuis GitHub)                                         |

---

## Prérequis

- **Node.js ≥ 22.12.0**
- **bun** (gestionnaire de paquets)
- Un projet **Supabase** (URL + clés `anon` et `service_role`)
- Une clé API **Brevo** (et un domaine expéditeur authentifié DKIM/SPF)
- Un compte **Stripe** et un endpoint webhook
- Un widget **Cloudflare Turnstile** limité aux domaines du site
- Une clé **Google Places API (New)** et le Place ID de la fiche
- _(Optionnel)_ un compte **CallMeBot** pour les notifications WhatsApp
- _(Optionnel)_ un identifiant **Google Tag Manager** pour l'analytics

---

## Installation

```sh
# 1. Installer les dépendances
bun install

# 2. Créer le fichier d'environnement à partir du modèle
cp .env.exemple .env
# puis renseigner les variables (voir ci-dessous)

# 3. Appliquer les migrations Supabase (dossier supabase/migrations)
#    via le dashboard Supabase ou la CLI Supabase
```

### Variables d'environnement

| Variable                                       | Rôle                                    |
| :--------------------------------------------- | :-------------------------------------- |
| `PUBLIC_SUPABASE_URL`                          | URL du projet Supabase                  |
| `PUBLIC_SUPABASE_ANON_KEY`                     | Clé publique — auth admin               |
| `SUPABASE_SERVICE_ROLE_KEY`                    | Clé service **côté serveur uniquement** |
| `CSRF_SECRET` / `RATE_LIMIT_SALT`              | Secrets aléatoires distincts            |
| `ADMIN_EMAILS`                                 | Comptes Supabase autorisés dans l'admin |
| `PUBLIC_TURNSTILE_SITE_KEY`                    | Clé publique du widget Turnstile        |
| `TURNSTILE_SECRET_KEY` / `TURNSTILE_HOSTNAMES` | Validation Turnstile côté serveur       |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET`  | Checkout et signature des webhooks      |
| `PAYMENT_LINK_TTL_HOURS`                       | Durée du lien Stripe, de 1 à 24 heures  |
| `BREVO_API_KEY` / `BREVO_TO`                   | E-mails transactionnels et alertes      |
| `CALLMEBOT_PHONE` / `CALLMEBOT_APIKEY`         | Notification WhatsApp propriétaire      |
| `GOOGLE_PLACES_API_KEY` / `GOOGLE_PLACE_ID`    | Synchronisation des avis Google         |
| `SITE_URL`                                     | URL publique du site                    |
| `GTM_ID`                                       | Google Tag Manager _(optionnel)_        |

> ⚠️ Ne jamais exposer `SUPABASE_SERVICE_ROLE_KEY` côté client.

Les avis Google sont relus côté serveur et conservés en cache pendant six heures. Si Google est temporairement indisponible, les vrais avis Airbnb restent affichés.

La procédure complète de configuration Stripe, Turnstile, Supabase et du proxy est décrite dans `docs/deploiement-securite-paiement.md`.

---

## Lancer le projet

Toutes les commandes s'exécutent à la racine du projet :

| Commande               | Action                                        |
| :--------------------- | :-------------------------------------------- |
| `bun dev`              | Serveur de développement sur `localhost:4321` |
| `bun build`            | Build de production dans `./dist/`            |
| `bun preview`          | Prévisualisation du build local               |
| `bun lint`             | Analyse ESLint de `src`                       |
| `bun format`           | Formatage Prettier de `src`                   |
| `bun test`             | Tests unitaires (Vitest)                      |
| `bun audit --omit dev` | Audit des dépendances                         |

---

## Structure du projet

```text
src/
├── components/     Composants UI (Hero, Gallery, ReservationForm, Nav…)
├── layouts/        Layouts de pages
├── lib/            Logique métier (bookings, pricing, tarifs, brevo,
│                   whatsapp, sanitize, ical, supabase-server…)
├── pages/
│   ├── api/        Routes API SSR (réservation, disponibilités, tarifs)
│   │   └── admin/  Routes API back-office (auth, bookings, tarifs, blocage)
│   ├── admin/      Pages du back-office
│   ├── en/         Pages en anglais
│   └── index.astro Landing page
├── assets/         Images & polices
└── styles/         Design tokens Tailwind
supabase/
└── migrations/     Schéma SQL (bookings, statuts, pricing, ical)
```

---

## Conventions

- **Design tokens obligatoires** — aucune couleur ou taille codée en dur.
- **Toute entrée utilisateur est validée (Zod) et sanitisée.**
- Formulaires protégés par **CSRF signé**, **Turnstile**, honeypot et rate limiting persistant.
- Routes API en SSR (`export const prerender = false`).
- Commentaires et communications en **français**.

---

_Site développé par l'Agence Kawanah — Laetitia Martin._
