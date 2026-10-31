# 🎲 Dice Throne Solo Quest (DTS)

Application compagne mobile et web pour jouer en solo à **Dice Throne** et **Dice Throne Adventures (DTA)**.

Ce projet propose un moteur de combat automatisé, un mode Survie, des affrontements de boss (dont Naraxus), un mode Minion Rush et un Back Office complet d'équilibrage.

---

## 🚀 Fonctionnalités Principales

- **Moteur de Combat Automatisé** :
  - Gestion fidèle des phases de jeu : Upkeep, Roll Phase (avec IA de relance intelligente des dés), Defensive Roll et Main Phase.
  - Gestion des statuts et tokens officiels (Chaos, Poison, Hémorragie, À terre, Brûlure, Ombre, etc.) avec limites d'empilement (stack limit) et animations dédiées.
  - Résolution des attaques spéciales : suites, combinaisons de symboles, jets additionnels et transformations (ex: Druide ours/élan, fuite de la Guivre noire, régénération de l'Hydre).
- **Modes de Jeu** :
  - **Campagne Survie & Carte** : Parcours d'aventures avec gestion de l'XP, points de vie et tirage de butin.
  - **Minion Rush** : Enchaînement de combats rapides avec classification par niveau de danger.
  - **Boss Battle (Naraxus & Bosses)** : Combats épiques dédiés aux boss avec règles spéciales.
- **Back Office d'Équilibrage (`web/admin`)** :
  - Interface dédiée pour créer, modifier, auditer et valider les profils des monstres (attaques, défenses, passifs, dés).
  - Export direct et synchronisation vers la source de vérité JSON.
- **Sauvegarde Cloud & Authentification** :
  - Synchronisation via **Supabase** (authentification Google OAuth et stockage de l'historique de parties).
- **Mise à Jour In-App (Hors Play Store)** :
  - Détection automatique de nouvelles versions au lancement sur mobile Android via GitHub Pages.
  - Téléchargement direct de l'APK via les GitHub Releases.

---

## 🏗️ Architecture du Projet

Le projet est conçu avec **Flutter** en suivant une architecture modulaire et découplée :

```text
├── .github/workflows/         # CI/CD GitHub Actions (Build APK + Déploiement GitHub Pages)
├── android/                   # Configuration native Android
├── assets/                    # Assets graphiques (icônes de dés, tokens, portraits)
├── docs/
│   ├── enemy_profiles.json    # Source de vérité des statistiques de tous les ennemis
│   ├── BUILD_PROCESS.md       # Protocole de build et règles de versioning
│   └── FIGHT_ARCHITECTURE.md  # Architecture détaillée du moteur de combat
├── lib/
│   ├── data/                  # Dépôts de données (EnemyProfileRepository, etc.)
│   ├── models/                # Modèles de données typés (EnemyNode, MinionAttackPlan, etc.)
│   ├── parts/                 # Écrans et modules métier découpés
│   │   ├── app_shell.dart     # Navigation racine et conteneur responsive
│   │   ├── bestiary.dart      # Bestiaire et consultation des cartes d'ennemis
│   │   ├── fight.dart         # Moteur et UI du combat principal
│   │   ├── fight_logic/       # Logique pure de combat (IA dés, passifs, jetons)
│   │   └── fight_widgets/     # Widgets de combat réutilisables (dés, badges, pop-ins)
│   ├── services/              # Services applicatifs (AppUpdateService, SupabaseService)
│   └── main.dart              # Point d'entrée de l'application
├── test/
│   └── fight_logic_test.dart  # Suite de tests unitaires couvrant la logique de combat
├── tool/                      # Scripts d'automatisation (set-version, verify-fast, preview)
└── web/                       # Application Web, Back Office Admin et Recette
    └── admin/                 # Interface d'administration web des monstres
```

---

## 🛠️ Commandes Utiles & Workflow Développeur

### 1. Lancer la suite de tests
```powershell
flutter test test/fight_logic_test.dart
```

### 2. Aperçu Web Local
Pour tester le build web localement avec le serveur Node.js embarqué :
```powershell
# Compiler le web release
powershell -ExecutionPolicy Bypass -Command "$env:allow_build=1; .\tool\verify-fast.ps1 -Target web"

# Lancer le serveur local (port 8083 par défaut)
node .\tool\local-web-preview.js
```
Accès à l'application : [http://127.0.0.1:8083/Dice-throne-Solo/](http://127.0.0.1:8083/Dice-throne-Solo/)  
Accès au Back Office : [http://127.0.0.1:8083/Dice-throne-Solo/admin/](http://127.0.0.1:8083/Dice-throne-Solo/admin/)

### 3. Incrémenter la version du projet
Avant tout build ou release, la version doit être synchronisée avec le script dédié :
```powershell
powershell -ExecutionPolicy Bypass -File .\tool\set-version.ps1 -Version 1.4.143 -BuildNumber 455
```
Ce script synchronise automatiquement :
- `pubspec.yaml`
- `lib/main.dart` (`appVersionLabel` et `appBuildNumber`)
- `web/version.json` (utilisé par la détection de mise à jour mobile)

---

## 🌐 Déploiement & CI/CD

- **Web (GitHub Pages)** :
  - Workflow : `.github/workflows/deploy-pages.yml`
  - URL de production : [https://bdewev18-droid.github.io/Dice-throne-Solo/](https://bdewev18-droid.github.io/Dice-throne-Solo/)
- **Android APK (GitHub Releases)** :
  - Workflow : `.github/workflows/build-apk.yml`
  - Les builds APK génèrent automatiquement une Release GitHub avec l'APK téléchargeable directement sur smartphone.
