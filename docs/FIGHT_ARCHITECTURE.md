# Guide d'Architecture & Bonnes Pratiques : Modularisation du Combat (v1.4.x)

## 1. Contexte & Historique

Le fichier `lib/parts/fight.dart` était initialement un fichier monolithique de **plus de 23 600 lignes de code**. 
Cette taille extrême entraînait :
- Des temps d'analyse et de manipulation très longs.
- Des corruptions de fichiers lors de remplacements globaux de texte sous PowerShell.
- Des difficultés pour tester unitairement et faire évoluer les composants UI ou les règles des tokens.

Entre les versions **1.4.0** et **1.4.3**, une refonte modulaire stricte a été entreprise pour découper `fight.dart` en composants et helpers indépendants sans aucune régression.

---

## 2. Structure Modulaire Actuelle

Le code de combat est désormais structuré en plusieurs dossiers thématiques :

```
lib/parts/
├── fight.dart                              # Orchestrateur central d'état (_FightPageState)
├── fight_widgets/                          # Composants UI purs et dialogs
│   ├── token_action_row.dart               # Composants 10, 11 et 12 (Use & Badges)
│   ├── combat_ai_chat_dock.dart            # Dock d'actions principal de combat
│   ├── ai_chat_with_health.dart            # Chat IA, vitals rapides (PV/PC)
│   ├── compact_item_strip.dart             # Barres de statut compactes des altérations
│   ├── enemy_rules_panel.dart              # Panneau accordéon des règles ennemies
│   ├── dice_panel.dart                     # Zone de dés, relance, verrouillage, 3D
│   ├── turn_phase_panel.dart               # Sélecteur de phase (Upkeep, Roll, Def, etc.)
│   ├── token_animation_dialog.dart         # Popin de résolution des dés de tokens
│   └── nanobot_detonation_dialog.dart      # Modale de détonation des nanobots
└── fight_logic/                            # Moteurs et logique métier pure
    └── token_combat_helpers.dart           # Prédicats, compteurs et résumés des tokens
```

---

## 3. Règles d'Or pour les Futurs Développements

### Règle 1 : Ne JAMAIS rajouter de Widgets UI dans `fight.dart`
- Tout nouveau composant visuel, popin ou vue modale **DOIT** être créé dans son propre fichier sous `lib/parts/fight_widgets/`.
- Déclarer le nouveau fichier dans `lib/main.dart` avec la directive `part 'parts/fight_widgets/nom_du_widget.dart';`.

### Règle 2 : Centraliser les Tokens dans `fight_logic/token_combat_helpers.dart`
- Chaque nouveau token ou altération doit avoir son prédicat `_isNomToken(String t)` dans `token_combat_helpers.dart`.
- Ne pas coder de logique d'analyse de chaîne (`t.toLowerCase() == ...`) dispersée dans plusieurs fichiers.

### Règle 3 : Pas de manipulation de gros fichiers via scripts PowerShell/Python opaques
- Utiliser les outils atomiques standard (`replace_file_content` et `write_to_file`).
- Si un composant grandit au-delà de 800 lignes, l'extraire immédiatement dans un nouveau fichier.

### Règle 4 : Validation de non-régression systématique
Avant de valider ou de pousser un commit :
1. `dart analyze` pour vérifier l'absence d'erreurs statiques.
2. `flutter test test/fight_logic_test.dart` pour s'assurer que toutes les règles de combat sont respectées.
3. Incrémenter la version via `.\tool\set-version.ps1 -Version X.Y.Z -BuildNumber N`.
4. Mettre à jour le cache-buster dans `web/recette/index.html` et l'historique dans `web/recette/recette_data.json`.
