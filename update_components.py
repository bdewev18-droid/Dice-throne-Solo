import json
import io

path = "web/recette/recette_data.json"
with io.open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Let's see if Composant 13 already exists
comp_idx = -1
for i, c in enumerate(data.get("components", [])):
    if c.get("id") == "multi-roll-token-bar" or "Composant 13" in c.get("title", ""):
        comp_idx = i
        break

new_comp = {
    "id": "multi-roll-token-bar",
    "category": "Modificateurs (Barres)",
    "title": "Composant 13 : Bandeau Jeton Actif Multi-Rolls (Violet)",
    "description": "Bandeau violet pour les tokens nÃ©cessitant la sÃ©lection du nombre de lancers (ex: Barbed Vine). Remplace le bouton OK tant que 'Select' n'est pas cliquÃ©.",
    "data": {
        "tokenName": "Barbed Vine Rolls",
        "icon": "../assets/token/Barbed-Vine.png",
        "btnText": "Select"
    }
}

if comp_idx >= 0:
    data["components"][comp_idx] = new_comp
else:
    # insert after Composant 12
    insert_idx = len(data.get("components", []))
    for i, c in enumerate(data.get("components", [])):
        if c.get("id") == "hero-token-bar":
            insert_idx = i + 1
            break
    data["components"].insert(insert_idx, new_comp)

with io.open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    
print("Updated components in recette_data.json!")
