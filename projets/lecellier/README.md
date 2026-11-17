# Le Cellier

Webapp de gestion du quotidien alimentaire d'un foyer : **cellier virtuel → listes de courses par magasin → planning repas → « cuisiné » → stock juste**.

Un **cellier** (latin _cellarium_, « réserve ») est la pièce où une maison garde ses provisions : on y conserve, on y voit ce qu'il reste, on y puise pour cuisiner. _Le Cellier_ est celui du foyer, dématérialisé — la mémoire partagée de tout ce qu'on a à manger, où que ce soit rangé.

**Garder** (péremptions, restes) · **Savoir** (stock, seuils, manques) · **Puiser** (planning, cuisiné → déduction) · **Remplir** (listes types, courses par magasin).

En une phrase : savoir ce qu'on a, ce qu'il faut manger d'abord, ce qui manque, et ce qu'on peut cuisiner avec — sans ouvrir un placard.

## État

**Phase : conception validée (CP0, 21/09/2026).** Aucun code applicatif encore — le lot 0 (socle technique) démarre sur décision explicite.

## Stack prévue

Next.js (App Router, PWA) · Convex (Convex Auth, rate-limiter) · Tailwind 4 · Shadcn/ui · TypeScript strict · Vitest + convex-test · Vercel.

## Documentation

| Document                                               | Rôle                                                                                           |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| docs/cadrage-v1.md               | PRD : vision, personas, user stories, parcours, MoSCoW, règles métier, edge cases              |
| docs/build-prompt.md           | Core flow, états importants, build prompt du premier lot                                       |
| docs/architecture.md           | Modules, `src/domain/` pur + Convex adapter, 3NF, multi-foyer, validation, état, harnais React |
| docs/regles-convex.md         | Règles Convex du projet (foyer = frontière, validateurs, nommage)                              |
| docs/plan-construction.md | Lot 0 (socle), lots 1–3, rituels, checkpoints                                                  |
| docs/maquettes/            | 7 écrans mobiles, style verre · végétal · minimal · bleu                                       |

`CLAUDE.md` contient les règles de travail pour Claude Code.

## Licence

Projet personnel — tous droits réservés.
