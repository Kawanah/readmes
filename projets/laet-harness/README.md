# Harness Claude Code de Laetitia

Source unique de la configuration globale de Claude Code. Les skills vivent ailleurs :
`dossier local` (dépôt `Kawanah/laet-skills`).

| Fichier                 | Lien dans `~/.claude`   | Rôle                                                          |
| ----------------------- | ----------------------- | ------------------------------------------------------------- |
| `CLAUDE.md`             | `CLAUDE.md`             | Instructions globales (style caveman, vérifs, bilan)          |
| `settings.json`         | `settings.json`         | Hooks, skills désactivés, plugins, permissions refusées       |
| `hooks/`                | `hooks/`                | Scripts appelés par les hooks                                 |
| `commands/`             | `commands/`             | Commandes `/bilan`, `/textes-client <lien>`, `/nouveau-projet`                |
| `statusline-command.sh` | `statusline-command.sh` | Barre d'état (badge caveman, modèle, contexte)                |
| `plugins/`              | (marketplace `kawanah-harness`) | Mods Claude Code (panneaux, commandes) : un dossier par mod |

**Pas versionné** : `~/.claude/settings.local.json` (permissions « allow » propres à cette machine).

## Hooks

| Moment                        | Script                  | Effet                                                                 |
| ----------------------------- | ----------------------- | --------------------------------------------------------------------- |
| Démarrage de session          | `last-session.md`       | Réaffiche le bilan de la session précédente                           |
|                               | `frontnote-clos.sh`     | Prévient si le site embarque encore le widget d'un projet FrontNote clos |
|                               | `harness-liens.sh`      | Prévient si un lien `~/.claude` → dépôt est cassé                     |
|                               | `lib/sante.py`          | Branche loin du tronc ou dossier local en retard sur `origin/main` (G-01, `lib/branches.py`, après un `git fetch` court) ? Projet déjà cassé (lint/typecheck) ? `CLAUDE.md` trop long ? `AGENTS.md` sans renvoi ? État de publication (site ouvert, indexable, interrupteurs propres au projet, recette ; tous les workflows de déploiement). Astro en retard sur le registre npm, failles connues (`bun audit` / `npm audit`), via `lib/majs.py` (cache 24 h dans `~/.claude/harness-majs.json`). Silencieux sinon |
| Avant Bash/Read/Write/Edit    | `garde-securite.py`     | Bloque : lecture `.env`, clé API en dur, `SERVICE_ROLE` côté client, `push --force`, `reset --hard`, `--no-verify`, `rm -rf ~`, `curl \| sh`, édition de `docs/client/generated/` |
| Avant Bash et outils MCP      | `garde-cms.py`          | Demande ton accord avant toute écriture dans WordPress ou Sanity (MCP, `curl` vers `wp-json`, WP-CLI, CLI Sanity, script `--appliquer`, script de contenu avec `--ecrire`) : écrire = mettre en ligne |
| Après Edit/Write              | `verif-fichier.sh`      | ESLint (erreurs seulement) sur le fichier modifié → Claude corrige    |
|                               | `textes-client.py`      | Phrase du site presque identique à un export client = retouche → Claude remet le texte exact |
|                               | impeccable `hook.mjs`   | Contrôle design rapide sur fichiers UI                                |
| Après un build (Bash)         | `verif-dist.py`         | Inspecte `dist/` : lorem ipsum, TODO, `localhost`, `example.com`, pages internes dans le plan de site, `noindex` en trop ou absent → Claude corrige ; référencement (canonical, page 404) en avertissement |
| Avant `git push` (par Claude) | `verif-avant-push.sh`   | `.env` suivi ? secrets dans les commits ? push sur `main` qui ouvrirait le site sans recette déclarée, ou avec un `dist/` sale ? contrat WordPress (`lib/wordpress.py` : champ ACF lu par le code absent des exports, config unique, test de contrat, `wp-json` hors du client) ? textes client retouchés ? puis `lint`, `typecheck`/`check`, `test` → push bloqué si échec |
| Fin de réponse                | `verif-termine.py`      | Fichiers modifiés → relance lint/typecheck/test (ou la « Définition de terminé » du `CLAUDE.md`) ; avertit, ou relance Claude une fois si niveau `bloquer` |
|                               | impeccable `hook.mjs`   | Passe design complète                                                 |
| Read, Edit, compaction…       | `jcodemunch-mcp hook-*` | Index de code à jour pour lecture économe                             |
| À la demande                  | `lib/ferme.py`          | S-05 : site fermé vraiment fermé (builds ouvert et fermé dans une copie, serveur local, chaque page appelée) |
|                               | `lib/entetes.py`        | W-03 : point d'entrée sécurisé (adaptateur Node), en-têtes en ligne par type de page, CSP contre les domaines externes de `dist/` (GTM, HubSpot, Google Fonts compris) |
|                               | `lib/animations.py`     | D-01 : animation CSS sans règle `prefers-reduced-motion`, fichier qui anime en JavaScript sans repli (ni lecture du réglage, ni import du module qui le lit) |
|                               | `lib/ci.py`             | P-01, P-06, P-05a : CI sur les PR (lint, tests), gitleaks, `dependabot.yml`, protection de `main` lue sur GitHub (`gh`) |
|                               | `lib/ligne_de_base.py`  | `/ligne-de-base` : tous les contrôles rejoués sur une copie à jour du tronc, rapport daté dans `.claude/ligne-de-base/` |

`test` est sauté avant push si le projet a `.husky/pre-push` (Husky le lance déjà).

## Textes client : activer le contrôle sur un projet

`/textes-client <lien du dossier Drive>` (ou lien d'un Doc, ou chemin local) importe les textes dans
`docs/client/generated/` et écrit `docs/sources.md`. Dès lors, `textes-client.py` contrôle ce projet.
Pour recomparer après une modif du Drive : relancer la commande, puis `git diff docs/client/generated/`.
Sans import, le contrôle ne fait rien dans le projet.

## Publication : recette et interrupteurs

Modèle CoReSS : le code est fermé par défaut, le workflow déclenché par un push sur `main` ouvre le site
(`SITE_OUVERT: '1'`, `SITE_INDEXABLE: '1'`). Tant qu'un interrupteur est ouvert dans ce workflow, un push sur
`main` par Claude est bloqué si aucune recette n'est déclarée dans `.harness.json` :

```json
{ "recette": "2026-10-05" }
```

Recette faite : le push passe si le `dist/` récent est propre (sinon bloqué). `dist/` absent ou plus ancien que le
dernier commit : avertissement, push autorisé.

Site protégé (`SITE_PROTEGE: '1'`) : tout le site en ligne derrière un mot de passe, rien de public. La ligne 📡 le
dit, S-01 ne demande pas de recette, et `lib/ferme.py` (S-05) vérifie que chaque page non publique est refusée sans
identifiant.

## Régler le niveau d'un projet

Fichier `.harness.json` à la racine du projet (facultatif) :

```json
{ "niveau": "avertir", "controles": { "textes-client": "off" } }
```

- `bloquer` (défaut) : l'action est refusée, Claude reçoit l'erreur. `avertir` : message visible, l'action passe. `off` : le contrôle ne tourne pas.
- Réglables : `verif-fichier` (ESLint), `verif-avant-push` (lint, typecheck, tests), `textes-client`, `verif-termine` (défaut : avertir), `sante-ouverture` et `cadrage` (défaut : avertir), `publication` (push sur `main` et état à l'ouverture), `mises-a-jour` (ligne 📦 à l'ouverture, défaut : avertir), `branches` (G-01 à l'ouverture, défaut : avertir), `wordpress` (contrat WordPress au push, défaut : avertir), `verif-dist`, `garde-cms`.
- **Jamais réglables** : `garde-securite`, et dans le push la détection d'un fichier d'environnement suivi ou d'une clé dans les commits.
- Le niveau « avertir » s'affiche à toi ; il n'est pas renvoyé à Claude.

## Mods

Un mod change l'interface ou le comportement de Claude lui-même (panneau, barre, commande slash). Tout vit dans ce dépôt.

| Quoi | Où |
| ---- | -- |
| Mod (TypeScript) | `plugins/<nom>/` : `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/` si état |
| Déclaration du mod | entrée dans `.claude-plugin/marketplace.json` (marketplace `kawanah-harness`) |
| Comportement global (scripts shell/Python, règles, permissions) | `hooks/`, `settings.json`, `CLAUDE.md` |
| Mod ou règle propre à un seul projet | `.claude/` du projet |

Mods actuels : `palette-site` (`/couleurs`), `plan-projet` (`/plan`), `historique-fils` (`/historique`, ouvert à chaque démarrage).

Écrire un mod : Claude le rédige d'abord dans `~/.claude/dev-mods/<session>/<nom>/` (dossier de travail temporaire). Quand il est validé (`claude plugin validate`, `claude plugin test`), le copier dans `plugins/<nom>/`, ajouter l'entrée dans `marketplace.json`, puis `git commit`. Ne jamais laisser un mod fini seulement dans `dev-mods/`.

## Pastille de couleur par projet

La barre latérale ne colore pas le texte : le hook `pastille-projet.py` met un emoji rond ou carré (🟣, 🟢…) en tête du titre de chaque **nouvelle** session (`🟣 Monstade · début du premier prompt`). Une session reprise ou vidée n'est jamais retitrée.

- Table dans `~/.claude/pastilles/projets.json` (état local, hors git) : `{"/chemin/du/projet": {"emoji": "🟣", "nom": "Monstade"}}`. La clé est un préfixe : un dossier parent couvre ses sous-projets, un worktree prend la pastille de son projet.
- Nouveau dossier de projet (`.git`, `package.json` ou `.harness.json`) : première pastille encore libre, enregistrée. Pour changer couleur ou nom : modifier le fichier.

## Journal

`~/.claude/harness-journal.log` (hors dépôt) : une ligne par blocage ou avertissement, et une par jour et par projet
pour les avertissements d'ouverture de session (branches, mises à jour, cadrage, instructions, projet déjà cassé).
Décompte sur 30 jours : `python3 ~/.claude/hooks/lib/journal.py stats`.

## Tests

`tests/lancer.sh` lance tout ; `tests/lancer.sh push` un seul fichier. À relancer après toute modification d'un hook.

## Modifier

1. Éditer ici (effet immédiat, les fichiers sont liés).
2. `git commit`.

Si Claude Code réécrit `settings.json` (changement via l'interface), le lien peut sauter :
`harness-liens.sh` le signale au démarrage. Comparer, reporter dans le dépôt, relancer `./installer.sh`.

## Nouvelle machine

```bash
git clone <ce dépôt> dossier local
uv tool install jcodemunch-mcp
claude mcp add -s user jcodemunch -- "$HOME/.local/bin/jcodemunch-mcp" serve
dossier local
```

Puis `005-SKILLS/lier.sh` pour les skills.

Voir aussi : ROADMAP.md (hooks et skills à faire, dans l'ordre).
