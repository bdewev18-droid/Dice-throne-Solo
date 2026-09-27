import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.218",
    "buildNumber": 253,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Barbed Vine (Minion vs Hero)",
    "tags": ["UI", "Composants", "Fight", "Bugfix"],
    "summary": "DiffÃ©renciation du composant Barbed Vine selon le joueur : vert classique (Composant 12) pour l'IA, violet avec sÃ©lection multi-rolls (Composant 13) pour le hÃ©ros.",
    "prompts": [
        {
            "id": "p-218-1",
            "userPrompt": "barded vine, lorsque c'est au joueur Minion de jouer, le composant reste le 12 avec la couleur verte. (actif en vert et jouer par l'IA) Lorsque c'est au joueur d'avoir ce token en phase de roll alors on a le composant 13 avec le fond violet.",
            "aiResponse": "Ajout d'une condition `isHeroTurn` sur la propriÃ©tÃ© `color` de `_MultiRollTokenActiveRow` pour Barbed Vine. Si c'est l'IA, on passe du vert, ce qui active le style du composant 12 automatiquement (sans sÃ©lection et vert).",
            "items": [
                {
                    "id": "item-218-1-1",
                    "title": "Barbed Vine pour l'IA (Composant 12)",
                    "description": "RÃ©tablissement de la couleur verte et du style non-interactif pour l'IA.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.218!")
