# Tokens

Ce fichier liste les tokens connus pour alimenter la section dediee dans l'application.

## Liste complete importee

| Token | Limite max | Effet detaille dans le moteur |
| --- | ---: | --- |
| A terre | 1 | A documenter |
| Brulure | 1 | A documenter |
| Chaos | 6 | A documenter |
| Commotion | 1 | A documenter |
| Dégat Bonus | 2 | Ajoute via certains gains de coffre D20 |
| Dépérissement | 2 | A documenter |
| Domination | 1 | A documenter |
| Eboulissement | 1 | A documenter |
| Enchevêtrement | 1 | A documenter |
| Evitement | 3 | A documenter |
| Hémorragie | 2 | Voir detail ci-dessous |
| Main du roi | infinie | A documenter |
| Ombre | 1 | A documenter |
| Parasite | 1 | A documenter |
| Poison | 3 | Voir detail ci-dessous |
| Première Frappe | 1 | Voir detail ci-dessous |
| Prime | 1 | A documenter |
| Pris pour cible | 1 | A documenter |
| Riposte | 1 | Voir detail ci-dessous |
| Ronces | 1 | Voir detail ci-dessous |
| Salve | infinie | A documenter |
| Silence | 1 | Voir detail ci-dessous |
| Siphon vital | 2 | A documenter |
| Sort | 1 | A documenter |
| Vol | 3 | Ajoute via certains gains de coffre D20 |

## Poison

- Type : negatif.
- Limite d'empilement : 3 tokens.
- Persistance : persistant.
- Cible : hero ou minion.
- Effet : pendant la phase d'upkeep de la cible, elle subit 1 degat par token Poison.

## Riposte

- Type : positif.
- Limite d'empilement : 1 token.
- Persistance : non persistant.
- Cible : hero ou minion.
- Effet : durant la phase d'attaque du hero, si un minion a Riposte en jeu et que sa vie baisse pendant ce tour, le minion lance 1 de et inflige au hero la moitie du resultat en degats, arrondie au chiffre superieur.
- Depense : le token doit etre depense quand la vie du minion baisse pendant le tour du hero, meme si la vie du minion arrive a 0 pendant ce tour.
- Rappel UI : pendant le tour du hero, rappeler au joueur de jouer Riposte si les conditions sont reunies.

## Première Frappe

- Type : unique.
- Limite d'empilement : 1 token.
- Persistance : persistant.
- Cible : minion.
- Effet : permet au minion de commencer a attaquer a la place du hero.

## Silence

- Type : unique.
- Limite d'empilement : 1 token.
- Persistance : non persistant.
- Cible : hero uniquement. Ne peut pas etre applique sur un minion.
- Effet : le joueur ne peut pas valider de suite sur son lance.
- Rappel UI : pendant le tour du hero, rappeler que Silence est actif.

## Ronces

- Type : negatif.
- Limite d'empilement : 1 token.
- Persistance : non persistant.
- Cible : hero ou minion.
- Effet : pendant sa phase de lance, la cible perd 1 point de vie par relance apres le premier lance. Si elle va jusqu'a 3 lances, elle perd donc 2 points de vie.
- Automate minion : le minion cherche toujours l'attaque maximum, sauf si les relances le tueraient.

## Hémorragie

- Type : negatif.
- Limite d'empilement : 2 tokens.
- Persistance : persistant avec condition de retrait.
- Cible : hero ou minion.
- Effet : au debut du tour, pendant l'upkeep, la cible lance 1 de par token Hemorragie. Sur 1 a 4, elle subit 1 degat. Sur 5 ou 6, le token est retire.
- Rappel UI : si le hero a ce token, le rappeler au joueur. Si le minion a ce token, le gerer pendant sa phase d'upkeep.
