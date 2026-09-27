---
name: build-workflow
description: Procédure obligatoire pour générer un build local (web ou apk) de Dice Throne Solo.
---

# Build Workflow

Quand l'utilisateur demande de faire un build (web ou apk), tu DOIS charger cette compétence et suivre scrupuleusement ces étapes dans l'ordre (une étape par appel d'outil) :

1. **Vérifier la version actuelle** : Lis `pubspec.yaml` pour connaître la version courante.
2. **Incrémenter la version** : Exécute `.\tool\set-version.ps1 -Version <nouvelle_version> -BuildNumber <nouveau_build>`. (Par exemple, si la version était 1.3.240+275, passe à 1.3.241+276).
3. **Lancer le build** : Exécute `powershell -ExecutionPolicy Bypass -Command "$env:allow_build='1'; .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 900"` (ou `apk` selon la demande). En cas de problème de syntaxe PowerShell avec les quotes, tu peux simplement utiliser `powershell -ExecutionPolicy Bypass -Command "$env:allow_build=1; .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 900"`.
   *Note : N'exécute JAMAIS la commande build sans avoir fait l'étape 2.*
4. **Mettre à jour la recette** : 
   - Modifie `web/recette/index.html` pour mettre à jour les cache-busters (`?v=...`) et le numéro de version affiché.
   - Ajoute une entrée d'historique dans `web/recette/recette_data.json` via un script python (si nécessaire).
