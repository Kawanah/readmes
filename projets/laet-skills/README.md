# Skills de Laetitia - source unique

Ce depot est **le seul endroit ou l'on modifie un skill**. Toutes les
interfaces lisent d'ici, directement ou par import.

| Interface                                                | Comment elle recoit les skills                             | Mise a jour                  |
| -------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------- |
| Codex                                                    | `~/.agents/skills/<skill>` -> ce depot                     | immediate                    |
| Claude Code (terminal, onglet Code de Desktop)           | `~/.claude/skills/<skill>` -> `~/.agents/skills/<skill>`   | immediate                    |
| Claude web, Desktop (conversation), Cowork, mobile       | skills importes dans le compte Claude                      | `./publier.sh` puis import   |

Claude web et Desktop ne lisent pas ce depot : ils ne connaissent que les
skills importes dans le compte. Le compte redescend ensuite vers Desktop,
Cowork, et Claude Code (prefixe `anthropic-skills:`).

## Modifier un skill

1. Editer `<skill>/SKILL.md` ici (Codex et Claude Code le voient aussitot).
2. `git commit` puis `git push`.
3. `./publier.sh` : liste les skills a reimporter et prepare leurs `.zip`
   dans `zips/`.
4. Dans Claude > Parametres > Capacites > Skills : supprimer l'ancienne
   version, importer le `.zip`.

## Ajouter un skill

Creer le dossier `<skill>/SKILL.md`, lancer `./lier.sh`, puis `./publier.sh`.

## Nouvelle machine

```bash
git clone git@github.com:Kawanah/laet-skills.git dossier local
cd dossier local && ./lier.sh
```

Puis reinstaller les skills tiers listes plus bas.

## Scripts

- `lier.sh` - cree les liens pour Codex et Claude Code. N'ecrase jamais une
  copie locale qui differe de la source : il la signale.
- `publier.sh` - compare au compte Claude, prepare les `.zip`. `--tout` pour
  tout reprendre.
- `sources-externes.txt` - skills dont la source vit dans un autre depot
  (`laet-kawanah-ui` suit la bibliotheque `kawanah-ui`).

## Exceptions

- `skill-creator` : copie personnelle, jamais importee dans le compte (le
  compte a deja celle d'Anthropic, meme nom).
- Les skills fournis par Anthropic (docx, pdf, pptx, xlsx, docs, morning...)
  vivent dans le compte et ne sont pas ici.

## Skills tiers

Installes par `npx skills` dans `~/.agents/skills`, jamais copies ici pour ne
pas casser leurs mises a jour. Liste figee dans `tiers/skill-lock.json`.

| Skill                        | Source                 |
| ---------------------------- | ---------------------- |
| `brandkit`                   | Leonxlnx/taste-skill   |
| `design-taste-frontend`      | Leonxlnx/taste-skill   |
| `design-taste-frontend-v1`   | Leonxlnx/taste-skill   |
| `find-skills`                | vercel-labs/skills     |
| `frontend-design`            | anthropics/skills      |
| `full-output-enforcement`    | Leonxlnx/taste-skill   |
| `gpt-taste`                  | Leonxlnx/taste-skill   |
| `high-end-visual-design`     | Leonxlnx/taste-skill   |
| `image-to-code`              | Leonxlnx/taste-skill   |
| `imagegen-frontend-mobile`   | Leonxlnx/taste-skill   |
| `imagegen-frontend-web`      | Leonxlnx/taste-skill   |
| `industrial-brutalist-ui`    | Leonxlnx/taste-skill   |
| `minimalist-ui`              | Leonxlnx/taste-skill   |
| `redesign-existing-projects` | Leonxlnx/taste-skill   |
| `stitch-design-taste`        | Leonxlnx/taste-skill   |

Reinstallation : `npx skills add <source>` (ex. `npx skills add Leonxlnx/taste-skill`).

## Secrets

Jamais de secret dans ce depot. Les `.env` sont ignores par git et exclus des
`.zip`.

## Archive

`_archive/` : skills remplacés ou obsolètes (`seo-geo`, `deploy-o2switch`), conservés par git. Les scripts `lier.sh` et
`publier.sh` ne les prennent pas (seuls les dossiers contenant directement un `SKILL.md` comptent).
Pour en réactiver un : `git mv _archive/<skill> .` puis `./lier.sh`.
