import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.240",
    "buildNumber": 275,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Application des dégâts du token Phoenix Burn",
    "tags": ["Logic", "Combat", "Tokens"],
    "summary": "Ajout du traitement du token Phoenix Burn (Brûlure du phénix) lors de la phase d'entretien (upkeep) pour appliquer les 2 dégâts et afficher la ligne dans les logs.",
    "prompts": [
        {
            "id": "p-240-1",
            "userPrompt": "après recette, le token phonix brurn n'inglige pas les 2 dégats (avant le jet de dès) malgrès l'affichage de la diminution dans la popin. je veux une ligne dans les logs pour les dégats de ce token.",
            "aiResponse": "Ajout de 'Phoenix burn' dans la méthode _upkeepHandlers de game_engine.dart pour appliquer 2 dégâts persistants et ajout des traductions dans les méthodes count() et remove().",
            "items": [
                {
                    "id": "item-240-1-1",
                    "title": "Dégâts Phoenix Burn",
                    "description": "2 dégâts subis lors de la phase d'entretien.",
                    "category": "Engine"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.240!")
