import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.222",
    "buildNumber": 257,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajustement UI v3 - Correction d'alignement et dÃ©bordement (Page MAP)",
    "tags": ["UI", "MAP", "Bugfix"],
    "summary": "Sur de petits Ã©crans, les composants cÃ´te Ã  cÃ´te causaient un dÃ©bordement (les boutons + Ã©taient tronquÃ©s ou masquÃ©s). Le panel a Ã©tÃ© rendu auto-redimensionnable (FittedBox) et encore plus compact pour un affichage toujours parfait.",
    "prompts": [
        {
            "id": "p-222-1",
            "userPrompt": "PB d'alignement [capture d'Ã©cran oÃ¹ le bouton + disparaÃ®t]",
            "aiResponse": "Mise en place d'un `FittedBox` couplÃ© Ã  un widget spÃ©cifique ultra-compact (retrait du Spacer dynamique et marges rÃ©duites) pour garantir que l'Ã©dition simultanÃ©e des HP et CP tienne intÃ©gralement sans effet de dÃ©bordement mÃªme sur les Ã©crans les plus Ã©troits.",
            "items": [
                {
                    "id": "item-222-1-1",
                    "title": "Scaling intelligent",
                    "description": "Le composant d'Ã©dition HP/CP sur la map scale dÃ©sormais automatiquement pour ne plus Ã©craser ses contrÃ´les sur mobile.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.222!")
