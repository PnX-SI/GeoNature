MANUEL ADMINISTRATEUR
=====================

Architecture
------------

GeoNature possède une architecture modulaire et s'appuie sur de plusieurs "services" indépendants pour fonctionner:

- UsersHub et son sous-module d'authentification Flask (https://github.com/PnX-SI/UsersHub-authentification-module) sont utilisés pour gérer le schéma de BDD ``ref_users`` (actuellement nommé ``utilisateurs``) et l'authentification. UsersHub permet une gestion centralisée de ses utilisateurs (liste, organisme, droits) utilisable par les différentes applications de son système d'information.
- TaxHub (https://github.com/PnX-SI/TaxHub) est utilisé pour la gestion du schéma de BDD ``ref_taxonomy`` (actuellemenet nommé ``taxonomie``). L'API de TaxHub est utilisée pour récupérer des informations sur les espèces et la taxonomie en générale.
- Un sous-module Flask (https://github.com/PnX-SI/Nomenclature-api-module/) a été créé pour une gestion centralisée des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module/), il pilote le schéma ``ref_nomenclature``.
- ``ref_geo`` est le schéma de base de données qui gère le référentiel géographique. Il est utilisé pour gérer les zonages, les communes, le calcul automatique d'altitude et les intersections spatiales.

GeoNature a également une séparation claire entre le backend (API: intéraction avec la base de données) et le frontend (interface utilisateur). Le backend peut être considéré comme un "service" dont se sert le frontend pour récupérer ou poster des données. 
NB: Le backend en le frontend se lancent séparement dans GeoNature.

.. image :: http://geonature.fr/docs/img/admin-manual/design-geonature.png

Base de données
---------------

Dans la continuité de sa version 1, GeoNature V2 utilise le SGBD PostgreSQL et sa cartouche spatiale PostGIS. Cependant l'architecture du modèle de données a été complétement revue.

La base de données a notemment été refondue pour s'appuyer au maximum sur des standards, comme le standard d'Occurrences de Taxon du MNHN (Voir https://github.com/PnX-SI/GeoNature/issues/183)

La base de données a également été traduite en Anglais et supporte désormais le multilangue.

Les préfixes des schémas de BDD sont désormais standardisés : ``ref_`` concerne les référentiels externes, ``gn`` concerne les schémas du coeur de GeoNature et ``pr`` les schémas des protocoles. 

Autres standards:

- Noms de tables, commentaires et fonctions en anglais
- pas de nom de table dans les noms de champs
- nom de schema eventuellement dans nom de table

Dernière version de la base de données (2018-03-19) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/2018-03-19-GN2-MCD.png

Désolé pour les relations complexes entre tables...

Voici un modèle simplifié de la BDD (2017-12-15) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/2017-12-15-GN2-MCD-simplifie.jpg

Gestion des droits :
""""""""""""""""""""

La gestion des droits est centralisée dans UsersHub. Dans la version 1 de GeoNature, il était possible d'attribuer des droits selon 6 niveaux à des rôles (utilisateurs ou groupes). Pour la version 2 de GeoNature, des évolutions ont été réalisées pour étendre les possibilités d'attribution de droits et les rendre plus génériques. 

Pour cela un système d'étiquettes (``utilisateurs.t_tags``) a été mis en place. Il permet d'attribuer des étiquettes génériques à des rôles (utilisateurs ou groupes d'utilisateurs). 

- Dans GeoNature V2 cela permet d'attribuer des actions possibles à un rôle sur une portée dans une application ou un module (définis dans ``utilisateurs.cor_app_privileges``).
- 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
- Une vue permet de retourner toutes les actions, leur portée et leur module de GeoNature pour tous les rôles (``utilisateurs.v_usersaction_forall_gn_modules``)
- Des fonctions PostgreSQL ont aussi été intégrés pour faciliter la récupération de ces informations (``utilisateurs.cruved_for_user_in_module``, ``utilisateurs.can_user_do_in_module``, ...)
- Une hiérarchie a été rendue possible entre applications et entre organismes pour permettre un système d'héritage
- Si un utilisateur n'a aucune action possible sur un module, alors il ne lui sera pas affiché et il ne pourra pas y accéder
- Tous ces éléments sont en train d'être intégrés dans le schéma ``utilisateurs`` de UsersHub pour supprimer le schéma spécifique ``utilisateurs`` de GeoNature
- Il est aussi possible de ne pas utiliser UsersHub pour gérer les utilisateurs et de connecter GeoNature à un CAS (voir configuration). Actuellement ce paramétrage est fonctionnel en se connectant au CAS de l'INPN (MNHN)

Nomenclatures :
"""""""""""""""

- Toutes les listes déroulantes sont gérées dans une table générique ``ref_nomenclatures.t_nomenclatures``
- Elles s'appuient sur les nomenclatures du SINP (http://standards-sinp.mnhn.fr/nomenclature/) qui peuvent être désactivées ou completées
- Chaque nomenclature est associée à un type et une vue par type de nomenclature a été ajoutée pour simplifier leur usage 
- Ces nomenclatures sont gérées dans un sous-module pour pouvoir les réutiliser (ainsi que leur mécanisme) dans d'autres applications : https://github.com/PnX-SI/Nomenclature-api-module/
- Chaque nomenclature peut être associée à un règne ou un group2inpn (``ref_nomenclatures.cor_taxref_nomenclature``) pour proposer des nomenclatures correspondants à un taxon
- Les valeurs par défaut sont définies dans chaque module
- Pour OCCTAX c'est dans ``pr_occtax.defaults_nomenclatures_value``. Elle peut être définie pour chaque type de nomenclature ainsi que par organisme, règne et/ou group2inpn
- Si organisme = 0 alors la valeur par défaut s'applique à tous les organismes. Idem pour les règnes et group2inpn
- La fonction ``pr_occtax.get_default_nomenclature_value`` permet de renvoyer l'id de la nomenclature par défaut
- Ces valeurs par défaut sont aussi utilisées pour certains champs qui sont cachés (statut_observation, floutage, statut_validation...) mais ne sont donc pas modifiables par l'utilisateur
- Il existe aussi une table pour définir des valeurs par défaut de nomenclature générales (``ref_nomenclatures.defaults_nomenclatures_value``)

Métadonnées :
"""""""""""""

- Elles sont gérées dans le schéma ``gn_meta`` basé sur le standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/)
- Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles

Données SIG :
"""""""""""""

- Le schéma ``ref_geo`` permet de gérer les données SIG (zonages, communes, MNT...) de manière centralisée, potentiellement partagé avec d'autres BDD
- Il contient une table des zonages, des types de zonages, des communes, des grilles (mailles) et du MNT vectorisé (https://github.com/PnX-SI/GeoNature/issues/235)
- La fonction ``ref_geo.fct_get_area_intersection`` permet de renvoyer les zonages intersectés par une observation en fournissant sa géométrie
- La fonction ``ref_geo.fct_get_altitude_intersection`` permet de renvoyer l'altitude min et max d'une observation en fournissant sa géométrie
- L'intersection d'une observation avec les zonages sont stockés au niveau de la synthèse (``gn_synthese.cor_area_synthese``) et pas de la donnée source pour alléger et simplifier leur gestion


Modularité
----------

Chaque module doit avoir son propre schéma dans la BDD, avec ses propres fichiers SQL de création comme le module OccTax : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/data

Côté backend, chaque module a aussi son modèle et ses routes : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/backend

Idem côté FRONT, où chaque module a sa config et ses composants : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/frontend/app

Mais en pouvant utiliser des composants du CORE comme expliqué dans la doc Developpeur.

Plus d'infos sur le développement d'un module : https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9velopper-et-installer-un-gn_module


Configuration
-------------

Pour configurer GeoNature, actuellement il y a : 

- Une configuration pour l'installation : ``config/settings.ini``
- Une configuration globale de l'application : ``/etc/geonature/geonature_config.toml`` (générée lors de l'installation de GeoNature)
- Une configuration par module : ``/etc/geonature/mods-enabled<nom_module>/conf_gn_module.toml`` (générée lors de l'instalation d'un module)
- Une table ``gn_meta.t_parameters`` pour des paramètres gérés dans la BDD


Configuration générale de l'application
"""""""""""""""""""""""""""""""""""""""

L'installation de GeoNature génère le fichier de configuration globale ``/etc/geonature/geonature_config.toml``. Ce fichier est aussi copié dans le frontend (``frontend/conf/app.config.ts`` à ne pas modifier).

Par défaut, le fichier ``/etc/geonature/geonature_config.toml`` est minimaliste et généré à partir des infos présentes dans le fichier ``config/settings.ini``.

Il est possible de le compléter en surcouchant les paramètres présents dans le fichier ``config/default_config.toml.example``.

A chaque modification fichier global de configuration (``/etc/geonature/geonature_config.toml``), il faut regénérer le fichier de configuration du frontend.

Ainsi après chaque modification des fichiers de configuration globale, placez-vous dans le backend de GeoNature (``/home/monuser/GeoNature/backend``) et lancez les commandes : 

::

    source venv/bin/activate
    geonature update_configuration
    deactivate

Configuration d'un gn_module
""""""""""""""""""""""""""""

Lors de l'instalation d'un module, un fichier de configuration est créé: ``/etc/geonature/mods-enabled/<nom_module>/conf_gn_module.toml``.

Comme pour la configuration globale, ce fichier est minimaliste et peut être surcouché. Le fichier ``conf_gn_module.toml.example`` situé à la racine du module, décrit l'ensemble des variables de configuration disponibles ainsi que leurs valeurs par défaut.

A chaque modification de ce fichier lancer les commandes suivantes (le fichier est copié à destination du frontend ``<nom_module>/frontend/app/module.config.ts``, qui est alors recompiler)

::

    source venv/bin/activate
    geonature update_module_configuration <NOM_DE_MODULE>
    deactivate



Exploitation
------------

Logs
"""""

Les logs de GeoNature sont dans le répertoire ``/var/log/geonature`` :

- logs d'installation de la BDD : ``install_db.log``
- logs d'installation de la BDD d'un module : ``install_<nom_module>_schema.log``
- logs de l'API : ``gn-errors.log``

Les logs de TaxHub sont dans le repertoire ``/var/log/taxhub``:

- logs de l'API de TaxHub : ``taxhub-errors.log``

Verification des services
"""""""""""""""""""""""""

Les API de GeoNature et de TaxHub sont lancées par deux serveurs http python indépendants (Gunicorn), eux-mêmes controlés par le supervisor.

Par défaut:

- L'API de GeoNature tourne sur le port 8000
- L'API de taxhub tourne sur le port 5000

Pour vérifier que les API de GeoNature et de TaxHub sont lancées, éxecuter la commande :

``ps -aux |grep gunicorn``

La commande doit renvoyer 4 fois la ligne suivante pour GeoNature :

::

    root      27074  4.6  0.1  73356 23488 ?        S    17:35   0:00       /home/theo/workspace/GN2/GeoNature/backend/venv/bin/python3 /home/theo/workspace/GN2/GeoNature/backend/venv/bin/gunicorn wsgi:app --error-log /var/log/geonature/api_errors.log --pid=geonature2.pid -w 4 -b 0.0.0.0:8000 -n geonature2

et 4 fois la ligne suivante pour TaxHub :

::

    root      27103 10.0  0.3 546188 63328 ?        Sl   17:35   0:00 /home/theo/workspace/GN2/TaxHub/venv/bin/python3.5 /home/theo/workspace/GN2/TaxHub/venv/bin/gunicorn server:app --access-logfile /var/log/taxhub/taxhub-access.log --error-log /var/log/taxhub/taxhub-errors.log --pid=taxhub.pid -w 4 -b 0.0.0.0:5000 -n taxhub
    
Chaque ligne correspond à un worker Gunicorn.

Si ces lignes n'apparaissent pas, cela signigie qu'une des deux API n'a pas été lancée ou a connu un problème à son lancement. Voir les logs des API pour plus d'informations.

Stopper/Redémarrer les API
"""""""""""""""""""""""""""

Les API de GeoNature et de TaxHub sont gérées par le supervisor pour être lancé automatiquement au démarage du serveur.

Pour les stopper, éxecuter les commandes suivantes :

- GeoNature: ``sudo supervisorctl stop geonature2``
- TaxHub: ``sudo supervisorctl stop taxhub``

Pour redémarer les API:
``sudo supervisorctl reload``

Maintenance
"""""""""""

Lors d'une opération de maintenance (monté en version, modification en base de données), vous pouvez rendre l'application momentanémment indisponible.

Pour cela, désactiver la configuration Apache de GeoNature, puis activer la configuration du mode de maintenance:

::

    sudo a2dissite geonature
    sudo a2ensite geonature_maintenance

A la fin de l'opération de maintenance, effectuer la manipulation inverse

::

    sudo a2dissite geonature_maintenance     
    sudo a2ensite geonature



Attention: ne pas stopper le backend (des opérations en BDD en cours pourraient être corrompue)

Sauvegarde et restauration
--------------------------

- Sauvegarge:

    **Sauvegarde de la base de données** :

    Opération à faire régulièrement grâce à une tâche cron

    ::

        pg_dump -Fc geonature2db  > <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-geonaturedb.backup


    **Sauvegarde des fichiers de configuration** :

    Opération à faire à chaque modification d'un paramètre de configuration

    ::

        cd /etc/geonature
        tar -zcvf <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-geonature_config.tar.gz ./
        cd /home/<MY_USER>/geonature
        cp config/settings.ini <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-settings.ini

    **Sauvegarde des fichiers de customisation**:

    Opération à faire à chaque modification de la customisation de l'application

    ::

        cd /home/<MY_USER>geonature/frontend/src/custom
        tar -zcvf <MY_BACKUP_DIRECTORY_PATH>/`date +%Y%m%d%H%M`-geonature_custom.tar.gz ./


- Restauration

    **Restauration de la base de données** :

    - Créer une base de données vierge (on part du principe que la de données ``geonature2db`` n'existe pas ou plus)
    
        Si ce n'est pas le cas, adaptez le nom de la BDD et également la configuration de connexion de l'application à la BDD dans ``/etc/geonature/geonature_config.toml``
        ::

            sudo -n -u postgres -s createdb -O theo geonature2db
            sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
            sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"
            sudo -n -u postgres -s psql -d geonature2db -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
        
    - Restaurer la BDD à partir du backup

        ::
            
            pg_restore -d geonature2db <MY_BACKUP_DIRECTORY_PATH>/201803150917-geonaturedb.backup

    **Restauration de la configutration et de la customisation** :

    Décomprésser les fichiers précedemment sauvegardés pour les remettre au bon emplacement :

    :: 
    
        sudo rm -r /etc/geonature/*
        cd /etc/geonature
        sudo tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_config.tar.gz

        cd /home/<MY_USER>/geonature/frontend/src/custom
        rm -r <MY_USER>/geonature/frontend/src/custom/*
        tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_custom.tar.gz

        rm /home/<MY_USER>/geonature/config/settings.ini
        cp <MY_BACKUP_DIRECTORY>/201803151036-settings.ini /home/<MY_USER>/geonature/config/settings.ini


- Relancer l'application :

    ::

        cd /<MY_USER>/geonature/frontend
        npm run build
        sudo supervisorctl reload


Intégrer des données externes
-----------------------------

Il peut s'agir de données partenaires, de données historiques ou de données saisies dans d'autres outils. 

2 possibilités s'offrent à vous : 

* Créer un schéma dédié aux données pour les intégrer de manière complète et en extraire les DEE dans la Synthèse
* N'intégrer que les DEE dans la Synthèse

Nous présenterons ici la première solution qui est privilégiée pour disposer des données brutes mais aussi les avoir dans la Synthèse.

* Créer un JDD dédié. Eventuellement un CA si elles ne s'intègrent pas dans un CA déjà existant.
* Ajouter une Source de données dans ``synthese.t_sources``.
* Créer le schéma dédié à accueillir les données brutes.
* Créer les tables nécessaires à accueillir les données brutes.
* Intégrer les données dans ces tables.
* Pour alimenter la Synthèse à partir des tables sources, vous pouvez mettre en place des triggers (en s'inspirant de ceux de OccTax) ou bien faire une requête spécifique si les données sources ne sont plus amenées à évoluer.


Module OCCTAX
-------------

**Installer le module**
""""""""""""""""""""""""

Le module est fourni par défaut avec l'instalation de GeoNature.

Si vous l'avez supprimé, lancer les commandes suivantes depuis le repertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature install_gn_module /home/<mon_user>/geonature/contrib/occtax occtax


**Configuration du module**
"""""""""""""""""""""""""""

Le fichier de configuration du module se trouve ici : ``/etc/geonature/mods-enabled/occtax/conf_gn_module.toml``

Pour voir l'ensemble des variables de configuration du module ainsi qu leurs valeurs par défaut, ouvrir le fichier ``/home/<mon_user>/geonature/contrib/occtax/conf_gn_module.toml``


Afficher/masquer des champs du formulaire
"""""""""""""""""""""""""""""""""""""""""

La quasi-totalité des champs du standard Occurrences de taxons sont présents dans la base de données, et peuvent donc être saisis à partir du formulaire.

Pour plus de souplesse et afin de répondre aux besoins de chacun, l'ensemble des champs sont masquables (sauf les champs essentiels : observateur, taxon ...)

En modifiant les variables des champs ci-dessous, vous pouvez donc personnaliser le formulaire :

::

  [form_fields]
	[form_fields.releve]
		date_min = true
		date_max = true
		hour_min = true
		hour_max = true
		altitude_min = true
		altitude_max = true
		obs_technique = true
		group_type = true
		comment = true
	[form_fields.occurrence]
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
		comment = true
	[form_fields.counting]
		life_stage = true
		sex = true
		obj_count = true
		type_count = true
		count_min = true
		count_max = true
		validation_status = false

Si le champ est masqué, une valeur par défaut est inscrite en base (voir plus loin pour définir ces valeurs).

Modifier le champ observateur
"""""""""""""""""""""""""""""

Par défaut le champ Observateur est une liste déroulante qui pointe vers une liste du schéma utilisateur.
Il est possible de passer ce champ en texte libre en mettant à ``true`` la variable ``observers_txt``

Le paramètre ``id_observers_list`` permet de changer la liste d'observateur proposé dans le formulaire. Vous pouvez modifier le numéro de liste du module ou modifier le contenu de la liste dans UsersHub (``utilisateurs.t_menus`` et ``utilisateurs.cor_role_menu``)

Par défaut, l'ensemble des observateurs de la liste 9 (observateur faune/flore) sont affichés.

Personnaliser la liste des taxons saisissables dans le module
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Le module est fournit avec une liste restreinte de taxons (3 seulement). C'est à l'administrateur de changer ou de remplir cette liste.

Le paramètre ``id_taxon_list = 500`` correspond à un ID de liste de la table ``taxonomie.bib_liste`` (L'ID 500 corespond à la liste "Saisie possible"). Vous pouvez changer ce paramètre avec l'ID de liste que vous souhaitez, ou bien garder cet ID et changer le contenu de cette liste.

Voici les requêtes SQL pour remplir la liste 500 avec tous les taxons de Taxref à partir du genre : 

Il faut d'abord remplir la table ``taxonomie.bib_noms`` (table des taxons de sa structure), puis remplir la liste 500, avec l'ensemble des taxons de ``bib_noms``

:: 

    DELETE FROM taxonomie.cor_nom_liste;
    DELETE FROM taxonomie.bib_noms;

    INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
    SELECT cd_nom, cd_ref, nom_vern
    FROM taxonomie.taxref
    WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
      'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR')

    INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
    SELECT 500,n.id_nom FROM taxonomie.bib_noms n


Il est également possible d'éditer des listes à partir de l'application TaxHub.

Gérer les valeurs par défaut des nomenclatures
"""""""""""""""""""""""""""""""""""""""""""""""

Le formulaire de saisie pré-rempli des valeurs par défaut pour simplifier la saisie. Ce sont également ces valeurs qui sont prises en compte pour remplir dans la BDD les champs du formulaire qui sont masqués.

La table ``pr_occtax.defaults_nomenclatures_value`` définit les valeurs par défaut pour chaque nomenclature du standard.

La table contient les deux colonnes suivantes :

- l'id_type de nomenclature (voir table ``ref_nomenclature.bib_nomenclatures_types``)
- l'id_nomenclature (voir table ``ref_nomenclature.t_nomenclatures``)

Pour chaque type de nomenclature, on associe l'ID de la nomenclature que l'on souhaite voir apparaitre par défaut.

Le mécanisme peut être poussé plus loin en associant une nomenclature par défaut par organisme, règne et group2_inpn.
La valeur 0 pour ses champs revient à mettre la valeur par défaut pour tous les organismes, tous les règnes et tous les group2_inpn.

Une interface de gestion des nomenclatures est prévue d'être réalisée pour simplifier cette configuration.

TODO: valeur par défaut de la validation

Personaliser l'inteface map-list
""""""""""""""""""""""""""""""""

La liste des champs affichés par défaut dans le tableau peut être modifiée avec le paramètre ``default_maplist_columns``

Par défaut:

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

Pour ne pas afficher le module Occtax à un utilisateur où à un groupe, il faut lui mettre l'action Read (R) à 0 par exemple.

Cette manipulation se fait dans la table (``utilisateurs.cor_ap_privileges``), où ``id_tag_action`` correspond à l'id du tag d'une action (CRUVED), et ``id_tag_object`` à l'id du tag de la portée pour chaque action (0,1,2,3). Voir la table ``utilisateurs.t_tags`` pour voir la corespondant entre les tags et les actions, ainsi que les portées.

La correspondance entre ``id_tag_action``, ``id_tag_object``, ``id_application`` et ``id_role`` donnera les droits d'une personne ou d'un groupe pour une application (ou module) donnée.

L'administration des droits des utilisateurs se fera bientôt dans une nouvelle version de UsersHub qui prendra en compte ce nouveau mécanisme du CRUVED.
