Installation globale
********************

Ce document décrit une procédure d'installation packagée de GeoNature.

En lançant le script d'installation ci-dessous, l'application GeoNature ainsi que ses dépendances seront installées sur un seul et même serveur au sein d'une seule base de données.

Les applications suivantes seront installées :

- `GeoNature <https://github.com/PnX-SI/GeoNature>`_ (incluant `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui pilote le schéma ``taxonomie``)
- `UsersHub <https://github.com/PnX-SI/UsersHub>`_ qui pilote le schéma ``utilisateurs`` (le paramètre ``install_usershub_app`` du fichier de configuration ``install_all.ini`` permet de désactiver l'installation de l'application. Il est cependant recommandé d'installer l'application pour disposer d'une interface pour gérer les utilisateurs dans GeoNature)

Si vous disposez déjà de UsersHub sur un autre serveur ou une autre base de données et que vous souhaitez installer simplement GeoNature, veuillez suivre la documentation :ref:`installation-standalone`.


Installation des applications
-----------------------------

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur dédié précédemment créé lors de l’étape de :ref:`preparation-server` (usuellement ``geonatureadmin``).

Téléchargement
^^^^^^^^^^^^^^
* Se placer à la racine du ``home`` de l'utilisateur puis récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Ces scripts installent les applications GeoNature (incluant TaxHub) et UsersHub (en option) ainsi que leurs bases de données (uniquement les schémas du coeur) :
 
  .. code:: console

    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.ini
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.sh

.. warning::
  
  Le script ``install_all.sh`` lit ``install_all.ini`` dans le répertoire courant.
  Placez ces 2 fichiers dans le même dossier avant exécution.
	

Configuration
^^^^^^^^^^^^^

* Configurez votre installation en adaptant le fichier ``install_all.ini`` :
 
  .. code:: console
    
    nano install_all.ini

* Renseignez à minima :

  * ``my_url`` : l'URL (ou IP) de votre serveur (avec un ``/`` à la fin)
  * ``user_pg`` : l'utilisateur PostgreSQL que vous souhaitez voir créé
  * ``user_pg_pass`` : mot de passe de l'utilisateur PostgreSQL
  * ``install_root_dir`` : racine d'installation des applications (recommandé : ``/opt``)
  * ``app_user`` / ``app_group`` : utilisateur et groupe propriétaires des dossiers applicatifs (laisser vide pour utiliser l'utilisateur courant)
  
  Le script se chargera d'installer PostgreSQL, de crééer la base de donnée et de créer l'utilisateur que vous avez renseigné. 
  Les répertoires d'installation effectifs sont ``geonature_dir`` et ``usershub_dir`` (déduits de ``install_root_dir`` par défaut).
  NVM est installé en partagé système dans ``/usr/local/nvm`` par ``00_install_nvm.sh``.

* Variable ``mode``

Pour l'installation d'une instance de production ou de test ``mode=prod``, pour une installation de développement ``mode=dev``.

**Il est déconseillé de modifier les numéros de version des dépendances, chaque nouvelle version de GeoNature étant fournie avec les versions adaptées de ses dépendances.**

Installation
^^^^^^^^^^^^^

Lancer l'installation à l'aide des commandes suivantes :
 
.. code:: shell

  touch install_all.log
  chmod +x install_all.sh
  ./install_all.sh 2>&1 | tee install_all.log

Une fois l'installation terminée, lancez la commande suivante:

.. code:: shell

    exec bash


Les applications sont disponibles aux adresses suivantes :

- http://monip.com/geonature/
- http://monip.com/usershub/ (en option)

Vous pouvez vous connecter avec l'utilisateur intégré par défaut (admin/admin).

.. note::

    Pour en savoir plus TaxHub, sa configuration et son utilisation, reportez-vous à sa documentation : https://taxhub.readthedocs.io. Idem pour UsersHub et sa documentation : https://usershub.readthedocs.io
    
.. note::

    * GeoNature-atlas compatible avec GeoNature V2 est disponible sur https://github.com/PnX-SI/GeoNature-atlas
    * Vous pouvez utiliser le schéma ``ref_geo`` de GeoNature pour votre territoire, les communes et les mailles.
    
Si vous rencontrez une erreur, se reporter aux fichiers de logs ``/home/`whoami`/install_all.log``.

.. note::

    Si vous souhaitez que GeoNature soit à la racine du serveur, ou à une autre adresse, editez le fichier de configuration Apache (``/etc/apache2/sites-available/geonature.conf``) en modifiant l'alias :

    - Pour ``/``: ``Alias / /opt/geonature/frontend/dist``
    - Pour ``/saisie`` : ``Alias /saisie /opt/geonature/frontend/dist``

.. note::

    Par défaut et par mesure de sécurité, la base de données est accessible uniquement localement par la machine où elle est installée. Pour accéder à la BDD depuis une autre machine (pour s'y connecter avec QGIS, pgAdmin ou autre), vous pouvez consulter cette documentation https://github.com/PnX-SI/Ressources-techniques/blob/master/PostgreSQL/acces-bdd.rst.
    Attention, exposer la base de données sur internet n'est pas recommandé. Il est préférable de se connecter via un tunnel SSH. QGIS et la plupart des outils d'administration de base de données permettent d'établir une connexion à la base de cette manière.
    Attention si vous redémarrez PostgreSQL (``sudo service postgresql restart``), il faut ensuite redémarrer les API de GeoNature et UsersHub :

    .. code:: shell

        sudo systemctl restart geonature
        sudo systemctl restart geonature-worker
        sudo systemctl restart usershub

.. note::

    Il est aussi important de configurer l'accès au serveur en HTTPS plutôt qu'en HTTP pour chiffrer le contenu des échanges entre le navigateur et le serveur (https://docs.ovh.com/fr/hosting/les-certificats-ssl-sur-les-hebergements-web/).
