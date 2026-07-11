L'objectif de ce fichier et de bien définir ce que doit afficher l application et l'IA dans la zone de bas de page IA. 
Je nommerai ZBP la zone de bas de page IA dans ce fichier.Ce qui est en Italique est une proposition de ce qu'il faut écrire en français. Cela peut-être être modifié et doit être traduit. 

Je vais indiquer dans ce fichier des textes avec des dégâts infligé ou prévenu ou en contre attaque / en retour.Il ne faut pas écrire tout ce texte .
Un dégât infligé par le hero , c'est un rond avec un fond noir, contour blanc et chiffre blanc à l'intérieur. (Déjà prèsent dans le jeu)
Si les dégâts sont infligé sans faire la défense du minion, c'est que les dégâts sont imparables. Parois le minion a aussi des dégâts imparables (c'est indiqué dans sa fiches) on affiche un dégât imparable avec un rond rouge et un le.chiffre en blanc (égal le nb de dégâts)

La contre attaque, c'est souvent des dégâts imparables en contre attaque.On affiche soit le symbole décrit juste au dessus en parrable ou imparable.

1. Début du premier combat.
le jeu affiche dans la ZBP Affrontement entre le (nom du hero, ex barbare) contre (nom du minion). Ensuite on passe à la ligne.

1.1 mode rush introduction.
En mode rush, on indique en introduction des statistiques sur hero. 

1.1.1 première partie du hero 
Si le hero n'a jamais réalisé le mode minion.Le jeu indique dans la ZBP : " Ce hero débute pour la première fois le mode rush minion, sera t il capable de battre tous les ennemis qui se bravent sur son chemin ? " 

1.1.2 deuxième partie du hero
Si le hero a déjà réalisé une partie dans le même mode de jeu, alors le jeu indique dans la ZBP : "En mode (nom du mode (free, medium, hard), le (nom du hero) à marqué (x) points lors du dernier run en battant (x) ennemis, seras-tu faire mieux cette fois-ci? 

1.1.3 plus de 2 parties à son actif pour le hero sélectionné. 
alors le jeu indique dans la ZBP : "En mode (nom du mode (free, medium, hard), le (nom du hero) à marqué une moyenne de  (x) points lors des derniers runs en battant en moyenne (x) ennemis, seras-tu faire mieux cette fois-ci? On Fait des moyennes comme dans l'historique.

1.2 introduction En mode Naraxus

1.2.1 première partie du hero 
Si le hero n'a jamais réalisé le mode naraxus.Le jeu indique dans la ZBP : " Ce hero débute pour la première fois le mode Nazarus, sera t il capable de vaincre le dragon ? " 

1.2.2 deuxième partie du hero naraxus

1.2.2.1 le hero avait gagné la première partie 
Si le hero a déjà réalisé une partie dans ce mode de jeu et déjà gagné la precedente partie alors le jeu indique dans la ZBP : "le (nom du hero)  s'apprête à défier le dragon Naraxus pour la deuxième fois, sera t'il en mesure de le vaincre une deuxième fois le dragon ?"

1.2.2.2 le hero avait perdu à la première partie.
Le jeu indique en ZBP:" Le (nom du hero) s'apprête à défier le dragon Naraxus pour la deuxième fois, sera-t-il capable de le vaincre cette fois ? "

1.2.3 plus de 2 parties à son actif pour le hero sélectionné. 
alors le jeu indique dans la ZBP : "Le (nom du hero) à ( xx%) de victoires dans ce mode de jeu, avec ( x)  victoires  et (x) défaites. seras-tu capable d'améliorer tes stats ? "En mettant les bons calculs.


2 . Début des combats minions

On affiche bien le texte du tout premier combat (1.1) puis, à la ligne , on affiche le texte du premier combat minion à la suite (2.1)
 
2.1. si nous sommes en mode rush, 
alors le jeu indique que c'est le (x ième) adversaire du mode rush. Par exemple : C'est le 3eme affrontement du mode rush minion . (1er affrontement du mode rush minion , 2nd, 13eme ..)2.1.bis Puis indiquer le nb de HP ,cp et token ou bonus que le minion au lancement de la partie (exemple 1 token main du roi )
Fin de la phase d introduction.

3. Début des phases de jeu, la phase d upkeep

3.1 upkeep 
Lors de cette phase l ensemble des personnages (minion, hero, Naxarus) fera la même chose (sauf contre indication spécifique). 3.1.1 le CPEn ZBP le jeu indique : "Début du tour pour (nom du joueur), ce joueur vient de gagner un CP" Le CP est déjà mis en place par l'application.

3.1.1.1 Naxarus mode
Naxarus ne gagne pas de CP, il a une infinité de CP.

3.1.2 les tokens 
Le jeu/ia doit vérifier s'il a des tokens qui s'activent en upkeep. (Exemple brûlure, Poison, hémorragie)l'IA doit indiquer s'il y a un token ou pas de token qui intervient.

3.1.2.1. aucun token
ZBP "aucun token trouvé, le jeu se poursuit."

3.1.2.2 tokens sans manipulation de dés 
Par exemple brûlure ou poison. Le jeu dois indiquer le nb de token, et les effets tout. ZBP " 2 tokens poisons trouvés". 

3.1.2.2.1 si c'est la Upkeep du hero. 
Si on est sur 2 tokens poison par exemple.l'IA indiquera que "Le (nom du joueur) recevra 1 dégât poison et un 2eme dégât poison. Donc 2 hp seront retirés au (nom du joueur) à la fin de l'upkeep" mettre le détail par tokens puis le cumul. 

3.1.2.2.2 si c'est le minion /Naxarus 
Même mécanique, sauf qu'il faudra imputer les points de vie du minion (ou Naxarus) ça sera minio qui recevra les dégâts ou.naxarus. 

3.1.2.3 le token a besoin d'une phase de dés 
Si le token a besoin d'une phase dès comme hémorragie qui demande à un joueur de lancer un dès et sur 5 et 6 le token est supprimé sinon le token inflige un dégât.

3.1.2.3.1 Si le token est sur un hero
L'ia indique au hero qu'il doit lancer son jet que son token.ZBP : "Le hero a le token (nom du token) qui nécessite un jet en phase d upkeep. Veuillez faire le lancer et mettre à jours vos CP ou la zone token."Si le hero a plusieurs tokens nommé l'ensemble des tokens concerné par un jet et mettre au pluriel la phrase avec plusieurs token.

3.1.2.3.2 Si le token est sur le minion /Naxarus 
Alors l'IA va indiquer quelle va lancer le dès du premier token puis elle attendra que le joueur appuie sur OK valider l Action du token.ZBP " j'ai un token hémorragie, je m'apprête à lancer le dès pour savoir si je conserve le token. J'attends ta confirmation sur OK"
Dans le cas où le minion Naxarus a plusieurs token, dès qu'un token a terminé son action enchainer avec les suivants (et validation ok)Il faudra bien indiquer le nb de token à joeur dans cette phase et mettre au pluriel " j'ai 3 tokens hémorragie.." 

3.1.2 s'il y a des tokens sur le joueur
alors le bouton suivant de la zone de tour est inactif On affichera la zone atk/défense et bouton ok (comme en zone battle).l'IA viendra remplir en attaque les points en moins qu'aura le joueur (,atk)S'il y a plusieurs tokens , on fera plusieurs vague C'est le bouton OK valide token après token, vague après vague. S'il n'y a plus de token à jouer, la zone atk,def,ok disparaît et le bouton flèche redevient cliquable et permet d'aller à l'étape battle qui suit. Attention, il arrivera souvent qu'un hero arrive à supprimer un token en phase d upkeep.Bien mette à jour l'IA chat, token après token avec le'bon nombre de vague à faire. 

3.1.3 fin de partie 
Si la fin de partie de déroule lors de la phase d upkeep. Par exemple un poison qui enlève le dernier point de vie d'un joueur. l'IA doit indiquer que la somme des dégâts de l'upkeep pourrait vaincre le joueur..Le bouton ok se transforme en une texte de mort. Il n'y a pas de Phase de battle. Le combat s'arrête, on passe à la phase récompense si c'est le hero qui gagne en mode rush minion. Si c'est le hero qui n'a plus de vie, la partie s'arrête, on met l'écran (rejouer, changer de personnage etc ..cela qu'on a déjà)

3.1.4 upkeep hero
Si nous sommes en upkeep hero,  il faut rappeler au hero de piocher une carte. À la seule condition qu'on token commotion ne soit pas présent sur le hero.ZBP : le (nom du.hero) doit piocher une carte avant sa phase de battle. 


4.la battle phase attaque 

4.1 phase battle hero 

4.1.1 les conditions sur le nb d'attaque.
On affiche un message différent suivant le nombre d'attaque dans le run.

4.1.1.1 la premier attaque du premier combat 
Phrase d introduction :ZBP "Le (nom du hero) entre en jeu, combien fera-t-il sur sa première attaque ? "

4.1.1.2 la deuxième attaque 
On affiche le score de la première attaque.ZBP " Avec (x dégâts) lors de sa première attaque, le (nom du. Hero) fera-t-il mieux ? 

4.1.1.3 toutes les autres attaques
Après les 2 premieres attaques et sur l'ensemble des minions ou en Naxarus ,on va mettre une moyenne d'attaque.ZBP " Le (nom du hero) a une moyenne de (x dégâts par tours. Est-il capable de faire mieux pour terrasser son ennemie ? " 

4.2.1.2 attente de la phase de défense.
l'IA ennemie est en attente du résultat du jet d'attaque physique et elle attend de savoir si l'attaque est imparable (pas de défense, ou parrable avec l'action du jet de défense par le joueur).On affiche donc en ZBP :" Le (nom du hero) effectue son attaque, je suis en attente de mon résultat du jet de défense si l'attaque est parrable. Mon maximum de prévention de dégâts est (x dégâts), mon maximum de dégâts en retour est de (x dégâts)." 

4.2.1.3 affichage du résultat d'attaque  et de defense
Lorsque le hero inscrit son attaque dans la zone attaque/épée fixe en bas de page. Puis il lance la defense du minion / Naxarus. Si l'attaque n'est pas imparable.
l'IA affiche le résultat du dès de défensePar exemple avec la combinaison (xxx) je peux prévenir (x dégâts) ET faire x dégâts en contre attaque avec affichage du bonus ou token infligé.
Une fois le bouton "ok"appuyé de la zone épée bouclier.
l'IA affiche donc le résultat de cette attaque en ZBP : "Le (nom du héros) a infligé (x dégâts) et j'ai prévenu (x dégâts) pour (x dégâts) fait en retour."X peut être 0.Ce message s'affiche en fin d étape de battle hero et resté visible en début d'étape upkeep ennemis. 4.2.1.4 le cas où le'hero ne fait pas de dégâtsSi le hero ne fait pas de dégâts en phase d'attaque, allors il n'y a pas de phase de défense. l'IA chat unique en ZBP " l'attaque du (nom du héros) a échoué. " Ce texte reste affiché en phase d upkeep, il s'affiche à la fin de la phase battle une. Fois le bouton (ok )(zone épée bouclier) cliqué 

4.2. deuxièeme phase battle minion 

4.2.2.1 premier lancé automatique.

l'IA lance le premier lancé automatiquement (c'est déjà développé).l'IA chat indique les dés qu'il conserve (c'est déjà développé)l'IA chat indique les dégâts réalisés sur ce premier jet. ZBP "je fais (x dégâts) sur mon premier jet grâce aux dés (x x x x x)  et j inflige (x tokens /bonus passif etcc. ) " Ou "Je ne fais aucun dégâts sur ce premier lancé."La zone attaque / épée est complétée par l'IA 

4.2.2.2 deuxième lancé 
Le deuxième lancé reprend la même mécanique que le premier lancé. On remplace juste premier par deuxième en mettant au pluriel.

4.2.2.3 dernier lancé
Au 3eme lancé et dernier lancé.l'IA chat indique le résultat de son attaqueZBP " A l'issue de mes  jets d'attaque, je fais (x dégâts) et j inflige (x tokens, bonus, passif) Le (nom du héros) va-t-il faire échouer mon attaque ?"

4.2.2.3.1 l attaque du minion est parrable.
En ZBP on affiche : "Le  (nom du hero ) doit effectuer sa phase défensive."

4.2.2.3.2 l'attaque du Minion est imparable 
En ZBP on affiche " l'attaque de (nom du minion ) est imparable, le (nom du hero) n'a pas de défense".

4.2.2.4 on passe à la phase suivante.
Si le.hero ne change pas les dés, on attend qu'il appuie sur le bouton "OK" de la zone épée bouclier ok. et alors on passe à la phase d' upkeep suivante 

4.2.2.5 mise à jours 
Si le hero change les dés lors d'un jet d'attaque du minion , il faut recalculer les résultats de l attaque du minion et afficher de nouveau dans l'IA chat le nouveau résultat.

4.2.3 phase battle Naxarus 
Naxarus commence toujours (token 1er frappe). 
Il n'a qu'un seul dès 

4.2.3.1 premier lancé automatique.
l'IA lance le lancé de dés automatiquement dès lors que la phase de battle Naxarus s'enclenche.
l'IA chat indique le chiffre sur le lancé de dés.l'IA chat indique les dégâts réalisés sur ce premier jet. Et le nom de l'attaque ZBP "je fais  l'attaque (nom de l'attaque) faisant (x dégâts) grâce au dés (x )  et j inflige (x tokens /bonus passif etcc. ) " La zone attaque / épée est complétée par l'IA

4.2.3.2 l attaque de Naxarus est parrable.
En ZBP on affiche : "Le (nom du hero ) doit effectuer sa phase défensive."

4.2.3.3 l'attaque de Naxarus est imparable 
En ZBP on affiche " l'attaque de Naxarus est imparable, le (nom du hero) n'a pas de défense

4.2.3.4 on passe à la phase suivante.
Si le.hero ne change pas les dés, on attend qu'il appuie sur le bouton "OK" de la zone épée bouclier ok. et alors on passe à la phase d' upkeep suivante 

4.2.3.5 mise à jours
Si le hero change les dés lors du jet d'attaque de.Naxarus , il faut recalculer les résultats de l attaque de Naxarus et afficher de nouveau dans l'IA chat le nouveau résultat.

5. Combat terminé et Fin de partie.

5.1 minion est vaincu
Une fois un minion vaincu, le hero ayant réussi à réduire les HP du minion à 0 ou moins. Alors on affiche la page de récompense (dès de 20) correspondant au Minion 

5.2 Naxarus est vaincu
Alors on affiche le mode historique de jeu sur l'onglet Naxarus.

5.3. Le hero est vaincu 
On affiche alors la popin Nouvelle partie (HP)Historique. (Ouverture page historique sur le mode de jeu qu'on vient de jouer) Quitter. 

