import json
import datetime

path = "web/recette/recette_data.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.215",
    "buildNumber": 250,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Création du Composant 13 (Barbed Vine multi-rolls)",
    "tags": ["UI", "Composants", "Tokens"],
    "summary": "Fusion du composant 11 et 12. Ajout d'un bandeau interactif permettant de choisir le nombre de lancers (x1, x2, x3) et d'appliquer directement les dégâts du jeton Barbed Vine lorsque c'est le tour du héros.",
    "prompts": [
        {
            "id": "p-215-1",
            "userPrompt": "on va créer un composant 13. Une fusion du 12 et 11. On part sur une base du 11. Mais je veux pourvoir activer plusieurs fois le token sur un même tour. comme barbed Vine, Coté AI s'il est sur le joueur IA, c'est lui qui décide quand arrêté (composant 12 est suffisant) Mais quand le token est sur le hero, alors c'est au hero de déclarer combien de roll il a fait. Il faut donc 'use' plusieurs fois ou indiquer le nb de roll. Rollx1 Rollx2 Rollx3...",
            "aiResponse": "Création du widget `_MultiRollTokenActiveRow`. S'il s'agit du tour du minion, le badge 'Actif' s'affiche (Composant 12). S'il s'agit du tour du héros, une ligne de boutons [x1] [x2] [x3] avec un bouton 'Use' (Composant 13) s'affiche pour appliquer instantanément les dégâts des lancers.",
            "items": [
                {
                    "id": "item-215-1-1",
                    "title": "Composant 13: Barbed Vine Multi-Rolls",
                    "description": "Ajout de la sélection du nombre de lancers et d'un bouton Use pour appliquer les dégâts de contre du jeton Barbed Vine au héros.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated!")
