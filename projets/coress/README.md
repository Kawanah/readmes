# CoReSS IDF Centre-Essonne - site public

Portail du Comité régional de coordination de la santé sexuelle
Île-de-France Centre-Essonne. Au-delà des pages de présentation, le site porte
trois **outils de recherche** : un **annuaire** de structures cartographié, un
**répertoire de ressources** documentaires classé sur deux niveaux, et bientôt
une **recherche de formations**. Tous fonctionnent en **recherche à facettes
rendue au build** - filtrage côté client, aucune requête serveur, aucune base
de données interrogée à la visite. Le site est compilé en pages statiques
depuis un WordPress headless.

> **Vous reprenez ce site ?** Commencez par
> [`docs/reprise-developpeur.md`](docs/reprise-developpeur.md) : ordre de
> lecture, carte des fichiers, accès, chaîne de publication, recettes, état
> du projet. Le support de formation de la cliente est dans
> [`docs/prise-en-main-client.md`](docs/prise-en-main-client.md).

---

## Le problème résolu

Le CoReSS est un organe nommé par arrêté de l'ARS. Son réseau - près de
90 structures de prévention, de dépistage et de prise en charge - n'existait
nulle part sous une forme consultable : un professionnel cherchant une
structure partenaire, ou une personne cherchant un lieu de dépistage près de
chez elle, devait passer par un contact humain ou un PDF daté.

Un site classique aurait déplacé le problème plutôt que de le résoudre. Le
contenu vivant (événements, documents, fiches structure) doit rester modifiable
par l'équipe du comité, sans développeur et sans risque pour la mise en page
livrée par l'agence. À l'inverse, tout ouvrir à l'édition aurait exposé le
design à la première manipulation malheureuse.

Le besoin n'est donc pas seulement éditorial, il est **fonctionnel** : ces
publics ne viennent pas lire une page, ils viennent **chercher** - une structure
selon son type, son territoire et les services qu'elle rend ; un document dans
une arborescence de catégories ; demain, une formation. Le site est vitrine par
sa forme, applicatif par ses usages - sans pouvoir se payer un serveur
applicatif : hébergement mutualisé, pas de base de données côté visiteur, pas de
collecte de données. Toute la recherche devait donc tenir dans du HTML déjà
compilé.

La réponse retenue est une séparation stricte : **trois types de contenu
éditables** (événements, ressources, structures) dans une interface
d'administration familière (WordPress), **tout le reste en dur** dans le code. Le site public, lui, est compilé en fichiers
statiques - aucune base de données n'est interrogée par le visiteur, aucune
donnée personnelle n'est collectée, et le CMS n'est jamais exposé sur
Internet.

---

## Fonctionnement

Le site est **compilé**, pas servi dynamiquement. Les données WordPress sont
lues **une seule fois, au build**, normalisées, validées, puis figées dans le
HTML produit. Le visiteur ne touche jamais le CMS.

```
                      ┌──────────────────────────────┐
  Équipe CoReSS ────► │  WordPress headless (CMS)    │
  (admin WP)          │  CPT : evenement, ressource, │
                      │        structure  + ACF      │
                      │  page « À propos » + ACF     │
                      │  front public fermé (mu-plugin)
                      └──────────────┬───────────────┘
                                     │ API REST (lecture anonyme)
                                     │ + webhook à la publication
                                     ▼
                      ┌──────────────────────────────┐
                      │  GitHub Actions              │
                      │  build Astro                 │
                      │                              │
                      │  loaders ─► normalisation    │
                      │            ─► schémas Zod    │
                      │            ─► snapshot JSON  │◄── repli si le CMS
                      └──────────────┬───────────────┘     ne répond pas
                                     │ FTP
                                     ▼
                      ┌──────────────────────────────┐
                      │  O2switch - process Node     │
                      │  (adaptateur standalone)     │
                      └──────────────┬───────────────┘
                                     ▼
                                  Visiteur
```

### Trois outils de recherche, pas des pages vitrine

Ces trois entrées reposent sur le même mécanisme : une **recherche à facettes
rendue au build**. Le jeu de données complet est écrit dans le HTML au moment de
la compilation ; le JavaScript ne fait ensuite que **masquer côté client** des
éléments déjà présents. Aucune requête n'est envoyée en cours de visite, il n'y a
ni point d'API ni base à interroger. Les pages restent donc lisibles,
imprimables et référençables sans script, et un téléchargement fonctionne quoi
qu'il arrive.

| Outil                        | Mécanisme                                        | État     |
| ---------------------------- | ------------------------------------------------ | -------- |
| **Annuaire des structures**  | Recherche à facettes + carte synchronisée        | En ligne |
| **Répertoire de ressources** | Recherche sur taxonomie hiérarchique à 2 niveaux | En ligne |
| **Recherche de formations**  | Même modèle - CPT, loader, schéma                | À venir  |

**Annuaire** (`/annuaire`) - près de 90 structures, servies simultanément en
liste de fiches et en **carte Leaflet** synchronisée : filtrer la liste redessine
les marqueurs, sélectionner un marqueur ouvre la fiche. Le filtrage est **à
facettes** - type de structure, territoire, service - avec union à l'intérieur
d'une facette et intersection entre facettes, compteurs vivants, bouton « tout
effacer » et état vide explicite. Sur mobile, liste et carte deviennent deux
onglets, l'état initial étant lu dans le HTML rendu pour que serveur et script ne
puissent pas diverger. Aucune facette n'est cochée au départ : un filtre actif
par défaut ferait disparaître les 28 structures dont le service n'est pas
renseigné.

**Répertoire de ressources** (`/ressources`) - bulletins, répertoires et
documents de référence, classés par une **taxonomie hiérarchique à deux
niveaux**, une ressource pouvant porter plusieurs termes dans des branches
différentes. Les filtres sont groupés par catégorie parente, avec icône propre à
chaque catégorie, compteurs par terme et mise en avant du dernier bulletin. Le
téléchargement est direct, sans compte ni formulaire.

**Recherche de formations** - _prévu_. Même modèle que les deux précédents :
un type de contenu dédié côté WordPress, un loader validé par schéma, une page de
recherche à facettes. L'architecture décrite ci-dessous a été pensée pour
qu'ajouter cet outil ne demande ni refonte du build, ni nouvelle dépendance :
un CPT, un loader, un schéma.

### Chaîne de contenu

Chaque collection éditable possède un **loader Content Layer** maison
(`src/lib/*-loader.ts`) qui interroge l'API REST, résout les identifiants de
taxonomie en noms lisibles, décode les entités HTML de WordPress et corrige les
particularités d'ACF (un champ nombre vide arrive en chaîne vide, une date en
`AAAAMMJJ`, un média en identifiant numérique). Les images sont résolues par un
module partagé (`src/lib/wp-medias.ts`) qui préfère la taille `large` de
WordPress à l'original. Le résultat normalisé est ensuite validé par un
**schéma Zod** déclaré dans `src/content.config.ts` : une donnée mal formée
fait échouer le build plutôt que d'atteindre la production.

### Repli sur instantané

Chaque loader écrit sa réponse dans un **snapshot versionné**
(`src/data/*-snapshot.json`). En local, si le CMS ne répond pas, le build
repart du dernier état connu au lieu d'échouer. L'instantané n'est réécrit que
si le contenu a réellement changé, pour ne pas salir le dépôt à chaque
compilation.

**En déploiement, ce repli est interdit** (`WP_SECOURS_INTERDIT: '1'` dans
`deploy.yml`, depuis le 2026-10-23) : les instantanés versionnés ont des
semaines de retard, et une maintenance WordPress de quelques secondes avait
suffi à remettre en ligne l'agenda de septembre, sans ses images. Chaque
requête est réessayée pendant environ une minute (`src/lib/wp.ts`), le
workflow recompile une fois après 2 minutes, puis abandonne sans rien envoyer :
le site en ligne reste tel quel.

### Reconstruction automatique

Un site statique ne voit pas les publications faites après sa compilation. Un
mu-plugin WordPress (`wordpress/mu-plugins/webhook-github.php`) déclenche donc
un `repository_dispatch` GitHub à chaque publication, modification ou
suppression d'un des trois types de contenu ou d'une page, avec anti-rafale de
30 secondes. Le site suit en **une minute environ** (appel reçu en quelques
secondes, compilation et envoi en 30 s, rechargement du process Node). Une
tâche planifiée quotidienne sert de filet si le webhook échoue.

### Deux interrupteurs de publication

Ouvrir le site aux visiteurs et l'ouvrir aux moteurs de recherche sont deux
décisions distinctes, portées par deux variables **fermées par défaut** - seule
la valeur exacte `1` ouvre, une variable oubliée ou mal orthographiée laisse
fermé.

| Variable              | Rôle                                                                   |
| --------------------- | ---------------------------------------------------------------------- |
| `SITE_OUVERT`         | publie toutes les pages ; sinon seule l'accueil est servie             |
| `SITE_INDEXABLE`      | autorise l'indexation (`robots.txt`, `noindex`, plan de site)          |
| `FORMATIONS_OUVERTES` | rubrique `/formations` : `0` fermée, `protege` avec codes, `1` publiée |

Le mode vitrine n'est pas un middleware : le site étant statique, un middleware
ne s'exécuterait pas à chaque visite. Le remplacement a lieu au crochet
`astro:build:done`, **sur les fichiers réellement produits** - aucune page non
publiée ne part sur le serveur, quelle que soit l'adresse devinée.

### Code WordPress versionné

Le dossier `wordpress/` contient la référence du code déposé sur le CMS :
mu-plugins (fermeture du front, durcissement, webhook) et exports d'import
(CPT UI, groupes de champs ACF). Le serveur ne doit jamais diverger de cette
copie : un mu-plugin modifié ici se redépose à la main sur l'hébergement.

---

## Stack technique

| Techno                  | Rôle                                                              |
| ----------------------- | ----------------------------------------------------------------- |
| **Astro 7**             | Génération des pages, Content Layer, îlots de script minimalistes |
| **@astrojs/node**       | Adaptateur standalone - process Node persistant sur l'hébergement |
| **Tailwind 4**          | Styles, via design tokens `@theme` exclusivement                  |
| **TypeScript** (strict) | Typage du code applicatif et des loaders                          |
| **Zod 4**               | Validation des données entrantes du CMS, à la compilation         |
| **Leaflet**             | Carte de l'annuaire - sans clé d'API ni cookie tiers              |
| **WordPress headless**  | Administration des 3 types de contenu éditables (CPT UI + ACF)    |
| **lucide-astro**        | Jeu d'icônes                                                      |
| **Vitest**              | Exécution des tests                                               |
| **ESLint / Prettier**   | Qualité et format, appliqués au commit                            |
| **Husky + lint-staged** | Hooks Git - rien de non conforme n'entre dans l'historique        |
| **GitHub Actions**      | Compilation et déploiement FTP                                    |
| **Bun**                 | Gestionnaire de paquets et lanceur de scripts                     |

Des scripts Python isolés (`scripts/`) ont servi au nettoyage et au géocodage
du jeu de données initial de l'annuaire, puis à l'injection du contenu client
dans WordPress (agenda, ressources, page À propos) par l'API REST, avec un mot
de passe d'application lu dans `.env`. Ils ne font pas partie du build.

---

## Prérequis

- **Node.js ≥ 22.12** (imposé par `engines`)
- **Bun** - gestionnaire de paquets du projet (`bun.lock` fait foi)
- Accès en lecture à une instance WordPress exposant l'API REST, avec les CPT
  `structure`, `evenement`, `ressource`, leurs taxonomies, et une page
  `a-propos` portant le groupe de champs « Page À propos » (imports fournis
  dans `wordpress/`)

Aucun accès en écriture, aucun jeton d'API et aucun compte de facturation ne
sont nécessaires pour compiler le site.

---

## Installation

```bash
# 1. Récupérer le dépôt
git clone <url-du-depot>
cd <dossier-du-projet>

# 2. Installer les dépendances (installe aussi les hooks Git via Husky)
bun install

# 3. Configurer l'accès au CMS
cp .env.example .env
# puis renseigner WP_URL - adresse du WordPress, sans slash final
```

Sans `WP_URL`, les loaders lèvent une erreur explicite au lieu de compiler un
site vide.

---

## Lancement

```bash
# Développement - http://localhost:4321, mode vitrine actif par défaut
bun run dev

# Développement, site entier visible
SITE_OUVERT=1 bun run dev

# Compilation de production (accueil seule si aucune variable n'est posée)
bun run build

# Compilation telle qu'elle est faite en intégration continue
SITE_OUVERT=1 SITE_INDEXABLE=0 bun run build

# Prévisualiser la compilation avant déploiement
bun run preview
```

Autres commandes :

```bash
bun run check    # recette complète : lint, tests, build ouvert, liens internes
bun run lint     # ESLint sur src
bun run format   # Prettier sur src
bun run test     # Vitest
```

`bun run check` est la recette du projet : à lancer avant toute pull request.
Le détail des contrôles est dans `docs/Tests.md`, la recette manuelle dans
`docs/Cahier-recette.md`.

**Déploiement.** Il est automatique : tout `push` sur `main` compile le site et
l'envoie par FTP sur l'hébergement. L'application tournant en process Node
persistant, un fichier d'horodatage est réécrit à chaque livraison pour forcer
le rechargement - copier les fichiers ne suffit pas à recharger le code déjà en
mémoire. Le workflow se déclenche également sur le webhook WordPress, sur une
planification quotidienne et manuellement depuis l'onglet Actions. Deux
variables du workflow décident de ce qui est visible (voir « Deux
interrupteurs de publication » plus haut).

---

## Sécurité

**Ce qui n'est jamais commité.** `.env` et `.env.production`, les identifiants
FTP et l'adresse du CMS de production (secrets GitHub Actions), le jeton GitHub
du webhook WordPress - défini dans `wp-config.php`, jamais dans le code du
mu-plugin versionné. `dist/`, `node_modules/` et le contenu brut fourni par le
client sont également hors dépôt.

**Garde-fous en place :**

- **Aucun formulaire public**, donc aucune collecte de données visiteur : pas
  de service d'emailing, pas de base de données côté visiteur.
- **CMS fermé au public** - un mu-plugin redirige tout le front WordPress vers
  l'écran de connexion et ne laisse passer que `/wp-json`, `/graphql`,
  `wp-login.php` et `wp-cron.php`. Un second durcit l'installation (édition de
  fichiers désactivée, XML-RPC coupé, énumération des comptes bloquée).
- **Aucun jeton dans le client Astro** : l'API est lue en anonyme, précisément
  pour qu'aucun secret ne puisse se retrouver dans le bundle.
- **Tout contenu du CMS est traité comme non fiable** - balises retirées,
  entités décodées, jamais injecté via `set:html`. Les URL saisies à la main
  sont filtrées sur le protocole : un `javascript:` collé par mégarde ne peut
  pas devenir un lien exécutable.
- **Validation Zod au build** : une donnée hors schéma casse la compilation, pas
  la page en production.
- **Ouverture fermée par défaut** : `SITE_OUVERT` et `SITE_INDEXABLE` n'ouvrent
  que sur la valeur exacte `1`. Une variable absente ne peut jamais publier ou
  indexer par accident, et le mode vitrine interrompt la compilation plutôt que
  de livrer le site entier s'il ne trouve pas son gabarit.
- **Carte sans traceur tiers** : Leaflet, sans clé d'API ni cookie soumis à
  consentement.
