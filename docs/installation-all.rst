Installation globale
********************

Ce document décrit une procédure d'installation packagée de GeoNature.

En lançant le script d'installation ci-dessous, l'application GeoNature ainsi que ses dépendances seront installées sur un seul et même serveur au sein d'une seule base de données.

Les applications suivantes seront installées :

- `GeoNature <https://github.com/PnX-SI/GeoNature>`_
- `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui pilote le schéma ``taxonomie``
- `UsersHub <https://github.com/PnX-SI/UsersHub>`_ qui pilote le schéma ``utilisateurs`` (le paramètre ``install_usershub_app`` du fichier de configuration ``install_all.ini`` permet de désactiver l'installation de l'application. Il est cependant recommandé d'installer l'application pour disposer d'une interface pour gérer les utilisateurs dans GeoNature)

Si vous disposez déjà de Taxhub ou de UsersHub sur un autre serveur ou une autre base de données et que vous souhaitez installer simplement GeoNature, veuillez suivre la documentation :ref:`installation-standalone`.


Installation de l'application
-----------------------------

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur dédié précédemment créé lors de l’étape de :ref:`preparation-server` (usuellement ``geonatureadmin``).

* Se placer à la racine du ``home`` de l'utilisateur puis récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Ces scripts installent les applications GeoNature, TaxHub et UsersHub (en option) ainsi que leurs bases de données (uniquement les schémas du coeur) :
 
::

    $ wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.ini
    $ wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.sh

*Attention* : l'installation globale fonctionne uniquement si les scripts sont placés à la racine du ``home`` de l'utilisateur courant.	
	
* Configurez votre installation en adaptant le fichier ``install_all.ini`` :
 
::
    
    nano install_all.ini

Renseignez à minima votre utilisateur linux, l'URL (ou IP) de votre serveur (avec un ``/`` à la fin) ainsi que l'utilisateur PostgreSQL que vous souhaitez et son mot de passe. Le script se chargera d'installer PostgreSQL et de créer l'utilisateur de base de données que vous avez renseigné.

Pour la définition des numéros de version des dépendances, voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances. Il est déconseillé de modifier ces versions, chaque nouvelle version de GeoNature étant fournie avec les versions adaptées de ses dépendances.

* Lancer l'installation :
 
::

    touch install_all.log
    chmod +x install_all.sh
    ./install_all.sh 2>&1 | tee install_all.log

Une fois l'installation terminée, lancez la commande suivante:

::

    exec bash


Les applications sont disponibles aux adresses suivantes :

- http://monip.com/geonature/
- http://monip.com/taxhub/
- http://monip.com/usershub/ (en option)

Vous pouvez vous connecter avec l'utilisateur intégré par défaut (admin/admin).

:Note:

    Pour en savoir plus TaxHub, sa configuration et son utilisation, reportez-vous à sa documentation : https://taxhub.readthedocs.io. Idem pour UsersHub et sa documentation : https://usershub.readthedocs.io
    
:Note:

    * GeoNature-atlas compatible avec GeoNature V2 est disponible sur https://github.com/PnX-SI/GeoNature-atlas
    * Vous pouvez utiliser le schéma ``ref_geo`` de GeoNature pour votre territoire, les communes et les mailles, si vous les avez intégré dans ``ref_geo.l_areas`` au préalable.
    
:Note:

    Une version expérimentale du calcul automatique de la sensibilité est disponible : https://github.com/PnX-SI/GeoNature/issues/284

Si vous rencontrez une erreur, se reporter aux fichiers de logs :

- Logs de l'installation de la base de données : ``/home/`whoami`/geonature/var/log/install_db.log``
- Log général de l'installation de l'application : ``/home/`whoami`/install_all.log``


Si vous souhaitez que GeoNature soit à la racine du serveur, ou à une autre adresse, editez le fichier de configuration Apache (``/etc/apache2/sites-available/geonature.conf``) en modifiant l'alias :

- Pour ``/``: ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie`` : ``Alias /saisie /home/test/geonature/frontend/dist``

:Note:

    Par défaut et par mesure de sécurité, la base de données est accessible uniquement localement par la machine où elle est installée. Pour accéder à la BDD depuis une autre machine (pour s'y connecter avec QGIS, pgAdmin ou autre), vous pouvez consulter cette documentation https://github.com/PnX-SI/Ressources-techniques/blob/master/PostgreSQL/acces-bdd.rst. Attention si vous redémarrez PostgreSQL (``sudo service postgresql restart``), il faut ensuite redémarrer les API de GeoNature, UsersHub et TaxHub (``sudo systemctl restart geonature.service``, ``sudo systemctl restart usershub.service`` et ``sudo systemctl restart taxhub.service``). Attention, exposer la base de données sur internet n'est pas recommandé. Il est préférable de se connecter via un tunnel SSH. QGIS et la plupart des outils d'administration de base de données permettent d'établir une connexion à la base de cette manière.

:Note:

    Il est aussi important de configurer l'accès au serveur en HTTPS plutôt qu'en HTTP pour chiffrer le contenu des échanges entre le navigateur et le serveur (https://docs.ovh.com/fr/hosting/les-certificats-ssl-sur-les-hebergements-web/).


Installation d'un module GeoNature
----------------------------------

L'installation de GeoNature n'est livrée qu'avec les schémas de base de données et les modules du coeur (NB : les modules Occtax, Occhab et Validation sont fournis par défaut). Pour ajouter un gn_module externe, il est nécessaire de l'installer :

**1.** Téléchargez le module depuis son dépôt Github puis dézippez-le dans le repertoire utilisateur, au même niveau que le dossier ``geonature``.

::

    cd /home/`whoami`

**2.** Renseignez l'éventuel fichier ``config/settings.ini`` du module.

**3.** Installez le module. Rendez-vous dans le répertoire ``backend`` de GeoNature et activez le virtualenv pour rendre disponible les commandes GeoNature :

::

    source venv/bin/activate

Lancez ensuite la commande ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>``

Le premier paramètre est l'emplacement absolu du module sur votre serveur et le deuxième est le chemin derrière lequel on accédera au module dans le navigateur.

Exemple pour un module Import :

::

    geonature install_gn_module /home/`whoami`/gn_module_import import

Le module sera disponible à l'adresse ``http://mon-geonature.fr/geonature/#/import``

L'API du module sera disponible à l'adresse ``http://mon-geonature.fr/api/import``

Cette commande exécute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend

**4.** Complétez l'éventuelle configuration du module (``config/conf_gn_module.toml``) à partir des paramètres présents dans ``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les valeurs par défaut. Puis relancez la mise à jour de la configuration (depuis le répertoire ``geonature/backend`` et une fois dans le venv (``source venv/bin/activate``) : ``geonature update_module_configuration nom_du_module``)

**5.** Re-build du frontend :

::

    cd frontend
    nvm use
    npm run build
