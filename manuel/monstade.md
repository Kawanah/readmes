# Monstade - site sport santé en entreprise

Site institutionnel de Monstade, qui conçoit des programmes de sport santé pour les
entreprises et les acteurs de l'immobilier. Le site présente la vision, l'approche,
les enjeux traités, l'expertise, les réalisations et les publications de la marque,
et mène vers une page d'atterrissage avec formulaire de contact. Il est compilé en
pages statiques depuis un WordPress headless.

> Le code source est privé. Ce README décrit la conception du site, sans
> réglage ni accès.

---

## Le problème résolu

Monstade avait des maquettes abouties et un discours précis, mais pas de site capable
de les porter sans les abîmer. Deux exigences tiraient en sens contraire.

- **L'équipe doit rester autonome sur ses contenus** : textes, photos, fiches équipe,
  cas clients, articles. Sans développeur, et sans attendre une intervention de
  l'agence pour corriger une phrase.
- **Le design doit rester intact** : typographie, rythme des sections, palette,
  mouvement. Un éditeur de pages libre aurait livré la mise en page à la première
  manipulation malheureuse.

La réponse retenue est un **niveau d'édition intermédiaire** : le client modifie le
contenu de chaque page dans WordPress, la structure de chaque page reste dans le code.
Chaque page a son jeu de champs fixes ; les collections réutilisables (équipe, cas
clients, publications, solutions) sont des types de contenu avec une page de liste et
une fiche. Le site public, lui, ne dépend pas de WordPress à la visite.

---

## Fonctionnement

```
  Équipe Monstade          Agence                          Visiteurs
        │                    │                                 ▲
        ▼                    ▼                                 │
  WordPress headless      GitHub                        Hébergement Node
  pages (champs ACF),     code + CI                     pages pré-générées
  types de contenu           │                                 ▲
        │  publication       │ push, webhook, planification    │ FTPS
        └──── webhook ──────►  GitHub Actions ── build Astro ──┘
                                   │
                                   └─ lit l'API REST de WordPress au build
```

### Contenu lu au build, jamais à la visite

Astro lit WordPress **une fois, à la compilation**. Les pages lisent leur contenu par
une couche unique (`lireContenu()`), jamais directement la source : chaque page a son
**schéma Zod**, et une donnée non conforme fait échouer le build au lieu d'atteindre
la production. Tant qu'un champ WordPress est vide, la page garde le texte validé des
maquettes : le branchement du CMS s'est fait page par page, sans jamais casser le site.

### Repli sur instantané

La dernière réponse connue du CMS est conservée dans le dépôt. Si WordPress ne répond
pas, le build repart de cet instantané plutôt que de bloquer tout déploiement. Si
WordPress répond mais ne ressemble plus à ce que le code attend, le build s'arrête :
on ne construit pas sur une structure inconnue.

### Reconstruction automatique

Publier dans WordPress déclenche un webhook GitHub (`repository_dispatch`) : le site
suit en deux à trois minutes. Une reconstruction nocturne sert de filet si le webhook
échoue.

### Ouverture progressive

Ouvrir le site aux visiteurs et l'ouvrir aux moteurs de recherche sont deux décisions
distinctes, portées par des interrupteurs **fermés par défaut** : seule la valeur
exacte `1` ouvre. En mode fermé, une intégration Astro remplace, **après le build et
sur les fichiers produits**, chaque page non publiée par une page « en préparation ».
Un middleware ne suffirait pas : les pages sont pré-générées. Une page d'atterrissage
et ses pages légales peuvent être publiées seules, pendant que le reste du site reste
réservé à la relecture du client.

### Formulaire de contact

La page d'atterrissage envoie ses demandes à HubSpot par l'**API publique des
formulaires**, côté serveur. Aucun script HubSpot dans la page : pas de cookie tiers,
et un formulaire dessiné comme le reste du site. Il fonctionne sans JavaScript (la
réponse est une redirection), et avec JavaScript (réponse JSON, sans recharger).

### Design system

Les design tokens Tailwind (`@theme`) sont la seule source des valeurs visuelles,
présentés sur une page `/design-system`. Quelques choix non négociables :

- trois polices auto-hébergées, avec polices de secours calées sur leur largeur pour
  éviter les décalages au chargement ;
- angles vifs, aucune ombre, aucun dégradé, fonds en aplat ;
- un seul easing pour tout le mouvement, le survol ne change que la couleur ;
- héros à photos qui défilent dans un chevron, en pause au survol, hors écran ou
  onglet caché ;
- `prefers-reduced-motion` coupe les animations.

---

## Stack technique

| Techno                       | Rôle                                                              |
| ---------------------------- | ----------------------------------------------------------------- |
| **Astro 7**                  | Pages pré-générées, route d'API du formulaire, intégration vitrine |
| **@astrojs/node**            | Adaptateur standalone, process Node sur l'hébergement             |
| **Tailwind 4**               | Styles, via design tokens `@theme` exclusivement                  |
| **TypeScript** (strict)      | Code applicatif et couche de contenu                              |
| **Zod 4**                    | Validation du contenu du CMS au build et du formulaire            |
| **WordPress headless + ACF** | Back-office : champs fixes par page, types de contenu, SEO Yoast  |
| **HubSpot Forms API**        | Réception des demandes de contact, sans script tiers              |
| **@kawanah/ui**              | Composants d'interface partagés de l'agence                       |
| **@kawanah/qualite**         | Règles de code vérifiées : dépendances, doublons, code mort       |
| **Vitest**                   | Tests unitaires de la logique (`src/lib`)                         |
| **ESLint / Prettier**        | Qualité et format, appliqués au commit (Husky + lint-staged)      |
| **GitHub Actions**           | Compilation et déploiement FTPS                                   |
| **Bun**                      | Gestionnaire de paquets et lanceur de scripts                     |

---

## Organisation du code

```
src/
├── config/        identité, navigation, interrupteurs, noms des champs WordPress
├── lib/           logique pure et testée : client WordPress, instantané, contenu,
│                  formulaire, SEO, accès, limitation des envois
├── components/    ui/, editorial/, puis un dossier par page maquettée
├── layouts/       racine (head, SEO, consentement) et mise en page avec menu
├── pages/         une route par fichier, robots.txt et llms.txt générés
├── scripts/       mouvement : un script par page + modules partagés
└── styles/        tokens et utilitaires
wordpress/         mu-plugins et exports ACF versionnés : le serveur ne diverge pas du dépôt
docs/              documentation de reprise du projet
```

Règles de dépendance vérifiées par outil : un composant n'importe jamais une page,
`lib/` n'importe ni page ni composant, aucune valeur de design en dur.

---

## Sécurité

- **CMS fermé au public** : un mu-plugin redirige tout le front WordPress vers la
  connexion et ne laisse passer que l'API. Un second durcit l'installation.
- **Aucun jeton dans le site** : l'API WordPress est lue en anonyme au build.
- **Formulaire** : validation Zod, sanitisation de chaque champ, limitation des
  envois par adresse (l'en-tête `x-forwarded-for` n'est cru que derrière un proxy de
  confiance).
- **Accès de relecture** : comparaison des identifiants en temps constant ; sans
  identifiants configurés sur le serveur, personne n'entre.
- **Publication fermée par défaut** : une variable absente ou mal orthographiée ne
  peut ni publier ni indexer par accident.
- **Aucun secret versionné** : identifiants FTP, adresse du CMS et jetons sont des
  secrets GitHub Actions ou des réglages serveur.

---

_Site conçu et développé par Kawanah Studio._
