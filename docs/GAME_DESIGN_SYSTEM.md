# Dice Throne Solo — Game Design System ("Obsidian & Platinum")

Ce document définit les règles d'interface et de Game Design à respecter sur l'ensemble des écrans et popins de **D.T Solo Quest**.

---

## 1. Palette & Hiérarchie des Couleurs

### Couleurs Système (Hors factions du jeu)
- **Action Principale / Validation (`GameDesign.actionPrimary`)** : **Platine Blanc `#E2E8F0`** avec texte noir **`#121212`** (`GameDesign.goldText`).
  - *Usage* : Boutons de lancement et de progression (`CONTINUE`, `SIGN IN WITH GOOGLE`, `BOSS BATTLE`, `MINION RUSH`, `LAUNCH CAMPAIGN`, `START RUN`, `SAVE`, `OK`, `NEXT ▶`, flèche de transition `→`, `ROLL ENEMY DICE`, `RESUME LATER`).
- **Action Secondaire / Consultation (`GameDesign.slateSurface`)** : **Gris Ardoise `#1B1F2E`** avec bordure **`#3A4159`** (`GameDesign.slateBorder`) et texte blanc **`#FFFFFF`**.
  - *Usage* : Boutons secondaires quand un bouton principal est déjà présent, boutons d'annulation/retour (`CONTINUE AS GUEST`, `BACK`, `◀ PREV`, `ABANDON`, `CANCEL`), et barre de consultation glassmorphique sur la Home Page (`BESTIARY`, `HISTORY`).
- **Surfaces Sombres (`GameDesign.obsidianBg` / `cardBg`)** : **Obsidienne `#131620` / `#181C28`**.
  - *Règle absolue* : Aucun panneau de combat ou popin principale sur fond blanc pur.

### Couleurs Réservées au Gameplay (Exceptions fonctionnelles)
- **Héros (`heroAccent = #FFE22D` — Jaune Or)** :
  - Strictement réservé à l'identité du Héros en combat : badges PV/PC Héros, bouton **`ROLL DEFENSE`** (ou `Roll` héros), **`Edit die`**, **`Reroll die`**.
- **Ennemis (`enemy.rank.color`)** :
  - Bleu, Vert, Violet, Orange, Rouge : réservés aux rangs d'ennemis et au bouton **`FIGHT`** sur la page Map.

---

## 2. Géométrie des Boutons
- **Composant standard** : `GameActionButton` (`lib/design_system.dart`)
- **Hauteur** : `52px` (`58px` pour les boutons principaux de la Home Page)
- **Rayon des coins** : `10px` (`GameDesign.buttonRadius`)
- **Typographie** : `FontWeight.w900`, majuscules pour les actions clés, contraste élevé.

---

## 3. Règles d'Onboarding & Mode Guest
- **Non connecté (Guest / Log out)** :
  - Sur la Pré-HP : aucune carte profil ni statistique affichée.
  - Sur la HP : simple pastille `Guest` (non éditable) à gauche, et bouton `Google` à droite.
  - Lors d'un `Sign out` : vidage immédiat du cache d'historique local, de l'aventure active et retour sur la Pré-HP.
- **Mise à jour non bloquante** :
  - L'application vérifie la version en arrière-plan sans forcer le téléchargement ni bloquer le lancement. Un bandeau cliquable signale si une nouvelle version est disponible.
