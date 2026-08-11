# Plan de Tests de Non-Régression & Persistance

Ce document référence les différents tests manuels et automatisés à exécuter pour s'assurer de la stabilité du moteur de jeu et de la persistance des données.

## 1. Tests de Persistance et Connexion (Google Sign-In / Base de Données)
Ces tests valident que la sauvegarde des historiques et du profil fonctionne de manière sécurisée et fluide.

*   [ ] **Connexion Initiale** : Se connecter avec un compte Google pour la première fois. Vérifier que la session s'ouvre sans erreur et que le token d'authentification est valide.
*   [ ] **Déconnexion / Reconnexion** : Se déconnecter puis se reconnecter. Vérifier que les anciennes données (historique de parties) sont récupérées correctement depuis Supabase/Firebase.
*   [ ] **Sauvegarde en fin de partie (Victoire)** : Terminer une partie (victoire), valider l'écran de récompense et l'écran de fin. Vérifier dans la base de données (et sur l'historique web) que le `score`, le `hero`, les `hp` et les dates correspondent.
*   [ ] **Sauvegarde en fin de partie (Défaite/Abandon)** : Abandonner une partie ou perdre. Vérifier que le statut est bien enregistré comme défaite dans l'historique cloud.
*   [ ] **Test hors-ligne (Optionnel)** : Si le mode hors-ligne est activé, vérifier que l'historique se met en cache localement et se synchronise au retour de la connexion.

## 2. Tests du Moteur de Combat et Égalités (Regression Engine Tests)
Ces tests s'assurent que la boucle de gameplay principale (phases, HP, CP) est respectée.

*   [ ] **Phase d'Upkeep et CP** : Le héros doit commencer avec 2 CP. À la phase d'Upkeep du joueur 1, le héros gagne +1 CP automatiquement dès la première seconde.
*   [ ] **Calcul des Dégâts et Vol de CP (Minion)** : Vérifier que lorsqu'une attaque de Minion contient un vol de CP (ex: Rat), les CP du héros diminuent et ceux de l'IA augmentent correctement dès la validation des dés.
*   [ ] **Transition Minion Rush** : En mode Minion, tuer le premier ennemi ne doit pas déclencher d'écran Game Over. Le panneau de récompenses (Reward Panel) doit s'afficher en bas, puis passer à l'ennemi suivant après validation.
*   [ ] **[NOUVEAU] Cas d'Égalité (Naraxus)** : 
    *   **Action** : Abaisser les PV du Héros à 0 et les PV de Naraxus à 0 simultanément (ex: dégâts de retour d'une défense, ou capacité spéciale du Barbare).
    *   **Résultat attendu** : Le panneau de résolution doit afficher **"Tie!"** (Égalité).
    *   **Vérification** : Un bonus spécial de **+50 Points de Victoire** doit être automatiquement ajouté au score de l'Aventure, et l'historique doit enregistrer la fin de partie.
*   [ ] **Défaite Classique** : Les PV du Héros tombent à 0 mais l'ennemi a encore des PV. Le panneau de résolution affiche "Defeat!". Le joueur n'avance pas.

## 3. Tests de l'Intégrité des Données et Assets (Data & Assets)
Ces tests valident que l'environnement de jeu se charge correctement, particulièrement après un build.

*   [ ] **Vérification du JSON (`enemy_profiles.json`)** : Tous les profils ennemis doivent être parsables sans exception. Aucun champ obligatoire (ex: `health`, `cp`, `attacks`) ne doit manquer.
*   [ ] **Vérification des Images** : S'assurer que les icônes (tokens), les visages des héros, et les cartes/portraits des ennemis sont bien présents dans les dossiers `assets/` et chargés sans erreur réseau (404) sur le Web.
*   [ ] **Versions et Cache** : Après chaque build local, vérifier que la version en bas à gauche de l'application correspond au dernier incrément (ex: `v1.3.95`) et que les fichiers de cache (`admin/index.html` cache buster) sont à jour si le portail admin a été modifié.
