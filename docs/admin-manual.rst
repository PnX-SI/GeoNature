MANUEL ADMINISTRATEUR
=====================

Architecture
------------

- UsersHub and its Flask module (https://github.com/PnX-SI/UsersHub-authentification-module) are used to manage ``ref_users`` database schema and to authentificate
- TaxHub (https://github.com/PnX-SI/TaxHub) is used to manage ``ref_taxonomy`` database schema. We also use TaxHub API to get information about taxons, species...
- A Flask module has been created to manage nomenclatures datas and their API (https://github.com/PnX-SI/Nomenclature-api-module/)
- ``ref_geo`` is a geographical referential to manage areas, DEM and spatial functions such as intersections

.. image :: http://geonature.fr/docs/img/admin-manual/design-geonature.png

Database
--------

In GeoNature V2, the whole database is still done with PostgreSQL/PostGIS but it has also been totally rebuilt. 

It is based on MNHN SINP standard Occurrences de Taxons.
Details at https://github.com/PnX-SI/GeoNature/issues/183.

The database has also been translated into English and supports multilingual values. 

Database schemas prefixs : ``ref_`` for external referentials, ``gn_`` for GeoNature core schemas, ``pr_`` for protocols schemas.

- Noms de tables, commentaires et fonctions en anglais
- meta_create_date et meta_update_date dans les différentes tables
- deleted (boolean)
- pas de nom de table dans les noms de champs
- nom de schema eventuellement dans nom de table

Latest version of the database (2017-12-13) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/2017-12-13-GN2-MCD.png

Sorry for the relations, it is too long to arrange...

Here is a simplified model of the database (2017-12-15) : 

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
- Pour OCCTAX c'est dans ``pr_contact.defaults_nomenclatures_value``. Elle peut être définie pour chaque type de nomenclature ainsi que par organisme, règne et/ou group2inpn
- Si organisme = 0 alors la valeur par défaut s'applique à tous les organismes. Idem pour les règnes et group2inpn
- La fonction ``pr_contact.get_default_nomenclature_value`` permet de renvoyer l'id de la nomenclature par défaut
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

Chaque module doit avoir son propre schéma dans la BDD, avec ses propres fichiers SQL de création comme le module Contact (OCCTAX) : https://github.com/PnX-SI/GeoNature/tree/develop/data/modules/contact

Côté backend, chaque module a aussi son modèle et ses routes : https://github.com/PnX-SI/GeoNature/tree/develop/backend/geonature/modules/pr_contact

Idem côté FRONT, où chaque module a sa config et ses composants : https://github.com/PnX-SI/GeoNature/tree/develop/frontend/src/modules/contact

Mais en pouvant utiliser des composants du CORE comme expliqué dans la doc Developpeur.

Plus d'infos sur le développement d'un module : https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9velopper-et-installer-un-gn_module


Configuration
-------------

Pour configurer GeoNature, actuellement il y a : 

- Une configuration pour l'installation : config/settings.ini
- Une configuration globale de l'application : /etc/geonature/geonature_config.toml
- Une configuration frontend par module : frontend/geonature/modules/contact/contact.config.ts
- Une table ``gn_meta.t_parameters`` pour des paramètres gérés dans la BDD

Après chaque modification du fichier de configuration globale ou d'une module, placez-vous dans le backend de GeoNature (``/home/monuser/GeoNature/backend``) et lancer les commandes : 

::

    source venv/bin/activate
    geonature update_configuration
    deactivate


Exploitation
------------
Logs
"""""
Les logs de GeoNature sont dans le répertoire `/var/log/geonature`:

- logs d'installation de la BDD: ``install_db.log``
- logs d'installation en BDD d'un module: ``install_<nom_module>_schema.log``
- logs de l'API : ``gn-errors.log``

Les logs de Taxhub sont dans le repertoire ``/var/log/taxhub``:

- logs de l'API: ``taxhub-errors.log``
Verification des services
""""""""""""""""""""""""""
Les API de GeoNature et de TaxHub sont lancés par deux serveurs http python indépendants (Gunicorn), eux mêmes controlés par le supervisor.

Par défaut:

- L'API de GeoNature tourne sur le port 8000
- L'API de taxhub tourne sur le port 5000

Pour vérifier que les API de GeoNature et de TaxHub sont lancés executer la commande:

``ps -aux |grep gunicorn``

La commande doit renvoyer 4 fois la ligne suivante pour GeoNature:

::

    root      27074  4.6  0.1  73356 23488 ?        S    17:35   0:00       /home/theo/workspace/GN2/GeoNature/backend/venv/bin/python3 /home/theo/workspace/GN2/GeoNature/backend/venv/bin/gunicorn wsgi:app --error-log /var/log/geonature/api_errors.log --pid=geonature2.pid -w 4 -b 0.0.0.0:8000 -n geonature2

et 4 fois la ligne suivante pour TaxHub:

::

    root      27103 10.0  0.3 546188 63328 ?        Sl   17:35   0:00 /home/theo/workspace/GN2/TaxHub/venv/bin/python3.5 /home/theo/workspace/GN2/TaxHub/venv/bin/gunicorn server:app --access-logfile /var/log/taxhub/taxhub-access.log --error-log /var/log/taxhub/taxhub-errors.log --pid=taxhub.pid -w 4 -b 0.0.0.0:5000 -n taxhub
    
Chaque ligne correspond à un worker Gunicorn.

Si ces lignes n'apparaissent pas, cela signigie qu'une des deux API n'a pas été lancé ou a connu un problème à son lancement. Voir les logs des API pour plus d'informations.

Stopper/Redémarrer les API
"""""""""""""""""""""""""""
Les API de GeoNature et de TaxHub sont gérés par le supervisor pour être lancé automatiquement au démarage du serveur.

Pour les stopper, executer les commande suivantes:

- GeoNature: ``sudo supervisorctl stop geonature2``
- TaxHub: ``sudo supervisorctl stop taxhub``

Pour redémarer les API:
``sudo supervisorctl reload``


Sauvegarde
----------

Quoi et comment sauvegarder
