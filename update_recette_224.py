import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.224",
    "buildNumber": 259,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajout Composant 12 pour Blinding Light",
    "tags": ["UI", "Combat"],
    "summary": "Lorsque le jeton Blinding Light a Ã©tÃ© rÃ©solu via sa popin et qu'il est actif sur le lancer d'attaque, il affiche dÃ©sormais la barre d'Ã©tat (composant 12) avec le badge 'Actif' en vert dans le dock de combat.",
    "prompts": [
        {
            "id": "p-224-1",
            "userPrompt": "sur le token Blinding Light, lorsqu'il a Ã©tÃ© dÃ©clenchÃ© par la popin. Il faut ajouter le composant 12 pour indiquer qu'il est actif.",
            "aiResponse": "Ajout de la condition d'affichage de la ligne de token dans le dock IA : dÃ¨s que le rÃ©sultat du dÃ© de Blinding Light est dÃ©fini et appliquÃ©, la ligne s'affiche avec le tag vert 'Actif'.",
            "items": [
                {
                    "id": "item-224-1-1",
                    "title": "Badge d'activation Blinding Light",
                    "description": "Le dock de combat indique visuellement (composant 12) que l'attaque est sous l'influence du jet de Blinding Light.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.224!")
