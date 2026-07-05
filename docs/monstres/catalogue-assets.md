# Catalogue des cartes ennemies

Ce fichier sert de registre technique pour rendre le jeu jouable avec toutes les images chargees dans `assets`.

## Statut des donnees

- Les cartes vertes deja lues ont une fiche detaillee et des regles precises dans ce dossier.
- Les nouvelles cartes sont integrees au pool de tirage avec leur image reelle et un profil generique par couleur.
- Les profils generiques permettent de jouer tout de suite, puis chaque carte pourra etre remplacee par sa vraie fiche quand elle sera lue.

## Profils generiques par couleur

| Couleur | Niveau | PV | PC | Defense | Objectif IA |
| --- | --- | ---: | ---: | --- | --- |
| Vert | 1 | 10 | 1 | 2 des, previent 1 degat | 3 symboles jaunes |
| Bleu | 2 | 13 | 2 | 3 des, previent 2 degats | 4 symboles jaunes |
| Violet | 3 | 16 | 3 | 4 des, previent 3 degats | 4 puis 5 symboles jaunes |
| Orange | 4 | 20 | 5 | 4 des, previent 4 degats | 4 symboles jaunes + 1 symbole rouge |

## Cartes vertes avec regles precises

| Code | Nom | Fiche |
| --- | --- | --- |
| Vert002 | Fee | `fee.md` |
| Vert003 | Ronin Vagabond | `ronin-vagabond.md` |
| Vert004 | Enchanteur Gobelin | `enchanteur-gobelin.md` |
| Vert005 | Archer de l'Ombre | `archer-de-lombre.md` |
| Vert007 | Ombre Feline | `ombre-feline.md` |
| Vert008 | Epeiste Egare | `epeiste-egare.md` |
| Vert009 | Elfe du Chaos | `elfe-du-chaos.md` |
| Vert010 | Oni Delirant | `oni-delirant.md` |

## Cartes integrees en profil generique

| Couleur | Fichiers |
| --- | --- |
| Vert | `assets/vert/vert-011.png` a `assets/vert/vert-021.png` |
| Bleu | `assets/bleu/bleu-001.png` a `assets/bleu/bleu-023.png`, plus `assets/bleu/vert-022.png` et `assets/bleu/vert-023.png` |
| Violet | `assets/violet/violet-001.png` a `assets/violet/violet-021.png` |
| Orange | `assets/orange/orange-001.png` a `assets/orange/orange-011.png` |

## Regle de recette

Avant chaque combat, l'application ouvre la page de recette avec une carte compatible deja choisie aleatoirement dans la bonne couleur. Le joueur peut garder ce choix ou selectionner une autre carte dans la liste.
