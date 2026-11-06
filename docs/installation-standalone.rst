Installation de GeoNature uniquement
************************************

Cette procédure détaille l’installation de GeoNature (incluant TaxHub) sans UsersHub.
Pour une installation automatisée, voir :ref:`installation-python`. UsersHub s'installe séparément (voir sa `documentation <https://usershub.readthedocs.io>`_).

Installation des dépendances
----------------------------

Installer les paquets suivants :

.. code:: shell  
    
  sudo apt install unzip git postgresql-postgis postgis python3-pip python3-venv python3-dev libpq-dev libgdal-dev libffi-dev libpangocairo-1.0-0 apache2 redis


Récupération de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas)

* Cloner le dépôt à la version voulue (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnX-SI/GeoNature/releases>`_) :

  .. code:: shell

    git clone --branch X.Y.Z https://github.com/PnX-SI/GeoNature geonature
    cd geonature
    git submodule update --init --recursive

* Copier puis mettre à jour le fichier de configuration (``install/install.toml``) comportant les informations relatives à votre environnement serveur :

  .. code:: shell

    cp install/install.sample.toml install/install.toml
    nano install/install.toml

  Le paramètre ``url_application_prefix_path`` permet de choisir le préfixe d'URL dès la 1ère installation :
  ``geonature`` (défaut), ``saisie`` ou vide pour servir à la racine ``/``.


Installation de l'application
-----------------------------

L'installation s'exécute étape par étape avec ``install/install.py`` (voir :ref:`installation-python`) :

.. code:: shell

  python3 install/install.py --config install/install.toml --only apt        # paquets système
  python3 install/install.py --config install/install.toml --only nvm        # Node (nvm)
  python3 install/install.py --config install/install.toml --only backend    # virtualenv (uv), dépendances et backend
  python3 install/install.py --config install/install.toml --only systemd    # services geonature et geonature-worker, logrotate
  python3 install/install.py --config install/install.toml --only database   # rôle, base, extensions, schémas et données métiers
  python3 install/install.py --config install/install.toml --only modules    # Occtax, Occhab, Validation (si activés), supergrant
  python3 install/install.py --config install/install.toml --only frontend   # configuration, dépendances npm, build, config.json
  python3 install/install.py --config install/install.toml --only apache     # configuration Apache
  python3 install/install.py --config install/install.toml --only services   # démarrage des services

Sans ``--only``, toutes les étapes non terminées sont exécutées dans cet ordre. ``--reset-state`` rejoue une étape déjà faite.

Vous pouvez alors démarrer le backend de GeoNature : ``sudo systemctl start geonature``

Configuration Apache
--------------------

* L'étape ``apache`` de ``install/install.py`` copie le fichier de configuration de référence ``install/assets/geonature_apache.conf``, le place dans ``/etc/apache2/conf-available/geonature.conf`` et remplace ses variables à partir de votre configuration de GeoNature.

  Rejouez cette étape (``--reset-state --only apache``) si vous changez l'URL de votre GeoNature ou les paramètres liés aux chemins et URL des fichiers statiques et des médias.

* Créez la configuration du vhost, incluant la configuration par défaut créée précédemment :

  .. code:: shell

    sudo cp install/assets/vhost_apache.conf /etc/apache2/sites-available/geonature.conf # Copier le vhost
    sudo nano /etc/apache2/sites-available/geonature.conf # Modifier la variable ``${DOMAIN_NAME}``

* Activez la nouvelle configuration :

  .. code:: shell

    sudo a2ensite geonature.conf

* et redémarrez Apache :

  .. code:: shell

    sudo systemctl reload apache2

* L'application est disponible à l'adresse suivante : http://monurl.fr/geonature

Une page HTML de maintenance et un vhost dédié sont aussi disponibles. Pour les mettre en place :

.. code:: shell
  
  sudo cp install/assets/vhost_apache_maintenance.conf /etc/apache2/sites-available/geonature_maintenance.conf # Copier le vhost
  sudo nano /etc/apache2/sites-available/geonature_maintenance.conf # Modifier la variable ``${DOMAIN_NAME}``
  sudo cp install/assets/maintenance.html /var/www/geonature_maintenance/index.html

Pour passer votre GeoNature en maintenance, vous pouvez alors désactiver le vhost de GeoNature et activer celui de la page de maintenance : 

.. code:: shell

  sudo a2dissite geonature.conf
  sudo a2ensite geonature_maintenance.conf

Dépendances
-----------

Lors de l'installation de la BDD (étape ``database``), le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

UsersHub n'est pas nécessaire au fonctionnement de GeoNature mais il sera utile pour avoir une interface de gestion des utilisateurs, des groupes et de leurs droits. 

TaxHub v2 est intégré à GeoNature depuis sa version 2.15.0

Voir la documentation de TaxHub : https://taxhub.readthedocs.io/

Voir la doc d'installation de UsersHub : https://usershub.readthedocs.io/


Passer en mode développement
----------------------------

.. Note::
    Consultez le guide :ref:`mode-dev` de GeoNature.
