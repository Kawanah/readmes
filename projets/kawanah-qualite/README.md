# @kawanah/qualite

Règles de construction de Laetitia (skills `laet-code-rules`, `laet-stack-setup`) vérifiées par des outils, pas seulement écrites.
Une seule source pour tous les projets : Astro (sites) et Next.js + Convex (applications).

## Installer dans un projet

```bash
bunx kawanah-qualite init astro     # ou : init app
bun add -D @kawanah/qualite knip jscpd dependency-cruiser
```

`init` crée `knip.json`, `.jscpd.json`, `.dependency-cruiser.cjs`, `eslint.config.mjs` et le script `qualite`. Il n'écrase jamais un fichier existant.

## Deux niveaux

| Niveau | Quand il tourne | Bloque ? |
|---|---|---|
| **Bloquant** | ESLint normal : commit (lint-staged), hook Claude après chaque modification, avant push | oui |
| **Conseil** | `bun run qualite` (ESLint avec `QUALITE=conseil`, knip, jscpd, dependency-cruiser, classes répétées) | non |

Pourquoi deux niveaux : lint-staged tourne avec `--max-warnings=0`, un avertissement bloquerait le commit.
Une règle passe de conseil à bloquant quand elle n'a plus de faux positif.

## Ce qui est vérifié

| Principe | Règle | Outil | Niveau |
|---|---|---|---|
| YAGNI | TODO / FIXME sans ticket (`#123`, `PROJ-4`, lien) | ESLint `kawanah/todo-avec-ticket` | bloquant |
| YAGNI | fichier, export, dépendance inutilisés ; import non déclaré | knip | conseil |
| SOLID (S) | route API qui importe Supabase, Sanity, Brevo, ou appelle l'API Brevo | ESLint | bloquant |
| SOLID | cycles ; `lib/` qui importe pages ou composants ; route API qui importe un composant | dependency-cruiser | conseil |
| App | `domain/` qui importe React, Next ou Convex | ESLint | bloquant |
| App | `v.any()` dans `convex/` | ESLint | bloquant |
| DRY | code copié-collé | jscpd | conseil |
| DRY | même séquence de 4+ classes Tailwind répétée 3 fois | `classes-repetees.mjs` | conseil |
| KISS | complexité > 10, fonction > 60 lignes, > 4 paramètres, imbrication > 3, Props > 7 | ESLint | conseil |
| Nommage | types en PascalCase, fonctions en camelCase | ESLint | conseil |
| Commentaires | logs `console.error('[domaine] …')` préfixés | ESLint | conseil |

Seuils : `SEUILS` dans `eslint/base.mjs`.

## Limites connues

- jscpd ne voit que du code **identique** : deux blocs HTML de même structure et de texte différent lui échappent. `classes-repetees.mjs` comble ce trou pour Tailwind.
- Constantes en `UPPER_SNAKE`, noms de fichiers (PascalCase, kebab-case) : pas vérifiés ici (il faudrait des types ou un hook à la création de fichier).
- « Abstraction pour un seul usage », « pas de donnée globale » : jugement, pas de règle mécanique.
- Prop ou variante jamais utilisée par aucun appelant : pas encore couvert (Q-06 de la roadmap du harness).

## Tests

```bash
bun run test      # rejoue les outils sur tests/fixtures (projets d'exemple volontairement fautifs)
```
