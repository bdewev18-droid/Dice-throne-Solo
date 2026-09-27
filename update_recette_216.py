import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.216",
    "buildNumber": 251,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajustement du Composant 13 (Barbed Vine multi-rolls)",
    "tags": ["UI", "Composants", "Tokens", "Fight"],
    "summary": "Passage du composant 13 en violet (comme Prey). Ajout de 'Rolls' dans le label. Blocage de l'action 'OK' (validation d'attaque) tant que le bouton 'Select' n'a pas Ã©tÃ© cliquÃ© par le hÃ©ros.",
    "prompts": [
        {
            "id": "p-216-1",
            "userPrompt": "on va passer le composant en violet comme le composant 11. Il faut ajouter 'Rolls' ou 'Roll' entre le nom du tolke et le x1. On va dÃ©sactiver le bouton 'OK' ligen atk/def jusqu'Ã  temps que le bouton 'use' soit actionnÃ©. On peut remplacer 'use' par 'Select' ou 'selected'. Tu ajouter se composant dans la page recette. COmposant 13.",
            "aiResponse": "Composant 13 ajustÃ© : fond violet, texte 'Rolls' ajoutÃ©, bouton renommÃ© 'Select' et passe Ã  l'Ã©tat sÃ©lectionnÃ© aprÃ¨s clic. Le bouton OK de la rÃ©solution d'attaque est dÃ©sormais bloquÃ© tant que l'action Barbed Vine n'a pas Ã©tÃ© rÃ©solue.",
            "items": [
                {
                    "id": "item-216-1-1",
                    "title": "Ajustements UI Barbed Vine",
                    "description": "Couleur violette, libellÃ© 'Rolls' et bouton 'Select' / 'Selected' intÃ©grÃ©s.",
                    "category": "UI"
                },
                {
                    "id": "item-216-1-2",
                    "title": "Blocage de rÃ©solution d'attaque",
                    "description": "Le bouton OK d'ATK/DEF est dÃ©sactivÃ© tant que le jeton Barbed Vine est en attente d'Ãªtre traitÃ© par le hÃ©ros.",
                    "category": "Logique"
                },
                {
                    "id": "item-216-1-3",
                    "title": "Galerie Composant 13",
                    "description": "Ajout du Composant 13 dans la galerie recette.",
                    "category": "Documentation"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.216!")
