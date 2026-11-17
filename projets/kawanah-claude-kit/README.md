# Kit Claude Code - Kawanah Studio

Ce dépôt est un **marketplace de plugins Claude Code**. Il contient la méthode
de l'agence pour construire un site Astro branché sur un WordPress headless,
sous une forme directement exécutable par Claude : des agents, des skills, des
commandes et des modèles de code.

Il est né du site CoReSS, où la même chaîne a été jouée trois fois (annuaire,
agenda, ressources). Le process écrit est dans `docs/process-cms-headless.md`
du dépôt CoReSS ; ici, c'est sa version outillée.

## Installer sur un projet

Dans Claude Code, à la racine du projet client :

```
/plugin marketplace add ~/Documents/011-KAWANAH-STUDIO/kawanah-claude-kit
/plugin install kawanah-wp-headless@kawanah
```

Le marketplace pointe sur le dossier local : une modification ici est
disponible partout après un `/plugin marketplace update kawanah`.

## Ce que le plugin apporte

### Deux agents

| Agent                   | Rôle                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------- |
| `kawanah-chef-projet`   | Établit l'état des lieux, découpe le site en lots, fait valider, délègue               |
| `kawanah-collection-wp` | Branche **une** collection éditable de bout en bout, du CPT jusqu'à la recette         |

Le chef ne code pas les collections : il les confie au spécialiste, une à la
fois. Deux agents sur `src/content.config.ts` en même temps se marchent dessus.

### Quatre skills (à écrire)

| Skill                     | Contenu                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| `kawanah-wp-modelisation` | CPT UI, ACF, exports JSON, mu-plugins de sécurité                   |
| `kawanah-wp-branchement`  | Schéma Zod, loader, instantané de secours, pièges d'API            |
| `kawanah-wp-injection`    | Injection du contenu client par la console, sans aucun secret       |
| `kawanah-wp-recette`      | Liste de vérification avant de déclarer une collection faite        |

### Modèles de code (à écrire)

`templates/` : `wp.ts`, `snapshot.ts`, squelette de loader, mu-plugins PHP,
générateur de script d'injection. Copiés tels quels sur un nouveau projet.

## État d'avancement

- [x] Structure du marketplace et du plugin
- [x] Agent `kawanah-chef-projet`
- [x] Agent `kawanah-collection-wp`
- [ ] Skill `kawanah-wp-modelisation`
- [ ] Skill `kawanah-wp-branchement`
- [ ] Skill `kawanah-wp-injection`
- [ ] Skill `kawanah-wp-recette`
- [ ] Modèles de code dans `templates/`
- [ ] Commandes slash (`/nouvelle-collection`, `/recette-collection`)
- [ ] Essai sur un projet neuf

## Règles d'écriture de ce dépôt

- Français partout, accents compris.
- Pas de tiret cadratin dans nos textes : un tiret simple.
- Aucun secret, aucun identifiant client dans ce dépôt.
