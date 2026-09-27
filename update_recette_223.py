import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.223",
    "buildNumber": 258,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajustement UI v4 - Nettoyage icÃ´nes",
    "tags": ["UI", "MAP", "Ergonomie"],
    "summary": "Suppression des icÃ´nes cÅ“ur et Ã©clair dans les puces compactes d'Ã©dition sur la map afin de libÃ©rer visuellement l'espace au profit des labels texte et des boutons de contrÃ´le.",
    "prompts": [
        {
            "id": "p-223-1",
            "userPrompt": "enlever picto coeur, et Ã©clair dans ce qu'on vient de mettre ca laissera plus de place pour Ã©galiser l'espace.",
            "aiResponse": "Suppression des icÃ´nes dans le composant compact, ce qui rÃ©duit sa largeur de 24 pixels par composant, laissant ainsi plus de respiration pour l'ensemble.",
            "items": [
                {
                    "id": "item-223-1-1",
                    "title": "Retrait icÃ´nes superflues",
                    "description": "Les textes HP et CP suffisent, plus besoin des icÃ´nes pour ces contrÃ´les miniatures.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.223!")
