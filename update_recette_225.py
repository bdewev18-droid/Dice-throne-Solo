import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.225",
    "buildNumber": 260,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajout Composant interactif pour Constrict",
    "tags": ["UI", "Combat", "Tokens"],
    "summary": "Mise Ã  jour de Constrict pour utiliser le mÃªme comportement que Barbed Vine. Lors de la phase de lancer du hÃ©ros, il doit dÃ©sormais interagir avec le jeton Constrict pour dÃ©clarer son coÃ»t en CP avant de pouvoir valider l'Ã©tape.",
    "prompts": [
        {
            "id": "p-225-1",
            "userPrompt": "Constrict token est compatible avec le composant 13. donc lorsque c'est le minion on garde el composant 12. lorsque c'est le hero, on affiche le composant 13 (bouton OK dÃ©sactivÃ© en attendant que le select soit utilisÃ©) bref comme barded vine.",
            "aiResponse": "IntÃ©gration du modÃ¨le MultiRollTokenActiveRow pour Constrict dans la phase offensive du dock, le rendant cliquable (composant 13) pour le joueur et informatif (composant 12) pour l'IA, avec retardement des pertes de CP Ã  la rÃ©solution de l'attaque.",
            "items": [
                {
                    "id": "item-225-1-1",
                    "title": "Interface interactive Constrict",
                    "description": "Validation dÃ©bloquÃ©e uniquement aprÃ¨s que le joueur a renseignÃ© le nombre de lancers pour soustraire ses CP, avec blocage de la sÃ©quence.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.225!")
