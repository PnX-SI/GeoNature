FAQ
===

Problèmes liés au frontend
--------------------------

Message d'erreur lors de la compilation du frontend 
"""""""""""""""""""""""""""""""""""""""""""""""""""

- **Probleme lié à Node-sass**::

    at module.exports (/home/myuser/geonature2/frontend/node_modules/node-sass/lib/binding.js:15:13) at Object.<anonymous> (/home/myuser/geonature2/frontend/node_modules/node-sass/lib/index.js:14:35)

Lancer la commande : ``npm rebuild node-sass --force``



- **Probleme de mémoire**
    ::

        [26098:0x3d10640]    98298 ms: Scavenge 977.3 (1059.9) -> 962.2 (1059.9) MB, 18.5 / 0.0 ms  allocation failure 
        <--- JS stacktrace --->
        Cannot get stack trace in GC.
        FATAL ERROR: MarkingDeque::EnsureCommitted Allocation failed - process out of memory

    Cela vient d'un manque de mémoire vive lors de l'execution de la compilation frontend.
    Executer les commandes suivantes pour libérer de l'espace mémoire (https://stackoverflow.com/questions/26193654/node-js-catch-enomem-error-thrown-after-spawn):

    ::

        sudo fallocate -l 4G /swapfile Create a 4 gigabyte swapfile
        sudo chmod 600 /swapfile Secure the swapfile by restricting access to root
        sudo mkswap /swapfile Mark the file as a swap space
        sudo swapon /swapfile Enable the swap


- **Problème pour trouver le chemin de lancement du frontend**
    ::
    
        Tried to find bootstrap code, but could not. Specify either statically analyzable bootstrap code or pass in an entryModule to   the plugins options.

    
    Editez le fichier ``/home/<my_user>/geonature/frontend/tsconfig.json`` et renseignez les bon chemin vers le frontend de geonature

    ::

        "@angular/*": ["/home/<my_user>/geonature/frontend/node_modules/@angular/*"],
        "@geonature_common/*" : ["/home/<my_user>/geonature/frontend/src/app/GN2CommonModule/*"],
        "@geonature/*" : ["/home/<my_user>/geonature/frontend/src/app/*"],
        "@geonature_config/*" : ["/home/<my_user>/geonaturefrontend/src/conf/*"],
