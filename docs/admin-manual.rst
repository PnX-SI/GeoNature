MANUEL ADMINISTRATEUR
=====================

Architecture
------------

GeoNature possède une architecture modulaire et s'appuie sur plusieurs "services" indépendants pour fonctionner :

- UsersHub et son sous-module d'authentification Flask (https://github.com/PnX-SI/UsersHub-authentification-module) sont utilisés pour gérer le schéma de BDD ``ref_users`` (actuellement nommé ``utilisateurs``) et l'authentification. UsersHub permet une gestion centralisée de ses utilisateurs (listes, organismes, droits), utilisable par les différentes applications de son système d'information.
- TaxHub (https://github.com/PnX-SI/TaxHub) est utilisé pour la gestion du schéma de BDD ``ref_taxonomy`` (actuellement nommé ``taxonomie``). L'API de TaxHub est utilisée pour récupérer des informations sur les espèces et la taxonomie en générale.
- Un sous-module Flask (https://github.com/PnX-SI/Nomenclature-api-module/) a été créé pour une gestion centralisée des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module/), il pilote le schéma ``ref_nomenclature``.
- ``ref_geo`` est le schéma de base de données qui gère le référentiel géographique. Il est utilisé pour gérer les zonages, les communes, le calcul automatique d'altitude et les intersections spatiales.

GeoNature a également une séparation claire entre le backend (API: intéraction avec la base de données) et le frontend (interface utilisateur). Le backend peut être considéré comme un "service" dont se sert le frontend pour récupérer ou poster des données. 
NB: Le backend en le frontend se lancent séparement dans GeoNature.

.. image :: http://geonature.fr/docs/img/admin-manual/design-geonature.png

Base de données
---------------

Dans la continuité de sa version 1, GeoNature V2 utilise le SGBD PostgreSQL et sa cartouche spatiale PostGIS. Cependant l'architecture du modèle de données a été complétement revue.

La base de données a notemment été refondue pour s'appuyer au maximum sur des standards, comme le standard d'Occurrences de Taxon du MNHN (Voir https://github.com/PnX-SI/GeoNature/issues/183).

La base de données a également été traduite en Anglais et supporte désormais le multilangue.

Les préfixes des schémas de BDD sont désormais standardisés : ``ref_`` concerne les référentiels externes, ``gn`` concerne les schémas du coeur de GeoNature et ``pr`` les schémas des protocoles. 

Autres standards:

- Noms de tables, commentaires et fonctions en anglais
- Pas de nom de table dans les noms de champs
- Nom de schema éventuellement dans nom de table

Schéma simplifié de la BDD : 

.. image :: http://geonature.fr/docs/img/admin-manual/GN-schema-BDD.jpg

- En jaune, les schémas des réferentiels.
- En rose, les schémas du coeur de GeoNature
- En bleu, les schémas des protocoles et sources de données
- En vert, les schémas des applications pouvant interagir avec le coeur de GeoNature

Modèle simplifié de la BDD (2017-12-15) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/2017-12-15-GN2-MCD-simplifie.jpg

Dernière version complète de la base de données (2018-03-19), à mettre à jour : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/2018-03-19-GN2-MCD.png

Désolé pour les relations complexes entre tables...

Gestion des droits :
""""""""""""""""""""

La gestion des droits est centralisée dans UsersHub. Dans la version 1 de GeoNature, il était possible d'attribuer des droits selon 6 niveaux à des rôles (utilisateurs ou groupes). Pour la version 2 de GeoNature, des évolutions ont été réalisées pour étendre les possibilités d'attribution de droits et les rendre plus génériques. 

Pour cela un système d'étiquettes (``utilisateurs.t_tags``) a été mis en place. Il permet d'attribuer des étiquettes génériques à des rôles (utilisateurs ou groupes d'utilisateurs). 

- Dans GeoNature V2 cela permet d'attribuer des actions possibles à un rôle sur une portée dans une application ou un module (définis dans ``utilisateurs.cor_app_privileges``).
- 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
- Une vue permet de retourner toutes les actions, leur portée et leur module de GeoNature pour tous les rôles (``utilisateurs.v_usersaction_forall_gn_modules``)
- Des fonctions PostgreSQL ont aussi été intégrées pour faciliter la récupération de ces informations (``utilisateurs.cruved_for_user_in_module``, ``utilisateurs.can_user_do_in_module``, ...)
- Une hiérarchie a été rendue possible entre applications et entre organismes pour permettre un système d'héritage
- Si un utilisateur n'a aucune action possible sur un module, alors il ne lui sera pas affiché et il ne pourra pas y accéder
- Il est aussi possible de ne pas utiliser UsersHub pour gérer les utilisateurs et de connecter GeoNature à un CAS (voir configuration). Actuellement ce paramétrage est fonctionnel en se connectant au CAS de l'INPN (MNHN)

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/schema_cruved.png


Nomenclatures :
"""""""""""""""

- Toutes les listes déroulantes sont gérées dans une table générique ``ref_nomenclatures.t_nomenclatures``
- Elles s'appuient sur les nomenclatures du SINP (http://standards-sinp.mnhn.fr/nomenclature/) qui peuvent être désactivées ou completées
- Chaque nomenclature est associée à un type et une vue par type de nomenclature a été ajoutée pour simplifier leur usage 
- Ces nomenclatures sont gérées dans un sous-module pour pouvoir les réutiliser (ainsi que leur mécanisme) dans d'autres applications : https://github.com/PnX-SI/Nomenclature-api-module/
- Les id des nomenclatures et des types de nomenclature sont des serial et ne sont pas prédéfinis lors de l'installation, ni utilisées en dur dans le code des applications. En effet, les nomenclatures peuvent varier en fonction des structures. On utilise le cd_nomenclature et le mnémonique du type de nomenclature pour retrouver dynamiquement l'id_nomenclature d'une nomenclature. C'est cependant cet id qu'on stocke au niveau des données pour garantir l'intégrité référentielle
- Chaque nomenclature peut être associée à un règne ou un group2inpn (``ref_nomenclatures.cor_taxref_nomenclature``) pour proposer des nomenclatures correspondants à un taxon
- Les valeurs par défaut sont définies dans chaque module
- Pour OccTax c'est dans ``pr_occtax.defaults_nomenclatures_value``. Elles peuvent être définies pour chaque type de nomenclature ainsi que par organisme, règne et/ou group2inpn
- Si organisme = 0 alors la valeur par défaut s'applique à tous les organismes. Idem pour les règnes et group2inpn
- La fonction ``pr_occtax.get_default_nomenclature_value`` permet de renvoyer l'id de la nomenclature par défaut
- Ces valeurs par défaut sont aussi utilisées pour certains champs qui sont cachés (statut_observation, floutage, statut_validation...) mais ne sont donc pas modifiables par l'utilisateur
- Il existe aussi une table pour définir des valeurs par défaut générales de nomenclature (``ref_nomenclatures.defaults_nomenclatures_value``)

Métadonnées :
"""""""""""""

- Elles sont gérées dans le schéma ``gn_meta`` basé sur le standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/)
- Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles

Données SIG :
"""""""""""""

- Le schéma ``ref_geo`` permet de gérer les données SIG (zonages, communes, MNT...) de manière centralisée, potentiellement partagé avec d'autres BDD
- Il contient une table des zonages, des types de zonages, des communes, des grilles (mailles) et un MNT raster ou vectorisé (https://github.com/PnX-SI/GeoNature/issues/235)
- La fonction ``ref_geo.fct_get_area_intersection`` permet de renvoyer les zonages intersectés par une observation en fournissant sa géométrie
- La fonction ``ref_geo.fct_get_altitude_intersection`` permet de renvoyer l'altitude min et max d'une observation en fournissant sa géométrie
- L'intersection d'une observation avec les zonages sont stockés au niveau de la synthèse (``gn_synthese.cor_area_synthese``) et pas de la donnée source pour alléger et simplifier leur gestion

Fonctions : 
"""""""""""

La base de données contient de nombreuses fonctions.

**gn_synthese**

+--------------------------------------+-------------------------------+----------------------+----------------------------------------+
| Fonction                             | Paramètres                    | Résultat             | Description                            |
+======================================+===============================+======================+========================================+
| get_default_nomenclature_value       | id_type_nomenclature,         | Entier               | Function that return the default       |
|                                      | idorganism, regne, group2inpn |                      | nomenclature id with a nomenclature    |
|                                      |                               |                      | type, organism id, regne, group2_inpn  |
+--------------------------------------+-------------------------------+----------------------+----------------------------------------+
| fct_trig_insert_in_cor_area_synthese | geom                          | Trigger              | Trigger intersectant la géométrie      |
|                                      |                               |                      | d'une observation avec tous les zonages|
+--------------------------------------+-------------------------------+----------------------+----------------------------------------+

**ref_geo**

.. code:: sql

  ref_geo.fct_get_altitude_intersection(IN mygeom geometry)
  -- Fonction qui retourne l'altitude min et max de la géométrie passée en paramètre
  
.. code:: sql

  ref_geo.fct_get_area_intersection(
    IN mygeom geometry,
    IN myidtype integer DEFAULT NULL::integer)
  RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying)
  -- Fonction qui retourne un tableau des zonages (id_area) intersectant la géométrie passée en paramètre

.. code:: sql

  ref_geo.get_id_area_type(mytype character varying) RETURNS integer
  --Function which return the id_type_area from the type_code of an area type

**pr_occtax**

.. code:: sql

  pr_occtax.get_id_counting_from_id_releve(my_id_releve integer) RETURNS integer[]
  -- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)

.. code:: sql

  get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
  --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inp  --Return -1 if nothing matche with given parameters

.. code:: sql

  pr_occtax.insert_in_synthese(my_id_counting integer) RETURNS integer[]

**ref_nomenclatures**

.. code:: sql

  get_id_nomenclature_type(mytype character varying) RETURNS integer
  --Function which return the id_type from the mnemonique of a nomenclature type

.. code:: sql

  get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0) RETURNS integer
  --Function that return the default nomenclature id with wanteds nomenclature type (mnemonique), organism id
  --Return -1 if nothing matche with given parameters

.. code:: sql

  check_nomenclature_type_by_mnemonique(id integer , mytype character varying) RETURNS boolean
  --Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)

.. code:: sql

  check_nomenclature_type_by_cd_nomenclature(mycdnomenclature character varying , mytype character varying) 
  --Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)

.. code:: sql

  check_nomenclature_type_by_id(id integer, myidtype integer) RETURNS boolean
  --Function that checks if an id_nomenclature matches with wanted nomenclature type (use id_type)

.. code:: sql

  get_id_nomenclature(
  mytype character varying,
  mycdnomenclature character varying)
  RETURNS integer
  --Function which return the id_nomenclature from an mnemonique_type and an cd_nomenclature

.. code:: sql

  get_nomenclature_label(
  myidnomenclature integer,
  mylanguage character varying
  )
  RETURNS character varying
  --Function which return the label from the id_nomenclature and the language

.. code:: sql

  get_cd_nomenclature(myidnomenclature integer) RETURNS character varying
  --Function which return the cd_nomenclature from an id_nomenclature

.. code:: sql

  get_filtered_nomenclature(mytype character varying, myregne character varying, mygroup character varying)
  RETURNS SETOF integer
  --Function that returns a list of id_nomenclature depending on regne and/or group2_inpn sent with parameters.

.. code:: sql

  calculate_sensitivity(
  mycdnom integer,
  mynomenclatureid integer)
  RETURNS integer
  --Function to return id_nomenclature depending on observation sensitivity
  --USAGE : SELECT ref_nomenclatures.calculate_sensitivity(240,21);


A compléter... A voir si on mentionne les triggers ou pas...

Modularité
----------

Chaque module doit avoir son propre schéma dans la BDD, avec ses propres fichiers SQL de création comme le module OccTax : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/data

Côté Backend, chaque module a aussi son modèle et ses routes : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/backend

Idem côté Frontend, où chaque module a sa configuration et ses composants : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/frontend/app

Mais en pouvant utiliser des composants du Coeur comme expliqué dans la documentation Developpeur.

Plus d'infos sur le développement d'un module : https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9velopper-et-installer-un-gn_module


Configuration
-------------

Pour configurer GeoNature, actuellement il y a : 

- Une configuration pour l'installation : ``config/settings.ini``
- Une configuration globale de l'application : ``<GEONATURE_DIRECTORY>/config/geonature_config.toml`` (générée lors de l'installation de GeoNature)
- Une configuration par module : ``<GEONATURE_DIRECTORY>/external_modules/<nom_module>/config/conf_gn_module.toml`` (générée lors de l'instalation d'un module)
- Une table ``gn_commons.t_parameters`` pour des paramètres gérés dans la BDD

.. image :: http://geonature.fr/docs/img/admin-manual/administration-geonature.png

Configuration générale de l'application
"""""""""""""""""""""""""""""""""""""""

L'installation de GeoNature génère le fichier de configuration globale ``<GEONATURE_DIRECTORY>/config/geonature_config.toml``. Ce fichier est aussi copié dans le frontend (``frontend/conf/app.config.ts``), à ne pas modifier.

Par défaut, le fichier ``<GEONATURE_DIRECTORY>/config/geonature_config.toml`` est minimaliste et généré à partir des infos présentes dans le fichier ``config/settings.ini``.

Il est possible de le compléter en surcouchant les paramètres présents dans le fichier ``config/default_config.toml.example``.

A chaque modification du fichier global de configuration (``<GEONATURE_DIRECTORY>/config/geonature_config.toml``), il faut regénérer le fichier de configuration du frontend.

Ainsi après chaque modification des fichiers de configuration globale, placez-vous dans le backend de GeoNature (``/home/monuser/GeoNature/backend``) et lancez les commandes : 

::

    source venv/bin/activate
    geonature update_configuration
    deactivate

Configuration d'un gn_module
""""""""""""""""""""""""""""

Lors de l'installation d'un module, un fichier de configuration est créé : ``<MODULE_DIRECTORY>/config/conf_gn_module.toml``.

Comme pour la configuration globale, ce fichier est minimaliste et peut être surcouché. Le fichier ``conf_gn_module.toml.example``, situé dans le répertoire ``config`` du module, décrit l'ensemble des variables de configuration disponibles ainsi que leurs valeurs par défaut.

A chaque modification de ce fichier, lancer les commandes suivantes depuis le backend de GeoNature (``/home/monuser/GeoNature/backend``). Le fichier est copié à destination du frontend ``<nom_module>/frontend/app/module.config.ts``, qui est alors recompilé automatiquement.

::

    source venv/bin/activate
    geonature update_module_configuration <NOM_DE_MODULE>
    deactivate

Exploitation
------------

Logs
""""

Les logs de GeoNature sont dans le répertoire ``<GEONATURE_DIRECTORY>/var/log/`` :

- Logs d'installation de la BDD : ``install_db.log``
- Logs d'installation de la BDD d'un module : ``install_<nom_module>_schema.log``
- Logs de l'API : ``gn-errors.log``

Les logs de TaxHub sont dans le repertoire ``/var/log/taxhub``:

- Logs de l'API de TaxHub : ``taxhub-errors.log``

Commandes GeoNature 
"""""""""""""""""""

GeoNature est fourni avec une série de commandes pour administrer l'application.
Pour les exécuter, il est nécessaire d'être dans le virtualenv python de GeoNature

::

    cd <GEONATURE_DIRECTORY>/backend
    source venv/bin/activate

Le préfixe (venv) se met alors au début de votre invite de commande.

Voici la liste des commandes disponible (aussi disponible en tapant la commande ``geonature --help``) :

- activate_gn_module : Active un gn_module installé (Possibilité d'activer seulement le backend ou le frontend)
- deactivate_gn_module : Désactive gn_un module activé (Possibilté de désactiver seulement le backend ou le frontend)
- dev_back : Lance le backend en mode développement
- dev_front : Lance le frontend en mode développement
- generate_frontend_module_route : Génère ou regénère le fichier de routing du frontend en incluant les gn_module installés (Fait automatiquement lors de l'installation d'un module)
- install_gn_module : Installe un gn_module 
- start_gunicorn : Lance l'API du backend avec gunicorn
- supervisor : Exécute les commandes supervisor (``supervisor stop <service>``, ``supervisor reload``)
- update_configuration : Met à jour la configuration du coeur de l'application. A exécuter suite à un modification du fichier ``geonature_config.toml``
- update_module_configuration : Met à jour la configuration d'un module. A exécuter suite à une modification du fichier ``conf_gn_module.toml``.

Effectuez ``geonature <nom_commande> --help`` pour accéder à la documentation et à des exemples d'utilisation de chaque commande.

Verification des services
"""""""""""""""""""""""""

Les API de GeoNature et de TaxHub sont lancées par deux serveurs http python indépendants (Gunicorn), eux-mêmes controlés par le supervisor.

Par défaut :

- L'API de GeoNature tourne sur le port 8000
- L'API de taxhub tourne sur le port 5000

Pour vérifier que les API de GeoNature et de TaxHub sont lancées, exécuter la commande :

::

    ps -aux |grep gunicorn

La commande doit renvoyer 4 fois la ligne suivante pour GeoNature :

::

    root      27074  4.6  0.1  73356 23488 ?        S    17:35   0:00       /home/theo/workspace/GN2/GeoNature/backend/venv/bin/python3 /home/theo/workspace/GN2/GeoNature/backend/venv/bin/gunicorn wsgi:app --error-log /var/log/geonature/api_errors.log --pid=geonature2.pid -w 4 -b 0.0.0.0:8000 -n geonature2

et 4 fois la ligne suivante pour TaxHub :

::

    root      27103 10.0  0.3 546188 63328 ?        Sl   17:35   0:00 /home/theo/workspace/GN2/TaxHub/venv/bin/python3.5 /home/theo/workspace/GN2/TaxHub/venv/bin/gunicorn server:app --access-logfile /var/log/taxhub/taxhub-access.log --error-log /var/log/taxhub/taxhub-errors.log --pid=taxhub.pid -w 4 -b 0.0.0.0:5000 -n taxhub
    
Chaque ligne correspond à un worker Gunicorn.

Si ces lignes n'apparaissent pas, cela signigie qu'une des deux API n'a pas été lancée ou a connu un problème à son lancement. Voir les logs des API pour plus d'informations.

Supervision des services
""""""""""""""""""""""""

- Vérifier que les applications GeoNature et TaxHub sont accessibles en http
- Vérifier que leurs services (API) sont lancés et fonctionnent correctement (tester les deux routes ci-dessous).

  - Exemple de route locale pour tester l'API GeoNature : http://127.0.0.1:8000/occtax/defaultNomenclatures qui ne doit pas renvoyer de 404. URL absolue : https://urlgeonature/api/occtax/defaultNomenclatures
  - Exemple de route locale pour tester l'API TaxHub : http://127.0.0.1:5000/api/taxref/regnewithgroupe2 qui ne doit pas renvoyer de 404. URL absolue : https://urltaxhub/api/taxref/regnewithgroupe2
    
- Vérifier que les fichiers de logs de TaxHub et GeoNature ne sont pas trop volumineux pour la capacité du serveur
- Vérifier que les services nécessaires au fonctionnement de l'application tournent bien (Apache, PostgreSQL)

Stopper/Redémarrer les API
"""""""""""""""""""""""""""

Les API de GeoNature et de TaxHub sont gérées par le supervisor pour être lancées automatiquement au démarrage du serveur.

Pour les stopper, exécuter les commandes suivantes :

- GeoNature : ``sudo supervisorctl stop geonature2``
- TaxHub : ``sudo supervisorctl stop taxhub``

Pour redémarer les API :

::

    sudo supervisorctl reload

Maintenance
"""""""""""

Lors d'une opération de maintenance (montée en version, modification de la base de données...), vous pouvez rendre l'application momentanémment indisponible.

Pour cela, désactivez la configuration Apache de GeoNature, puis activez la configuration du mode de maintenance :

::

    sudo a2dissite geonature
    sudo a2ensite geonature_maintenance
    sudo apachectl restart

A la fin de l'opération de maintenance, effectuer la manipulation inverse :

::

    sudo a2dissite geonature_maintenance     
    sudo a2ensite geonature
    sudo apachectl restart
    
Attention : ne pas stopper le backend (des opérations en BDD en cours pourraient être corrompues)


- Redémarrage de PostgreSQL

  Si vous effectuez des manipulations de PostgreSQL qui nécessitent un redémarrage du SGBD (``sudo service postgresql restart``), il faut impérativement lancer un redémarrage des API GeoNature et TaxHub pour que celles-ci continuent de fonctionner. Pour cela, lancez la commande ``sudo supervisorctl reload``. 
  
  **NB**: Ne pas faire ces manipulations sans avertir les utilisateurs d'une perturbation temporaire des applications.


Sauvegarde et restauration
--------------------------

Sauvegarde
""""""""""

* Sauvegarde de la base de données :

Les sauvegardes de la BDD sont à faire avec l'utilisateur ``postgres``. Commencer par créer un répertoire et lui donner des droits sur le répertoire où seront faites les sauvegardes.

::

    # Créer le répertoire pour stocker les sauvegardes
    mkdir /home/`whoami`/backup
    # Ajouter l'utilisateur postgres au groupe de l'utilisateur linux courant pour qu'il ait les droits d'écrire dans les mêmes répertoires
    sudo adduser postgres `whoami`

Connectez-vous avec l'utilisateur linux ``postgres`` pour lancer une sauvegarde de la BDD :

::

    sudo su postgres
    pg_dump -Fc geonature2db  > backup/`date +%Y-%m-%d-%H:%M`-geonaturedb.backup
    exit

Si la sauvegarde ne se fait pas, c'est qu'il faut revoir les droits du répertoire où sont faites les sauvegardes pour que l'utilisateur ``postgres`` puisse y écrire

Opération à faire régulièrement grâce à une tâche cron.

* Sauvegarde des fichiers de configuration :

  ::

    cd geonature/config
    tar -zcvf <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-geonature_config.tar.gz ./
    cd /home/<MY_USER>/geonature
    
Opération à faire à chaque modification d'un paramètre de configuration.

* Sauvegarde des fichiers de customisation :

  ::

    cd /home/<MY_USER>geonature/frontend/src/custom
    tar -zcvf <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-geonature_custom.tar.gz ./

Opération à faire à chaque modification de la customisation de l'application.

* Sauvegarde des modules externes :

  ::

    cd /home/<MY_USER>geonature/external_modules
    tar -zcvf <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-external_modules.tar.gz ./

Restauration
""""""""""""

* Restauration de la base de données :

  - Créer une base de données vierge (on part du principe que la base de données ``geonature2db`` n'existe pas ou plus). Sinon adaptez le nom de la BDD et également la configuration de connexion de l'application à la BDD dans ``<GEONATURE_DIRECTORY>/config/geonature_config.toml``

    ::

        sudo -n -u postgres -s createdb -O theo geonature2db
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS hstore;"
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"
        sudo -n -u postgres -s psql -d geonature2db -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
        
  - Restaurer la BDD à partir du backup

    ::

        pg_restore -d geonature2db <MY_BACKUP_DIRECTORY_PATH>/201803150917-geonaturedb.backup

* Restauration de la configuration et de la customisation :

  - Décomprésser les fichiers précedemment sauvegardés pour les remettre au bon emplacement :

    ::

        sudo rm <GEONATURE_DIRECTORY>/config/*
        cd <GEONATURE_DIRECTORY>/config
        sudo tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_config.tar.gz
        
        cd /home/<MY_USER>/geonature/frontend/src/custom
        rm -r <MY_USER>/geonature/frontend/src/custom/*
        tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_custom.tar.gz
        
        rm /home/<MY_USER>/geonature/external_modules/*
        cd <GEONATURE_DIRECTORY>/external_modules
        tar -zxvf <MY_BACKUP_DIRECTORY>/201803151036-external_modules.tar.gz 

* Relancer l'application :

  ::

    cd /<MY_USER>/geonature/frontend
    npm run build
    sudo supervisorctl reload

Customisation
-------------

Intégrer son logo
"""""""""""""""""

Le logo affiché dans la barre de navigation de GeoNature peut être modifié dans le répertoire ``geonature/frontend/src/custom/images``. Remplacez alors le fichier ``logo_structure.png`` par votre propre logo, en conservant ce nom pour le nouveau fichier. 

Relancez la construction de l’interface :

::

    cd /home/`whoami`/geonature/frontend
    npm run build


Customiser le contenu
"""""""""""""""""""""

* Customiser le contenu de la page d’introduction :

Le texte d'introduction et le titre de la page d'Accueil de GeoNature peuvent être modifiés à tout moment, sans réinstallation de l'application. Il en est de même pour le bouton d’accès à la synthèse.

Il suffit pour cela de mettre à jour le fichier ``introduction.component.html``, situé dans le répertoire ``geonature/frontend/src/custom/components/introduction``. 

Afin que ces modifications soient prises en compte dans l'interface, il est nécessaire de relancer les commandes suivantes :

::

    cd /home/`whoami`/geonature/frontend
    npm run build


* Customiser le contenu du pied de page :

Le pied de page peut être customisé de la même manière, en renseignant le fichier ``footer.component.html``, situé dans le répertoire ``geonature/frontend/src/custom/components/footer``

De la même manière, il est nécessaire de relancer les commandes suivantes pour que les modifications soient prises en compte :

::

    cd /home/`whoami`/geonature/frontend
    npm run build
    
    
Customiser l'aspect esthétique
""""""""""""""""""""""""""""""

Les couleurs de textes, couleurs de fonds, forme des boutons etc peuvent être adaptés en renseignant le fichier ``custom.scss``, situé dans le répertoire ``geonature/frontend/src/custom``. 

Pour remplacer la couleur de fond du bandeau de navigation par une image, on peut par exemple apporter la modification suivante :

::

    html body pnx-root pnx-nav-home mat-sidenav-container.sidenav-container.mat-drawer-container.mat-sidenav-container mat-sidenav-content.mat-drawer-content.mat-sidenav-content mat-toolbar#app-toolbar.row.mat-toolbar
   {
      background :
      url(bandeau_test.jpg)
   }

Dans ce cas, l’image ``bandeau_test.jpg`` doit se trouver dans le répertoire ``>geonature/frontend/src`` .

Comme pour la modification des contenus, il est nécessaire de relancer la commande suivante pour que les modifications soient prises en compte :

::

    cd /home/`whoami`/geonature/frontend
    npm run build


Intégrer des données
--------------------

Référentiel géographique
""""""""""""""""""""""""

GeoNature est fourni avec des données géographiques de base sur la métropôle (MNT national à 250m et communes de métropôle).

**1.** Si vous souhaitez modifier le MNT pour mettre celui de votre territoire : 

* Videz le contenu des tables ``ref_geo.dem`` et éventuellement ``ref_geo.dem_vector``
* Uploadez le fichier du MNT sur le serveur
* Suivez la procédure de chargement du MNT en l'adaptant : https://github.com/PnX-SI/GeoNature/blob/master/install/install_db.sh#L295-L299

*TODO : Procédure à améliorer et simplifier : https://github.com/PnX-SI/GeoNature/issues/235*



Si vous n'avez pas choisi d'intégrer le raster MNT national à 250m lors de l'installation ou que vous souhaitez le remplacer, voici les commandes qui vous permettront de le faire.

Suppression du MNT par défaut (adapter le nom de la base de données : MYDBNAME).

::

    sudo -n -u postgres -s psql -d MYDBNAME -c "TRUNCATE TABLE ref_geo.dem;"
    sudo -n -u postgres -s psql -d MYDBNAME -c "TRUNCATE TABLE ref_geo.dem_vector;"

Placer votre propre fichier MNT dans le répertoire ``/tmp/geonature`` (adapter le nom du fichier et son chemin ainsi que les paramètres en majuscule). Ou télécharger le MNT par défaut.

::

    wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P /tmp/geonature
    unzip /tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d /tmp/geonature
    export PGPASSWORD=MYUSERPGPASS;raster2pgsql -s MYSRID -c -C -I -M -d -t 5x5 /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h localhost -U MYPGUSER -d MYDBNAME
    sudo -n -u postgres -s psql -d MYDBNAME -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;"

Si vous souhaitez vectoriser le raster MNT pour de meilleures performances lors des calculs en masse de l'altitude à partir de la localisation des observations, vous pouvez le faire en lançant les commandes ci-dessous. Sachez que cela prendra du temps et beaucoup d'espace disque (2.8Go supplémentaires environ pour le fichier DEM France à 250m).

::

    sudo -n -u postgres -s psql -d MYDBNAME -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;"
    sudo -n -u postgres -s psql -d MYDBNAME -c "REINDEX INDEX ref_geo.index_dem_vector_geom;"

Si ``ref_geo.dem_vector`` est remplie, cette table est utilisée pour le calcul de l'altitude à la place de la table ``ref_geo.dem``

**2.** Si vous souhaitez modifier ou ajouter des zonages administratifs, réglementaires ou naturels : 

* Vérifiez que leur type existe dans la table ``ref_geo.bib_areas_types``, sinon ajoutez-les
* Ajoutez vos zonages dans la table ``ref_geo.l_areas`` en faisant bien référence à un ``id_type`` de ``ref_geo.bib_areas_types``. Vous pouvez faire cela en SQL ou en faisant des copier/coller de vos zonages directement dans QGIS
* Pour les grilles et les communes, vous pouvez ensuite compléter leurs tables d'extension ``ref_geo.li_grids`` et ``ref_geo.li_municipalities``

Données externes
""""""""""""""""

Il peut s'agir de données partenaires, de données historiques ou de données saisies dans d'autres outils. 

2 possibilités s'offrent à vous : 

* Créer un schéma dédié aux données pour les intégrer de manière complète et en extraire les DEE dans la Synthèse
* N'intégrer que les DEE dans la Synthèse

Nous présenterons ici la première solution qui est privilégiée pour disposer des données brutes mais aussi les avoir dans la Synthèse.

* Créer un JDD dédié (``gn_meta.t_datasets``) ou utilisez-en un existant. Eventuellement un CA si elles ne s'intègrent pas dans un CA déjà existant.
* Ajouter une Source de données dans ``gn_synthese.t_sources`` ou utilisez en une existante.
* Créer le schéma dédié à accueillir les données brutes.
* Créer les tables nécessaires à accueillir les données brutes.
* Intégrer les données dans ces tables (avec les fonctions de ``gn_imports``, avec QGIS ou pgAdmin).
* Pour alimenter la Synthèse à partir des tables sources, vous pouvez mettre en place des triggers (en s'inspirant de ceux de OccTax) ou bien faire une requête spécifique si les données sources ne sont plus amenées à évoluer.

Pour des exemples plus précis, illustrées et commentées, vous pouvez consulter les 2 exemples d'import dans cette documentation.

Vous pouvez aussi vous inspirer des exemples avancés de migration des données de GeoNature V1 vers GeoNature V2 : https://github.com/PnX-SI/GeoNature/tree/master/data/migrations/v1tov2

Import depuis SICEN (ObsOcc) : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/sicen ou import continu : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/generic

Module OCCTAX
-------------

Installer le module
"""""""""""""""""""

Le module est fourni par défaut avec l'installation de GeoNature.

Si vous l'avez supprimé, lancez les commandes suivantes depuis le repertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature install_gn_module /home/<mon_user>/geonature/contrib/occtax occtax


Configuration du module
"""""""""""""""""""""""

Le fichier de configuration du module se trouve ici : ``<GEONATURE_DIRECTORY>/external_modules/occtax/conf_gn_module.toml``.

Pour voir l'ensemble des variables de configuration du module ainsi que leurs valeurs par défaut, ouvrir le fichier ``/home/<mon_user>/geonature/external_modules/occtax/config/conf_gn_module.toml``.

Afficher/masquer des champs du formulaire
*****************************************

La quasi-totalité des champs du standard Occurrences de taxons sont présents dans la base de données, et peuvent donc être saisis à partir du formulaire.

Pour plus de souplesse et afin de répondre aux besoins de chacun, l'ensemble des champs sont masquables (sauf les champs essentiels : observateur, taxon ...)

En modifiant les variables des champs ci-dessous, vous pouvez donc personnaliser le formulaire :

::

    [form_fields]
        date_min = true
        date_max = true
        hour_min = true
        hour_max = true
        altitude_min = true
        altitude_max = true
        obs_technique = true
        group_type = true
        comment_releve = true
        obs_method = true
        bio_condition = true
        bio_status = true
        naturalness = true
        exist_proof = true
        observation_status = true
        diffusion_level = false
        blurring = false
        determiner = true
        determination_method = true
        sample_number_proof = true
        digital_proof = true
        non_digital_proof = true
        source_status = false
        comment_occ = true
        life_stage = true
        sex = true
        obj_count = true
        type_count = true
        count_min = true
        count_max = true
        validation_status = false

Si le champ est masqué, une valeur par défaut est inscrite en base (voir plus loin pour définir ces valeurs).

Modifier le champ Observateurs
******************************

Par défaut le champ ``Observateurs`` est une liste déroulante qui pointe vers une liste du schéma ``utilisateurs``.
Il est possible de passer ce champ en texte libre en mettant à ``true`` la variable ``observers_txt``.

Le paramètre ``id_observers_list`` permet de changer la liste d'observateurs proposée dans le formulaire. Vous pouvez modifier le numéro de liste du module ou modifier le contenu de la liste dans UsersHub (``utilisateurs.t_menus`` et ``utilisateurs.cor_role_menu``)

Par défaut, l'ensemble des observateurs de la liste 9 (observateurs faune/flore) sont affichés.

Personnaliser la liste des taxons saisissables dans le module
*************************************************************

Le module est fourni avec une liste restreinte de taxons (8 seulement). C'est à l'administrateur de changer ou de remplir cette liste.

Le paramètre ``id_taxon_list = 100`` correspond à un ID de liste de la table ``taxonomie.bib_listes`` (L'ID 100 correspond à la liste "Saisie Occtax"). Vous pouvez changer ce paramètre avec l'ID de liste que vous souhaitez, ou bien garder cet ID et changer le contenu de cette liste.

Voici les requêtes SQL pour remplir la liste 500 avec tous les taxons de Taxref à partir du rang ``genre`` : 

Il faut d'abord remplir la table ``taxonomie.bib_noms`` (table des taxons de sa structure), puis remplir la liste 500, avec l'ensemble des taxons de ``bib_noms`` :

:: 

    DELETE FROM taxonomie.cor_nom_liste;
    DELETE FROM taxonomie.bib_noms;

    INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
    SELECT cd_nom, cd_ref, nom_vern
    FROM taxonomie.taxref
    WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
      'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR')

    INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
    SELECT 100,n.id_nom FROM taxonomie.bib_noms n

Il est également possible d'éditer des listes à partir de l'application TaxHub.

Gérer les valeurs par défaut des nomenclatures
**********************************************

Le formulaire de saisie pré-remplit des valeurs par défaut pour simplifier la saisie. Ce sont également ces valeurs qui sont prises en compte pour remplir dans la BDD les champs du formulaire qui sont masqués.

La table ``pr_occtax.defaults_nomenclatures_value`` définit les valeurs par défaut pour chaque nomenclature.

La table contient les deux colonnes suivantes :

- l'``id_type`` de nomenclature (voir table ``ref_nomenclature.bib_nomenclatures_types``)
- l'``id_nomenclature`` (voir table ``ref_nomenclature.t_nomenclatures``)

Pour chaque type de nomenclature, on associe l'ID de la nomenclature que l'on souhaite voir apparaitre par défaut.

Le mécanisme peut être poussé plus loin en associant une nomenclature par défaut par organisme, règne et group2_inpn.
La valeur 0 pour ses champs revient à mettre la valeur par défaut pour tous les organismes, tous les règnes et tous les group2_inpn.

Une interface de gestion des nomenclatures est prévue d'être développée pour simplifier cette configuration.

TODO: valeur par défaut de la validation

Personnaliser l'interface Map-list
**********************************

La liste des champs affichés par défaut dans le tableau peut être modifiée avec le paramètre ``default_maplist_columns``.

Par défaut :

::


    default_maplist_columns = [
        { prop = "taxons", name = "Taxon" },
        { prop = "date_min", name = "Date début" },
        { prop = "observateurs", name = "Observateurs" },
        { prop = "dataset_name", name = "Jeu de données" }
    ]

Voir la vue ``occtax.v_releve_list`` pour voir les champs disponibles.

Gestion des exports
"""""""""""""""""""

Les exports du module sont basés sur une vue (par défaut ``pr_occtax.export_occtax_dlb``)

Il est possible de définir une autre vue pour avoir des exports personnalisés.
Pour cela, créer votre vue, et modifier les paramètres suivants :

::

    # Name of the view based export
    export_view_name = 'ViewExportDLB'

    # Name of the geometry columns of the view
    export_geom_columns_name = 'geom_4326'

    # Name of the primary key column of the view
    export_id_column_name = 'permId'

La vue doit cependant contenir les champs suivants pour que les filtres de recherche fonctionnent :

::

    date_min,
    date_max,
    id_releve_occtax,
    id_dataset,
    id_occurrence_occtax,
    id_digitiser,
    geom_4326,
    dataset_name

Attribuer des droits
""""""""""""""""""""

La gestion des droits (CRUVED) se fait module par module. Cependant si on ne redéfinit pas de droit pour un module, ce sont les droits de l'application mère (GeoNature elle-même) qui seront attribués à l'utilisateur pour l'ensemble de ses sous-modules.

Pour ne pas afficher le module Occtax à un utilisateur où à un groupe, il faut lui mettre l'action Read (R) à 0.

Cette manipulation se fait dans la table (``utilisateurs.cor_ap_privileges``), où ``id_tag_action`` correspond à l'id du tag d'une action (CRUVED), et ``id_tag_object`` à l'id du tag de la portée pour chaque action (0,1,2,3). Voir la table ``utilisateurs.t_tags`` pour identifier la correspondance entre les tags et les actions, ainsi que les portées.

La correspondance entre ``id_tag_action``, ``id_tag_object``, ``id_application`` et ``id_role`` donnera les droits d'une personne ou d'un groupe pour une application (ou module) donnée.

L'administration des droits des utilisateurs se fera bientôt dans une nouvelle version de UsersHub qui prendra en compte ce nouveau mécanisme du CRUVED.
