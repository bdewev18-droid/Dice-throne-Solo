import json
import datetime
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_version = {
    "version": "1.3.220",
    "buildNumber": 255,
    "commit": "local-dev",
    "date": datetime.datetime.now().strftime("%Y-%m-%d"),
    "author": "Antigravity AI",
    "title": "Ajustement UI - modification HP/CP (Page MAP)",
    "tags": ["UI", "MAP"],
    "summary": "Optimisation de l'espace dans la zone de modification HP/CP de la MAP : le gros bouton 'Save' a Ã©tÃ© remplacÃ© par un bouton de validation compact (avec un v vert) superposÃ© Ã  l'espace initial de l'icÃ´ne pour gagner un maximum de place.",
    "prompts": [
        {
            "id": "p-220-1",
            "userPrompt": "sur la page MAP, la modification des HP, et CP, le bouton est trop grand. Ajuste cela au mieux. [suite logic: 'soit faire en sorte que le bouton valider se superpose sur le coeur ou le mot CP ainsi une place pour 2 elements']",
            "aiResponse": "Suppression du bouton `FilledButton('Save')` qui prenait 112px de large et du label dynamique (CÅ“ur / CP). Remplacement direct par un `IconButton` vert compact (bouton valider) alignÃ© Ã  gauche, libÃ©rant tout l'espace d'Ã©dition pour les mobiles.",
            "items": [
                {
                    "id": "item-220-1-1",
                    "title": "Optimisation widget Edition Stats",
                    "description": "Remplacement du bouton Save par une icÃ´ne de validation intÃ©grÃ©e Ã  gauche.",
                    "category": "UI"
                }
            ]
        }
    ]
}

data["versions"].insert(0, new_version)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Updated version 1.3.220!")
