# Vox Populi

> **What candidates say vs. what people talk about.**

App qui compare ce dont parlent les candidats à la présidentielle 2027 et ce dont parlent
vraiment les citoyens sur TikTok et Instagram, en écartant ce qui est poussé artificiellement.

Hackathon **Hack the Feed** (Oriane × Lovable × Brut, Albert School Paris) : track 02 · Brut,
« Déchiffrer les conversations sur les réseaux sociaux ». 7 novembre 2026.

## Ce que fait l'app

1. **Recherche** d'un sujet large (ex. « présidentielle 2027 ») via l'API Oriane
2. **Séparation** candidats / citoyens (appartenance à la liste des candidats)
3. **Classement par thème** (13 thèmes de référence, attribution par IA)
4. **Comparaison** de la part de chaque thème des deux côtés, triée par écart
5. **Détail d'un thème** : jusqu'à 5 vidéos par côté (compte, date, vues, lien)

Bonus : étiquette « contenu poussé » (signaux de coordination), filtre par tranche d'âge.

## Ce que l'app ne fait pas

- Elle ne dit pas ce qui est vrai et ne détecte pas les fausses informations.
- Elle ne présuppose pas qu'un écart existe : elle le mesure.
- Elle ne favorise aucun bord : tous les candidats sont traités de la même façon.
- Aucune estimation d'âge à partir des visages.

## Stack

- **Next.js** : front, déployé sur Vercel
- **Convex** : base de données et fonctions serveur (tous les appels API y passent)
- Clés API en variables d'environnement Convex uniquement : `ORIANE_API_KEY`, `ANTHROPIC_API_KEY`

## Développement

```bash
npm install
npm run dev        # serveur local sur http://localhost:3000
npm run check      # eslint + tsc --noEmit
npm run build      # build de production
```

Convex (base de données et fonctions serveur) est installé mais pas encore initialisé.
Première fois, dans un terminal séparé, ouvre une page de connexion :

```bash
npx convex dev
```

Les polices sont une pile système (`ui-sans-serif, system-ui, …`) : aucun appel réseau au build.

Le cadrage complet (principes, thèmes, planning, définition de terminé) est dans
CLAUDE.md.

## Licence

Privé : tous droits réservés.
