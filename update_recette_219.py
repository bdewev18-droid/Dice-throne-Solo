import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.219",
    "buildNumber": 254,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Application dÃ©fÃ©rÃ©e des dÃ©gÃ¢ts de Barbed Vine",
    "tags": ["Logique", "Fight", "Bugfix"],
    "summary": "Les dÃ©gÃ¢ts du jeton Barbed Vine sont dÃ©sormais appliquÃ©s uniquement Ã  la fin de la phase (lors de la validation par le bouton OK) afin d'Ã©viter une mort immÃ©diate empÃªchant une Ã©galitÃ©. Un log dÃ©taillÃ© est ajoutÃ© dans la rÃ©solution.",
    "prompts": [
        {
            "id": "p-219-1",
            "userPrompt": "les dégats ne doivent pas se faire sur le bouton sélected, mais sur le bouton OK. Pourquoi , car les dégats en roll phase, se font touts en même temps (token et phase d'attaque); S'il reste que 2 points de vie aux 2 joueurs; Si le joueur qui a Barded vine subit 2 dégats avant même attaqué, il perd dans la version actuelle. Si il a le temps d'attaquer, il peut jouer l'égalité contre un boss ou autre. Donc on déclencher l'effet à la fin du tour de roll.(bouton ok) D'ailleurs, les dégats doivent être visibles via une ligne claire dans le log.",
            "aiResponse": "Mise en mÃ©moire des dÃ©gÃ¢ts du Barbed Vine lors du clic sur 'Select'. Ces dÃ©gÃ¢ts sont maintenant dÃ©duits des HP et consignÃ©s dans le journal du combat lors du clic sur le bouton 'OK' (rÃ©solution gÃ©nÃ©rale de la phase de lancer).",
            "items": [
                {
                    "id": "item-219-1-1",
                    "title": "DÃ©lai des dÃ©gÃ¢ts Barbed Vine",
                    "description": "Stockage des dÃ©gÃ¢ts en attente au lieu d'une soustraction immÃ©diate.",
                    "category": "Logique"
                },
                {
                    "id": "item-219-1-2",
                    "title": "IntÃ©gration au journal",
                    "description": "Ajout d'une ligne dÃ©diÃ©e aux dÃ©gÃ¢ts Barbed Vine dans le rÃ©sumÃ© gÃ©nÃ©ral du log lors du clic sur OK.",
                    "category": "Fight"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.219!")
