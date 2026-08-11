Avant de faire un build ou un formatage, tu dois lire ce fichier BUILD\_PROCESS.md
ce fichier est ici D:\app\BUILD_PROCESS.md
Si tu souhaites prendre une initative pour faire rapide, demande une confirmation humaine.
Pour le build web locale, si le port est occupé, ouvrir un autre port.

Chaque fois que tu fais un build local (web ou autre), tu DOIS OBLIGATOIREMENT incrementer la version du projet via `.\tool\set-version.ps1 -Version X -BuildNumber Y`.
De plus, si tu as modifie les fichiers de l'admin web (`web/admin/*`), tu DOIS incrementer manuellement la version dans `web/admin/index.html` ET ajouter un parametre de cache buster aux appels CSS/JS (ex: `?v=1.5.6`) pour forcer le rafraichissement.
