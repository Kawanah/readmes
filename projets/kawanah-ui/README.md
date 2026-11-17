# @kawanah/ui

Bibliotheque de composants Astro reutilisables de Kawanah Studio.

Objectif : ne plus recreer un bouton, un hero ou une carte a chaque site, et
reduire le contexte que les agents consomment sur les projets suivants.

## Principe

La bibliotheque **lit** les design tokens du site, elle ne les **impose**
jamais. Chaque site garde sa palette ; un token manquant tombe sur un repli
neutre et le composant reste lisible au lieu de s'afficher casse.

Aucun composant ne doit necessiter de surcharge CSS depuis l'exterieur.

## Installation

```bash
bun add github:Kawanah/kawanah-ui          # avec bun
npm install github:Kawanah/kawanah-ui      # avec npm
```

Le paquet est distribue par git, sans etape de build : les composants `.astro`
sont consommes en source.

Pre-requis : Astro 7 et Tailwind 4.

### Figer une version (recommande pour un site client)

Un tag est une etiquette fixe posee sur un etat du code. Installer un tag
garantit que le site ne bouge pas quand `main` evolue.

```bash
bun add github:Kawanah/kawanah-ui#v0.1.0
npm install github:Kawanah/kawanah-ui#v0.1.0
```

### Mettre a jour

Relancer la commande d'installation (avec le nouveau tag si la version est
figee). `npm update` ne suffit pas : il reste sur le commit enregistre dans
`package-lock.json`.

### Publier une nouvelle version de la bibliotheque

Rien a publier sur npm. Depuis ce depot :

```bash
bun test && bun run lint && bun run build
git push                                   # met a jour main
git tag -a v0.2.0 -m "v0.2.0 - ..."        # puis version figee
git push origin v0.2.0
```

Penser a aligner le champ `version` de `package.json` sur le tag.

### Deploiement du site hote

Le depot est prive.

- Build en local puis envoi de `dist/` : aucun acces GitHub requis cote
  serveur.
- Build sur le serveur ou en CI (GitHub Actions) : il faut un acces en lecture
  au depot `kawanah-ui` (deploy key SSH ou token en lecture seule dans les
  secrets du site), sinon l'installation echoue.

## Configuration du site hote

Dans le `global.css` du site :

```css
@import 'tailwindcss';
@import '@kawanah/ui/tokens/fallback.css';
@source '../../node_modules/@kawanah/ui/src';

@theme {
  /* Les 8 couleurs du contrat - voir src/tokens/contract.css */
  --color-primary: #0caaaa;
  --color-action: #e8633a;
  --color-on-action: #ffffff;
  --color-surface: #ffffff;
  --color-surface-soft: #f8f6f1;
  --color-text: #171717;
  --color-text-muted: #595959;
  --color-border: #d9d9d9;
}
```

La ligne `@source` est obligatoire : sans elle, Tailwind ne scanne pas
`node_modules` et purge les classes des composants.

## Utilisation

```astro
---
import Button from '@kawanah/ui/components/Button.astro'
---

<Button href="/contact" variante="action" taille="lg">Reserver</Button>
```

## Developpement

```bash
bun install
bun dev       # page de demonstration
bun test      # tests du contrat de tokens
bun run lint
```

## Documentation

- `INDEX.md` - tableau de tous les composants et de leurs props, lisible d'un
  seul coup d'oeil, sans ouvrir un fichier de composant.
- `src/tokens/contract.css` - la liste des tokens attendus.
- `.claude/skills/laet-kawanah-ui/` - skill qui apprend a un agent quand
  piocher ici plutot que de reecrire un composant.
