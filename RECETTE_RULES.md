# Règles pour la Recette

À chaque fois qu'une nouvelle version de l'application est compilée ou que des modifications sont apportées à la partie recette :

1. **Incrémentation du cache-buster** : Tu DOIS manuellement incrémenter la version du paramètre `?v=...` dans les appels CSS/JS du fichier `web/recette/index.html`.
2. **Synchronisation** : Assure-toi que `web/recette/recette_data.json` contient l'historique correct des prompts et la déclaration des composants.
3. **Mise à jour de l'appli** : Lance toujours `.\tool\set-version.ps1` et la compilation web `.\tool\verify-fast.ps1 -Target web` (ou `flutter build web --release --base-href /Dice-throne-Solo/ --no-pub`).
