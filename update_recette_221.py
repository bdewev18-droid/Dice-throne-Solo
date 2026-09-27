import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.221",
    "buildNumber": 256,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajustement UI v2 - Panneau d'Ã©dition MAP",
    "tags": ["UI", "MAP", "Ergonomie"],
    "summary": "Le panneau d'Ã©dition des HP/CP de la MAP s'affiche dÃ©sormais sous forme de deux blocs compacts cÃ´te Ã  cÃ´te (identique Ã  la page Combat) et rÃ©agit en temps rÃ©el. Le gros bouton Save est remplacÃ© par un bouton de fermeture vert.",
    "prompts": [
        {
            "id": "p-221-1",
            "userPrompt": "c'est trop gros, trop disproportionnÃ©. Vs la page de combat, c'est pas proportionnel. ou diviser la taille en 2 sur la largeur, d'un cotÃ© les Hp et de l'autrecotÃ© les CP.",
            "aiResponse": "Mise en page complÃ¨tement rÃ©visÃ©e en rÃ©utilisant le widget `StepperStat` existant. DÃ©sormais, un clic sur HP ou CP affiche directement les deux compteurs proportionnÃ©s cÃ´te Ã  cÃ´te, accompagnÃ©s d'un petit bouton pour fermer.",
            "items": [
                {
                    "id": "item-221-1-1",
                    "title": "Edition simultanÃ©e et compacte",
                    "description": "Les widgets HP et CP partagent horizontalement l'espace du menu Map, rendant l'interface moins invasive.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.221!")
