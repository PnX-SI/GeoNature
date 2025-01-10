FAQ
===

Problèmes liés au frontend
--------------------------

Changement d'URL de GeoNature
"""""""""""""""""""""""""""""

Si vous souhaitez changer l'URL de l'API de GeoNature, il est nécessaire d'indiquer les nouvelles adresses dans le fichier de configuration principale (``geonature/config/geonature_config.toml`` pour GeoNature, ainsi que celle de UsersHub)  ainsi que le fichier ``frontend/src/assets/config.json`` précisant l'URL de l'API au frontend. Pour mettre à jour ce fichier automatiquement, relancer le script ``install/05_install_frontend.sh``.
 
Message d'erreur lors de la compilation du frontend
"""""""""""""""""""""""""""""""""""""""""""""""""""

- **Problème lié à Node-sass**::

    at module.exports (/home/myuser/geonature2/frontend/node_modules/node-sass/lib/binding.js:15:13) at Object.<anonymous> (/home/myuser/geonature2/frontend/node_modules/node-sass/lib/index.js:14:35)

Lancer la commande : ``npm rebuild node-sass --force``


- **Problème de mémoire**

Si vous avez un message d’erreur durant le build du frontend ressemblant à l’un des messages ci-dessous :

.. code-block:: dmesg

    [26098:0x3d10640]    98298 ms: Scavenge 977.3 (1059.9) -> 962.2 (1059.9) MB, 18.5 / 0.0 ms  allocation failure 
    <--- JS stacktrace --->
    Cannot get stack trace in GC.
    FATAL ERROR: MarkingDeque::EnsureCommitted Allocation failed - process out of memory

.. code-block:: console

    $ npm run build

    > geonature@0.0.0 build
    > ng build --aot=false --build-optimizer=false --configuration production

    Warning: Support was requested for IE 11 in the project's browserslist configuration. IE 11 support is deprecated since Angular v12.
    For more information, see https://angular.io/guide/browser-support
    ✔ Browser application bundle generation complete.
    Killed

Cela vient d'un manque de mémoire vive lors du build du frontend.

Vous pouvez essayer de stopper les backends durant le build du frontend :

.. code-block:: console

    $ sudo systemctl stop geonature
    $ sudo systemctl stop geonature-worker
    $ sudo systemctl stop usershub
    $ cd frontend
    $ nvm use
    $ npm run build
    $ sudo systemctl start geonature
    $ sudo systemctl start geonature-worker
    $ sudo systemctl start usershub


Si cela n’est pas suffisant, vous pouvez également essayer de rajouter du swap à votre machine.
Les commandes ci-dessous permettent de créer un fichier de swap de 4G (https://stackoverflow.com/questions/26193654/node-js-catch-enomem-error-thrown-after-spawn):

.. code-block:: console

    $ sudo fallocate -l 4G /swapfile  # Create a 4 gigabyte swapfile
    $ sudo chmod 600 /swapfile  # Secure the swapfile by restricting access to root
    $ sudo mkswap /swapfile  # Mark the file as a swap space
    $ sudo swapon /swapfile  # Enable the swap


.. warning:: Au redémarrage de la machine, il faudra réactiver le swap en exécutant à nouveau la dernière commande, à moins de rajouter une entrée dans votre fichier ``/etc/fstab``.

- **Problème d'affichage du Frontend**

Si vous rencontrez des problèmes de librairies Frontend qui n'ont pas bien été installées ou non accessibles, vous pouvez les réinstaller

- Réinstaller les dépendances du Frontend : Dans le répertoire frontend, lancez la commande ``npm ci``
- Reconstruire le Frontend : Dans le répertoire frontend, lancez la commande ``npm run build``

Problèmes liés à la BDD
-----------------------

* Après un redémarrage de PostgreSQL (``sudo service postgresql restart``), celle-ci ne sera plus accessible par l'application et si vous tentez de vous connecter, vous aurez un message du type ``LoginError``. Cela est lié au fait que lorsqu'on redémarre PostgreSQL, il faut aussi relancer les API de GeoNature, car cela génère des erreurs de transaction et de session entre l'API et PostgreSQL.

Donc à chaque ``sudo systemctl restart postgresql``, lancer un ``sudo systemctl restart geonature``
