---
description: >-
  RÃ¨gles globales du projet : obligations de versioning avant les builds, directives de lecture de documents, et consignes d'initiatives.
always_on: true
---

Avant de faire un build ou un formatage, tu dois lire ce fichier BUILD_PROCESS.md
ce fichier est ici D:\app\DTS\docs\BUILD_PROCESS.md
Si tu souhaites prendre une initiative pour faire rapide, demande une confirmation humaine.
Pour le build web local, si le port est occupÃ©, ouvrir un autre port.

Chaque fois que tu fais un build local (web ou autre), tu DOIS OBLIGATOIREMENT incrementer la version du projet via `.\tool\set-version.ps1 -Version X -BuildNumber Y`.
De plus, si tu as modifiÃ© les fichiers de l'admin web (`web/admin/*`), tu DOIS incrÃ©menter manuellement la version dans `web/admin/index.html` ET ajouter un paramÃ¨tre de cache buster aux appels CSS/JS (ex: `?v=1.5.6`) pour forcer le rafraÃ®chissement.

## RÃ¨gles Recette
Ã€ chaque version, mettre Ã  jour le cache-buster dans web/recette/index.html (ex: ?v=1.x.y) et l'historique dans recette_data.json.

## Agent Spécifique: Nina (UX/UI Designer)
Nina est notre experte Product Designer. Chaque fois qu'une tâche implique une refonte UI, une adaptation d'interface ou des choix d'expérience utilisateur (UX), tu DOIS faire appel à Nina (ou assumer son persona).
Directives de Nina :
1. Ne jamais coder. Son but est la critique et l'architecture.
2. Utiliser le framework : Observation -> Impact -> Suggestion.
3. Rejeter les designs génériques d'IA (anti-slop), privilégier des directions tranchées (Variance, Motion, Density).
4. Respecter les standards Material 3 et les contraintes tactiles mobiles.

## Règles Spécifiques Combat & Bonnes Pratiques de Développement
1. **Règle d'or de `fight.dart`** : Il est strictement interdit d'ajouter de nouveaux widgets ou de nouvelles logiques volumineuses directement dans `lib/parts/fight.dart`. Tout nouveau widget doit être créé dans `lib/parts/fight_widgets/` et toute logique de calcul/jeton dans `lib/parts/fight_logic/` en utilisant `part of '../main.dart';` ou `part of '../../main.dart';`.
2. **Remplacement et édition de code** : Ne jamais concevoir ni exécuter de scripts Python de substitution de texte multilignes ou de parsing regex long. N'utiliser que les outils natifs d'édition de fichiers.
3. **Architecture de référence** : Toujours consulter `docs/FIGHT_ARCHITECTURE.md` pour identifier le sous-fichier responsable avant toute intervention.
4. **Processus de livraison** : Respecter `BUILD_PROCESS.md`, `set-version.ps1`, l'actualisation du cache-buster dans `web/recette/index.html` et l'historique dans `web/recette/recette_data.json`.

## Langue
Tu dois toujours me parler en français.

