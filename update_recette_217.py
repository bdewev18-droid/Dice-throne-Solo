import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.217",
    "buildNumber": 252,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Correctifs UI et logiques sur le Composant 13 (Barbed Vine)",
    "tags": ["UI", "Composants", "Fight", "Bugfix"],
    "summary": "Mise à jour du design du statut Selected (vert actif) et du libellé Rolls centré. Correction du calcul des dégâts : 1 dégât par relance après le premier lancer (dmg = max(0, rolls - 1)).",
    "prompts": [
        {
            "id": "p-217-1",
            "userPrompt": "au lieu de mettre gris sur le selected, mettre le vert d'actif sur selected. Rolls, le coler X1 (devant) centré à coté du x1. Attention barbed vine, c'est un damage après le 1er jet. Car là au 3eme, j'ai eu 3 dégats. Mais c'est après le 1er jet, donc au 2eme c'est 1, dégat et au 3eme c'est 2 dédgats",
            "aiResponse": "Mise en place de l'état Selected en vert type 'Actif'. Déplacement du texte 'Rolls' juste devant les sélecteurs [x1] [x2] [x3]. Correction de la formule de dégâts pour ignorer le 1er jet.",
            "items": [
                {
                    "id": "item-217-1-1",
                    "title": "UI 'Selected' vert et label centré",
                    "description": "Le composant 13 affiche un badge vert similaire au composant 12 une fois validé. 'Rolls' est inséré avant les boutons x1 x2 x3.",
                    "category": "UI"
                },
                {
                    "id": "item-217-1-2",
                    "title": "Correction formule Barbed Vine",
                    "description": "Le hÃ©ros prend 1 dégât pour chaque jet après le 1er (dmg = (rolls - 1)).",
                    "category": "Logique"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.217!")
