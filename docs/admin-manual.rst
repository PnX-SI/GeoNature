MANUEL ADMINISTRATEUR
=====================

Architecture
------------

GeoNature possède une architecture modulaire et s'appuie sur plusieurs "services" indépendants pour fonctionner :

- UsersHub et son sous-module d'authentification Flask (https://github.com/PnX-SI/UsersHub-authentification-module) sont utilisés pour gérer le schéma de BDD ``ref_users`` (actuellement nommé ``utilisateurs``) et l'authentification. UsersHub permet une gestion centralisée de ses utilisateurs (listes, organismes, droits), utilisable par les différentes applications de son système d'information.
- TaxHub (https://github.com/PnX-SI/TaxHub) est utilisé pour la gestion du schéma de BDD ``ref_taxonomy`` (actuellement nommé ``taxonomie``). L'API de TaxHub est utilisée pour récupérer des informations sur les espèces et la taxonomie en général.
- Un sous-module Flask (https://github.com/PnX-SI/Nomenclature-api-module/) a été créé pour une gestion centralisée des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module/), il pilote le schéma ``ref_nomenclature``.
- ``ref_geo`` est le schéma de base de données qui gère le référentiel géographique. Il est utilisé pour gérer les zonages, les communes, le MNT, le calcul automatique d'altitude et les intersections spatiales.

GeoNature a également une séparation claire entre le backend (API: intéraction avec la base de données) et le frontend (interface utilisateur). Le backend peut être considéré comme un "service" dont se sert le frontend pour récupérer ou poster des données.
NB : Le backend et le frontend se lancent séparément dans GeoNature.

.. image :: _static/design-geonature.png

Base de données
---------------

Dans la continuité de sa version 1, GeoNature V2 utilise le SGBD PostgreSQL et sa cartouche spatiale PostGIS. Cependant l'architecture du modèle de données a été complétement revue.

La base de données a notamment été refondue pour s'appuyer au maximum sur des standards, comme le standard d'Occurrences de taxons du SINP (Voir http://standards-sinp.mnhn.fr/category/standards/occurrences-de-taxons/).

La base de données a également été traduite en Anglais et supporte désormais le multilangue.

Les préfixes des schémas de BDD sont désormais standardisés : ``ref_`` concerne les référentiels externes, ``gn_`` concerne les schémas du coeur de GeoNature et ``pr_`` les schémas des protocoles.

Autres standards :

- Noms de tables, commentaires et fonctions en anglais
- Pas de nom de table dans les noms de champs
- Nom de schema éventuellement dans nom de table

Schéma simplifié de la BDD :

.. image :: http://geonature.fr/docs/img/admin-manual/GN-schema-BDD.jpg

- En jaune, les schémas des réferentiels.
- En rose, les schémas du coeur de GeoNature
- En bleu, les schémas des protocoles et sources de données
- En vert, les schémas des applications pouvant interagir avec le coeur de GeoNature

Depuis la version 2.0.0-rc.4, il faut noter que les droits (CRUVED) ont été retirés du schéma ``utilisateurs`` (``ref_users``) de UsersHub pour l'intégrer dans GeoNature dans un schéma ``gn_permissions``, à ajouter en rose.

Modèle simplifié de la BDD (2017-12-15) :

.. image :: _static/2017-12-15-GN2-MCD-simplifie.jpg

Dernière version complète de la base de données (GeoNature 2.1 / 2019-08) :

.. image :: _static/2019-08-GN2-1-MCD.png

Les relations complexes entre les schémas ont été grisées pour faciliter la lisibilité.

Administration avec Alembic
"""""""""""""""""""""""""""

À partir de la version 2.7.5 de GeoNature, la gestion du schéma de la base de données se fait avec l’outil `Alembic <https://alembic.sqlalchemy.org/en/latest/>`_.
Celui-ci fonctionne grâce à des fichiers de migration qui sont appliqués de manière atomique (via une transaction) à la base de données, leur application étant enregistré dans la table ``public.alembic_version`` permettant en chaque instant de savoir dans quel état la base de données se trouve.

Les fichiers de migrations de GeoNature se trouve dans le dossier ``backend/geonature/migrations/versions/``.
Il est possible pour n’importe quelle dépendance ou module GeoNature de fournir également des fichiers de migrations. Pour que ceux-ci soient détectés par Alembic, il suffira de définir un point d’entrée dans le ``setup.py`` de la dépendance ou du module concerné :

.. code-block::

    setuptools.setup(
        …,
        entry_points={
            'alembic': [
                'migrations = my_module:migrations',
            ],
        },
        …
    )

Il est également possible de spécifier l’emplacement de révisions Alembic manuellement dans la configuration de GeoNature. Cela est nécessaire entre autre pour UsersHub afin de pouvoir manipuler son schéma alors que UsersHub n’est usuellemment pas installé dans le venv de GeoNature (seul UsersHub-authentification-module l’est) :

.. code-block::

    [ALEMBIC]
    VERSION_LOCATIONS = '/path/to/usershub/app/migrations/versions'

Chaque fichier de migration est caractérisé par :

* un identifiant, `e.g.` ``f06cc80cc8ba``
* une branche : Les branches permettent de séparer les fichiers de migrations afin de pouvoir les appliquer séparement. Par exemple, pour un déploiement de TaxHub sans GeoNature, il peut être intéressant de créer le schéma ``taxonomie`` sans créer les schémas de GeoNature, et ainsi gérer indépendamment les migrations de chaque schéma.
* un ancêtre : Lorsqu’un fichier de migration représente l’évolution d’un état antérieur de la base de données, l’ancêtre indique dans quelle version la base de données doit se trouver avant d’appliquer le-dis fichier de migration.
* des dépendances : Il est possible d’indiquer qu’une migration nécessite qu’une ou plusieurs autres migrations aient été préalablement appliquées. Par exemple, ceci permet d’indiquer que le schéma de GeoNature nécessite les schémas ``taxonomie`` et ``utilisateurs``.

Les commandes Alembic sont disponible grâce à la sous-commande ``db`` de la commande ``geonature`` :

.. code-block::

    $ geonature db --help

Les deux sous-commandes ``status`` et ``autoupgrade`` sont spécifique à GeoNature afin d’aider à l’utilisation d’Alembic.

La commande ``status`` permet de visualiser les branches et l’ensemble de leurs révisions.
Pour chaque révision est indiqué si celle-ci est appliqué à la base de données.
Si une branche a au moins sa première révision d’appliquée, alors un petit symbole indique si cette branche est à jour, c’est-à-dire si toutes les révisions de la branche ont été appliquées (``✓``) ou si la branche est en retard, c’est-à-dire que celle-ci contient des révisions qui ne sont pas encore appliqué à la base de données (``×``).

.. code-block::

    [geonature ✓]
      [x] ┰ f06cc80cc8ba geonature schemas 2.7.5
      [x] ┃ c0fdf2ee7f4f auto update cor_area_synthese
      [x] ┃ 7077aa76da3d bump dependencies
      [x] ┃ 2a2e5c519fd1 fix gn_synthese.get_default_nomenclature_value
      [x] ┃ 5f4c4b644844 delete cascade on  cor_dataset_territory and cor_dataset_protocol
      [x] ┃ 2aa558b1be3a add schema gn_profiles
      [x] ┃ 1eb624249f2b add default value in additionalFields bib
      [x] ┃ 7471f51011c8 change index_vm_valid_profiles_cd_ref to unique index
      [x] ┃ 9a9f4971edcd fix altitude trigger
      [x] ┃ 6f7d5549d49e delete view v_synthese_validation_forwebapp
      [x] ┣┓ dde31e76ce45 remove old profile function
      [x]  ┃ 61e46813d621 Update synthese sensitivity
      [x]  ┃ dfec5f64ac73 Fix sensitivity algorithm
      [x]  ┃ ac08dcf3f27b Do not auto-compute diffusion_level
      [x] ┃ 30edd97ae582 Remove gn_export.t_config_exports
      [x] ┗┛ 1dbc45309d6e Merge sensitivity
    [geonature-samples ✓]
      [x] ─ 3d0bf4ee67d1 geonature samples
    [habitats ✓]
      [x] ─ 62e63cd6135d create ref_habitats schema
    [habitats_inpn_data ✓]
      [x] ┰ 46e91e738845 insert inpn data in ref_habitats schema
      [x] ┸ 805442837a68 correction on habref data
    [ign_bd_alti ✓]
      [x] ─ 1715cf31a75d Insert default French DEM (IGN 250m BD alti)
    [ign_bd_alti_vector]
      [ ] ─ 87651375c2e8 Vectorize French DEM
    [nomenclatures ✓]
      [x] ┰ 6015397d686a create ref_nomenclature schema 1.3.9
      [x] ┃ 11e7741319fd fix ref_nomenclatures.get_default_nomenclature_value
      [x] ┃ f8c2c8482419 fix ref_nomenclatures.get_default_nomenclature_value
      [x] ┸ b820c66d8daa fix ref_nomenclatures.get_nomenclature_label
    [nomenclatures_inpn_data ✓]
      [x] ─ 96a713739fdd insert inpn data in ref_nomenclatures
    [nomenclatures_taxonomie ✓]
      [x] ─ f5436084bf17 add support for taxonomy into ref_nomenclatures
    [nomenclatures_taxonomie_inpn_data ✓]
      [x] ─ a763fb554ff2 insert taxonomic inpn data in ref_nomenclatures
    [occhab ✓]
      [x] ─ 2984569d5df6 create occhab schema
    [occhab-samples]
      [ ] ─ 21f661247023 insert occhab sample data
    [occtax ✓]
      [x] ┰ 29c199e07eaa create occtax schema
      [x] ┃ addb71d8efad create occtax export view
      [x] ┃ f57107d2d0ad fix get_default_nomenclature_value
      [x] ┃ 494cb2245a43 trigger comportement
      [x] ┸ 944072911ff7 update synthese data (bug occtax trigger)
    [occtax-samples ✓]
      [x] ─ cce08a64eb4f insert occtax sample data
    [occtax-samples-test]
      [ ] ─ 2a0ab7644e1c occtax sample test
    [ref_geo ✓]
      [x] ┰ 6afe74833ed0 ref_geo schema
      [x] ┃ e0ac4c9f5c0a add indexes on FK referencing l_areas.id_area
      [x] ┸ 4882d6141a41 add regions in area types
    [ref_geo_fr_departments ✓]
      [x] ─ 3fdaa1805575 Insert French departments in ref_geo
    [ref_geo_fr_municipalities ✓]
      [x] ─ 0dfdbfbccd63 Insert French municipalities in ref_geo
    [ref_geo_fr_regions ✓]
      [x] ─ d02f4563bebe Insert French regions in ref_geo
    [ref_geo_fr_regions_1970 ✓]
      [x] ─ 05a0ae652c13 Insert French regions 1970-2016 in ref_geo
    [ref_geo_inpn_grids_1 ✓]
      [x] ─ 586613e2faeb Insert INPN 1×1 grids in ref_geo
    [ref_geo_inpn_grids_10 ✓]
      [x] ─ ede150d9afd9 Insert INPN 10×10 grids in ref_geo
    [ref_geo_inpn_grids_5 ✓]
      [x] ─ 7d6e98441e4c Insert INPN 5×5 grids in ref_geo
    [ref_sensitivity_inpn ✓]
      [x] ─ 7dfd0a813f86 Insert INPN rules in sensitivity referential
    [sql_utils ✓]
      [x] ─ 3842a6d800a0 Add public shared functions
    [taxhub ✓]
      [x] ─ fa5a90853c45 taxhub
    [taxhub-admin ✓]
      [x] ─ 3fe8c07741be taxhub
    [taxonomie ✓]
      [x] ┰ 9c2c0254aadc create taxonomie schema version 1.8.1
      [x] ┃ 7540702c6407 cd_ref utility functions
      [x] ┃ 98035939bc0d find_all_taxons_parents
      [x] ┃ c93cbb35cfe4 set default value for id_liste
      [x] ┸ 4fb7e197d241 create taxonomie.v_bdc_status view
    [taxonomie_attributes_example]
      [ ] ─ aa7533601e41 add attributes exemple to taxonomie
    [taxonomie_inpn_data ✓]
      [x] ─ f61f95136ec3 insert inpn data in taxonomie schema
    [taxonomie_taxons_example]
      [ ] ─ 8222017dc3f6 add taxons exemple to taxonomie
    [usershub ✓]
      [x] ┰ 9445a69f2bed UsersHub
      [x] ┸ 6ec215fe023e upgrade utilisateurs schema
    [usershub-samples ✓]
      [x] ─ f63a8f44c969 UsersHub samples data
    [utilisateurs ✓]
      [x] ┰ fa35dfe5ff27 utilisateurs schema 1.4.7 (usershub 2.1.3)
      [x] ┃ 830cc8f4daef add additional_data field to bib_organismes
      [x] ┃ 5b334b77f5f5 fix v_roleslist_forall_applications
      [x] ┃ 951b8270a1cf add unique constraint on bib_organismes.uuid_organisme
      [x] ┸ 10e87bc144cd get_id_role_by_name()
    [utilisateurs-samples ✓]
      [x] ─ 72f227e37bdf utilisateurs sample data

La commande ``autoupgrade`` permet de mettre automatiquement à jour toutes les branches dont au moins une révision est appliquée lorsque celles-ci possèdent une ou plusieurs révisions non appliquées.
Cette commande est appelé par le script ``migration.sh`` lors d’une mise à jour de la base de données.
Elle accepte également les paramètres ``-x`` qui sont alors fournis à la commande ``upgrade`` lorsque appelé sur chaque branche en retard.

La commande ``heads`` permet de lister l’ensemble des branches disponibles, ainsi que la dernière révision disponible pour chaque branche :

.. code-block::

    $ geonature db heads
    e0ac4c9f5c0a (ref_geo) (effective head)
    7077aa76da3d (geonature) (head)
    586613e2faeb (ref_geo_inpn_grids_1) (head)
    1715cf31a75d (ign_bd_alti) (effective head)
    3d0bf4ee67d1 (geonature-samples) (head)
    0dfdbfbccd63 (ref_geo_fr_municipalities) (head)
    7d6e98441e4c (ref_geo_inpn_grids_5) (head)
    87651375c2e8 (ign_bd_alti_vector) (head)
    3fdaa1805575 (ref_geo_fr_departments) (effective head)
    ede150d9afd9 (ref_geo_inpn_grids_10) (head)
    3842a6d800a0 (sql_utils) (effective head)
    951b8270a1cf (utilisateurs) (effective head)
    72f227e37bdf (utilisateurs-samples) (effective head)
    f5436084bf17 (nomenclatures_taxonomie) (effective head)
    6015397d686a (nomenclatures) (effective head)
    96a713739fdd (nomenclatures_inpn_data) (effective head)
    a763fb554ff2 (nomenclatures_taxonomie_inpn_data) (effective head)
    4fb7e197d241 (taxonomie) (effective head)
    aa7533601e41 (taxonomie_attributes_example) (head)
    3fe8c07741be (taxhub-admin) (head)
    8222017dc3f6 (taxonomie_taxons_example) (head)
    f61f95136ec3 (taxonomie_inpn_data) (effective head)
    fa5a90853c45 (taxhub) (effective head)
    46e91e738845 (habitats_inpn_data) (effective head)
    62e63cd6135d (habitats) (effective head)

La commande ``history`` permet de lister l’ensemble de fichier de révisions. Il est également possible de lister les révisions devant être appliqué pour passer d’un état à un autre. Par exemple, voici la liste des révisions à appliquer pour passer d’une base de données vierge (``base``) à une base avec la branche ``nomenclatures_inpn_data`` à jour (``head``) :

.. code-block::

    $ geonature db history -r base:nomenclatures_inpn_data@head
    <base> (6015397d686a) -> 96a713739fdd (nomenclatures_inpn_data) (effective head), insert inpn data in ref_nomenclatures
    <base> (fa35dfe5ff27, 3842a6d800a0) -> 6015397d686a (nomenclatures) (effective head), create ref_nomenclature schema 1.3.9
    <base> -> 3842a6d800a0 (sql_utils) (effective head), Add public shared functions
    <base> -> fa35dfe5ff27 (utilisateurs), utilisateurs schema 1.4.7 (usershub 2.1.3)

Si vous avez déjà une base de données existante correspondant à une installation de GeoNature en version 2.7.5 et que vous passez à Alembic, vous pouvez l’indiquer grâce à la commande suivante :

.. code-block::

    $ geonature db stamp f06cc80cc8ba

Il est possible que votre base de données contiennent quelques données supplémentaires (référentiel géographique des communes, …), qu’il faut donc indiquer à Alembic aussi.
Reportez-vous aux notes de versions de la release 2.8.0 de GeoNature afin de consulter la liste des révisions à éventuellement « `stamper` ».

Vous pouvez demander à Alembic dans quel état se trouve votre base de données avec la commande ``current`` :

.. code-block::

    $ geonature db current
    62e63cd6135d (effective head)
    f06cc80cc8ba
    3842a6d800a0 (effective head)
    9c2c0254aadc
    72f227e37bdf (effective head)
    fa35dfe5ff27
    6015397d686a (effective head)
    6afe74833ed0
    a763fb554ff2 (effective head)
    f5436084bf17 (effective head)
    46e91e738845 (effective head)
    f61f95136ec3 (effective head)
    96a713739fdd (effective head)

La liste obtenue contient, pour chaque branche, la dernière migration appliqué.
Notons toutefois que Alembic ne stoque pas l’ensemble de cette liste dans la table ``public.alembic_revision``, mais se restreint uniquement aux migrations dont l’application ne peut être déduit des indications de dépendances.

Il est possible que d’afficher les informations liées à une révision avec la commande ``show`` :

.. code-block::

    $ geonature db show f06cc80cc8ba
    Rev: f06cc80cc8ba
    Parent: <base>
    Also depends on: 72f227e37bdf, a763fb554ff2, 46e91e738845, 6afe74833ed0
    Branch names: geonature
    Path: backend/geonature/migrations/versions/f06cc80cc8ba_2_7_5.py

        geonature schemas 2.7.5

        Revision ID: f06cc80cc8ba
        Create Date: 2021-08-10 14:23:55.144250

L’absence de l’indication ``(head)`` à côté du numéro de révision indique qu’il ne s’agit pas de la dernière révision disponible pour la branche ``geonature``.
Vous pouvez alors mettre à jour cette branche avec la commande ``upgrade`` :

.. code-block::

    $ geonature db upgrade geonature@head

Il est possible de monter des branches optionnelles pour, par exemple, bénéficier des mailles 10×10 dans son référentiel géographique :

.. code-block::

    $ geonature db upgrade ref_geo_inpn_grids_10@head -x data-directory=./tmp_geo

L’ensemble des branches disponible est décrit dans la sous-section ci-après.

L’argument ``-x`` permet de fournir des variables à usage des fichiers de migrations. Dans le cas des migrations de données de zones géographiques, celles-ci supporte la variable ``data-directory`` permettant de spécifier où doivent être cherché et éventuellement téléchargé les données géographiques. Si l’argument n’est pas spécifié, un dossier temporaire, supprimé à la fin de la procédure, sera utilisé.

Pour supprimer les mailles 10×10 de son référentiel géographique, on utilisera :

.. code-block::

    $ geonature db downgrade ref_geo_inpn_grids_10@base

Dans le cas d’une branche contenant plusieurs migrations, on pourra appliquer ou dé-appliquer chaque migration individuellement avec ``upgrade branch@+1`` ou ``downgrade branch@-1``. Il est également possible de référencer directement un numéro de migration.

Si l’on souhaite appliquer une migration manuellement, ou si l’on souhaite la modifier, il est possible de passer l’argument ``--sql`` aux commandes ``upgrade`` et ``downgrade`` afin de récupérer le code SQL de la migration. Cela ne fonctionne toutefois pas avec certaines migrations telles que les migrations de données géographique en raison d’import SQL nécessitant de manipuler directement le curseur SQLAlchemy.

Pour créer un nouveau fichier de migration afin d’y placer ses évolutions de la base de données, on utilisera la commande suivante :

.. code-block::

    $ geonature db revision -m "add table gn_commons.t_foo" --head geonature@head
      Generating […]/backend/geonature/migrations/versions/31250092bce3_add_table_gn_commons_t_foo.py ...  done

La `documentation d’Alembic <https://alembic.sqlalchemy.org/en/latest/ops.html>`_ liste les opérations prises en charge.
Certaines opérations complexes telles que la création de trigger ne sont pas prévu, mais il reste toujours possible d’executer du SQL directement avec l’opérateur ``op.execute``.


Description des branches
````````````````````````

Cette section liste les branches Alembic disponibles et leur impacte sur la base de données.

* ``sql_utils`` : Fournie quelques fonctions SQl utilitaires dans le schéma ``public``. Fournie par Utils-Flask-SQLAlchemy.
* ``geonature`` : Crée les schémas propres à GeoNature (``gn_commons``, ``gn_synthese``, …).
* ``geonature-samples`` : Insert quelques données d’exemple en base.
* ``taxonomie`` : Crée le schéma ``taxonomie``. Fournie par TaxHub.
* ``taxonomie_inpn_data`` : Insert le référentiel TAXHUBv14 en base. Fournie par TaxHub.
* ``taxonomie_attributes_example`` : Insert quelques attributs d’exemple en base. Fournie par TaxHub.
* ``taxonomie_taxons_example`` : Insert quelques taxons d’exemple en base. Fournie par TaxHub.
* ``nomenclatures`` : Crée le schéma ``ref_nomenclatures``. Fournie par Nomenclature-api-module.
* ``nomenclatures_inpn_data`` : Insert le référentiel des nomenclatures de l’INPN en base. Fournie par Nomenclature-api-module.
* ``nomenclatures_taxonomie`` : Complète le schéma ``ref_nomenclatures`` pour accueillir les nomenclatures liées à la taxonomie.
* ``nomenclatures_taxonomie_inpn_data`` : Insert les nomenclatures liées à la taxonomie en base.
* ``utilisateurs`` : Installe le schéma ``utilisateurs``. Fournie par UsersHub-authentification-module.
* ``utilisateurs-samples`` : Insert des données d’exemples (utilisateurs, groupes) dans le schéma ``utilisateurs``. Fournie par UsersHub-authentification-module.
* ``habitats`` : Crée le schéma ``ref_habitats``. Fournie par Habref-api-module.
* ``habitats_inpn_data`` : Insert le référentiel HABREF de l’INPN en base. Fournie par Habref-api-module.
* ``ref_geo`` : Crée le schéma ``ref_geo``.
* ``ref_sensitivity_inpn`` : Insère le référentiel de sensbilité de l’INPN en base.

Si vous utilisez TaxHub, vous pouvez être intéressé par les branches suivantes :

* ``taxhub`` : Déclare l’application TaxHub dans la liste des applications. Fournie par TaxHub.
* ``taxhub-admin`` : Associe le groupe « Grp_admin » issue des données d’exemple à l’application UsersHub et au profil « Administrateur » permettant aux utilisateurs du groupe de se connecter à TaxHub. Fournie par TaxHub.

Si vous utilisez UsersHub, vous pouvez être intéressé par les branches suivantes :

* ``usershub`` : Déclare l’application UsersHub dans la liste des applications. Fournie par UsersHub.
* ``usershub-samples`` : Associe le groupe « Grp_admin » issue des données d’exemple à l’application UsersHub et au profil « Administrateur » permettant aux utilisateurs du groupe de se connecter à UsersHub. Fournie par UsersHub.

Les branches ci-après sont totalement optionnelles :

* ``ref_geo_inpn_grids_1`` : Insert les mailles 1×1 km (INPN) dans le référentiel géographique (type de zone ``M1``).
* ``ref_geo_inpn_grids_5`` : Insert les mailles 5×5 km (INPN) dans le référentiel géographique (type de zone ``M5``).
* ``ref_geo_inpn_grids_10`` : Insert les mailles 10×10 km (INPN) dans le référentiel géographique (type de zone ``M10``).
* ``ref_geo_fr_municipalities`` : Insert les municipalités française (IGN février 2020) dans le référentiel géographique (type de zone ``COM``).
* ``ref_geo_fr_departments`` : Insert les départements français (IGN février 2020) dans le référentiel géographique (type de zone ``DEP``).
* ``ign_bd_alti`` : Insert le modèle numérique de terrain (MNT) de l’IGN en base.
* ``ign_bd_alti_vector`` : Vectorise le MNT.

Note : pour plusieurs fichiers de révisions, notamment lié au référentiel géographique ou nécessitant des données INPN, il est nécessaire de télécharger des ressources externes. Il est possible d’enregistrer les données téléchargé (et ne pas les re-télécharger si elles sont déjà présentes) avec ``-x data-directory=…`` :

.. code-block::

    $ geonature db upgrade …@head -x data-directory=./data/


Gestion des droits
""""""""""""""""""

Accès à GeoNature et CRUVED
```````````````````````````

Les comptes des utilisateurs, leur mot de passe, email, groupes et leur accès à l'application GeoNature est géré de manière centralisée dans UsersHub. Pour qu'un rôle (utilisateur ou groupe) ait accès à GeoNature, il faut lui attribuer un profil de "Lecteur" dans l'application GeoNature, grâce à l'application UsersHub.

La gestion des droits (permissions) des rôles, spécifique à GeoNature, est ensuite gérée dans un schéma (``gn_permissions``) et un module de GeoNature dédié. 

Les permissions des groupes et utilisateurs peuvent en effet être administrées dans le module "Admin / Administration des permissions" de GeoNature.
Dans la version 1 de GeoNature, il était possible d'attribuer des droits selon 6 niveaux à des rôles (utilisateurs ou groupes). Pour la version 2 de GeoNature, des évolutions ont été réalisées pour étendre les possibilités d'attribution de droits et les rendre plus génériques.

La gestion des droits dans GeoNature, comme dans beaucoup d'applications, est liée à des actions (Create / Read / Update / Delete aka CRUD). Pour les besoins  métiers de l'application nous avons rajouté deux actions : "Valider" et "Exporter", ce qui donne le CRUVED : Create / Read / Update / Validate / Export / Delete.

Sur ces actions, on peut appliquer des "portées":

- Portée 1 = "Mes données". Cela concerne les données sur lesquels je suis :
   - observateur 
   - personne ayant effectuée la saisie de la données
   - personnelement acteur du jeu de données de la donnée
   - personne ayant saisi le JDD de la donnée
- Portée 2 = Les données de mon organisme. Portée 1 + :
   - les données sur lesquels mon organisme est acteur du JDD de la donnée
- Portée 3 = Toute les données
   - Toute les données : aucun filtre n'est appliqué


Exemple :

- Utilisateur 1 peut effectuer l'action "DELETE" sur la portée "SES DONNEES"
- Utilisateur Admin peut effectuer l'action "UPDATE" sur la portée "TOUTES LES DONNEES"

Enfin ces permissions vont pouvoir s'attribuer à l'ensemble de l'application GeoNature et/ou à un module.

On a donc le quatriptique : Un utilisateur / Une action / Une portée / Un module

**NB** : certains objets comme les JDD et CA sont transversal à tout GeoNature (ils sont utilisés dans tous les modules: saisie, synthese, métadonnées, dashbord), il sont donc contrôlé par les permissions du "module" GeoNature

Cas particulier de l'action "C"
```````````````````````````````

| Dans les modules de saisie, on veut que des utilisateurs puissent saisir uniquement dans certains JDD.
| La liste des JDD ouvert à la saisie est contrôlée par l'action "CREATE" du module dans lequel on se trouve. 
| Comme il n'est pas "normal" de pouvoir saisir dans des JDD sur lesquels on n'a pas les droit de lecture, la portée de l'action "CREATE" vient simplement réduire la liste des JDD surlesquels on a les droits de lecture ("READ").
| Même si la portée de l'action "CREATE" sur le module est supérieure à l'action "READ", l'utilisateur ne vera que les JDD surlesquels il a des droits de lecture

Récapitulatif
`````````````

- Dans GeoNature V2 on peut attribuer à un role des actions possibles, sur lesquels on peut ajouter des filtres, dans un module ou sur toute l'application GeoNature (définis dans ``gn_permissions.cor_role_action_filter_module_object``).
- 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- Différents types de filtre existent. Le plus courant est le filtre de type "SCOPE" (portée) : 3 portées sont attribuables à des actions: Mes données / Les données de mon organisme / Toutes les données.
- Une vue permet de retourner toutes les actions, leurs filtres et leurs modules de GeoNature pour tous les rôles (``gn_permissions.v_users_permissions``)
- Des fonctions PostgreSQL ont aussi été intégrées pour faciliter la récupération de ces informations (``gn_permissions.cruved_for_user_in_module``, ``gn_permissions.does_user_have_scope_permission``, ...)
- Les permissions attribuées à un module surchargent les permission attribuées sur l'ensemble de l'application par un mécanisme d'héritage. Par défaut et en l'absence de permissions, tous les modules héritent des permissions de GeoNature. Attention cependant aux utilisateurs appartenant à plusieurs groupes. Si un CRUVED est définit pour un module à un seul de ses groupes, c'est ce CRUVED qui sera pris en compte. En effet, le mécanisme d'héritage ne fonctionne plus lorsqu'on surcouche implicitement le CRUVED d'un module pour un groupe.
- Si un utilisateur n'a aucune action possible sur un module, alors il ne lui sera pas affiché et il ne pourra pas y accéder
- Il est aussi possible de ne pas utiliser UsersHub pour gérer les utilisateurs et de connecter GeoNature à un CAS (voir configuration). Actuellement ce paramétrage est fonctionnel en se connectant au CAS de l'INPN (MNHN)

.. image :: _static/schema_cruved.png

A noter que toutes les actions et toutes les portées n'ont pas été implémentées dans tous les modules. Elles le sont en fonction des besoins de chaque module.

TODO : Lister les permissions implémentées dans chaque module.


Accès public
""""""""""""

Cette section de la documentation concerne l'implémentation d'un utilisateur-lecteur pour votre instance GeoNature, permettant d'y donner accès sans authentification.

Etapes :

1/ UsersHub :

- Aller dans la section ``Utilisateurs``
- Créer un utilisateur 
- Définir un identifiant et un mot de passe (par défaut utilisateur 'public' et mot de passe 'public')
- Aller ensuite dans la section `Applications`
- Pour GeoNature, cliquer sur le premier icône 'Voir les membres'
- Cliquer sur ajouter un rôle 
- Choisir l'utilisateur juste créé
- Attribuer le rôle 1, 'lecteur' 

2/ Configuration GeoNature : 

- Reporter identifiant et mot de passe dans le fichier de configuration de GeoNature (``config/geonature_config.toml``)

.. code:: 

  PUBLIC_LOGIN = 'public'
  PUBLIC_PASSWORD = 'public'

- Mettre à jour la configuration de GeoNature

.. code:: 

  $ source backend/venv/bin/activate
  $ geonature update_configuration
  $ sudo systemctl restart geonature

A ce moment-là, cet utilisateur a tous les droits sur GeoNature.
Il s'agit maintenant de gérer ses permissions dans GeoNature même. 

3/ GeoNature 

- Se connecter à GeoNature avec un utilisateur administrateur
- Aller dans le module Admin
- Cliquer sur 'Gestion des permissions'
- Choisissez l'utilisateur sélectionné 
- Editer le CRUVED pour chacun des modules de l'instance. Passer à 0 tous les droits et tous les modules devant être supprimés. Laisser '3' pour les modules d'intérêt. 

Nomenclatures
"""""""""""""

- Toutes les valeurs des listes déroulantes sont gérées dans une table générique ``ref_nomenclatures.t_nomenclatures``
- Elles s'appuient sur les nomenclatures du SINP (http://standards-sinp.mnhn.fr/nomenclature/) qui peuvent être désactivées ou completées
- Chaque nomenclature est associée à un type, et une vue par type de nomenclature a été ajoutée pour simplifier leur usage
- Ces nomenclatures sont gérées dans un sous-module pour pouvoir les réutiliser (ainsi que leur mécanisme) dans d'autres applications : https://github.com/PnX-SI/Nomenclature-api-module/
- Les identifiants des nomenclatures et des types de nomenclature sont des serials (entiers auto-incrémentés) et ne sont pas prédéfinis lors de l'installation, ni utilisées en dur dans le code des applications. En effet, les nomenclatures peuvent varier en fonction des structures. On utilise le ``cd_nomenclature`` et le ``mnémonique`` du type de nomenclature pour retrouver dynamiquement l'``id_nomenclature`` d'une nomenclature. C'est cependant cet identifiant qu'on stocke au niveau des données pour garantir l'intégrité référentielle
- Chaque nomenclature peut être associée à un règne ou un group2inpn (``ref_nomenclatures.cor_taxref_nomenclature``) pour proposer des nomenclatures correspondants à un taxon
- Les valeurs par défaut sont définies dans chaque module
- Pour Occtax c'est dans ``pr_occtax.defaults_nomenclatures_value``. Elles peuvent être définies pour chaque type de nomenclature ainsi que par organisme, règne et/ou group2inpn
- Si organisme = 0 alors la valeur par défaut s'applique à tous les organismes. Idem pour les règnes et group2inpn
- La fonction ``pr_occtax.get_default_nomenclature_value`` permet de renvoyer l'id de la nomenclature par défaut
- Ces valeurs par défaut sont aussi utilisées pour certains champs qui sont cachés (statut_observation, floutage, statut_validation...) mais ne sont donc pas modifiables par l'utilisateur
- Il existe aussi une table pour définir des valeurs par défaut générales de nomenclature (``ref_nomenclatures.defaults_nomenclatures_value``)
- Elles peuvent être administrées dans le module Admin de GeoNature

Métadonnées
"""""""""""

- Elles sont gérées dans le schéma ``gn_meta`` basé sur le standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/)
- Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles
- Elles peuvent être administrées dans le module Métadonnées de GeoNature

Données SIG
"""""""""""

- Le schéma ``ref_geo`` permet de gérer les données SIG (zonages, communes, MNT...) de manière centralisée, potentiellement partagé avec d'autres BDD
- Il contient une table des zonages, des types de zonages, des communes, des grilles (mailles) et un MNT raster ou vectorisé (https://github.com/PnX-SI/GeoNature/issues/235)
- La fonction ``ref_geo.fct_get_area_intersection`` permet de renvoyer les zonages intersectés par une observation en fournissant sa géométrie
- La fonction ``ref_geo.fct_get_altitude_intersection`` permet de renvoyer l'altitude min et max d'une observation en fournissant sa géométrie
- Les intersections d'une observation avec les zonages sont stockées au niveau de la synthèse (``gn_synthese.cor_area_synthese``) et non au niveau de la donnée source pour alléger et simplifier leur gestion


Profils de taxons
"""""""""""""""""

Introduction
````````````

GeoNature dispose d'un mécanisme permettant de calculer des profils pour chaque taxon en se basant sur les données validées présentes dans la Synthèse de l'instance.

Ces profils sont stockés dans un schéma dédié ``gn_profiles``, et plus précisément dans les deux vues matérialisées suivantes :

1. La vue matérialisée ``gn_profiles.vm_valid_profiles`` comporte des informations générales sur chaque taxon :

- L'aire d'occurrences
- Les altitudes extrêmes d'observation du taxon
- Les dates de première et de dernière observation
- Le nombre de données valides pour le taxon considéré

2. La vue matérialisée ``gn_profiles.vm_cor_taxon_phenology`` comporte les "combinaisons" d'informations relatives à la phénologie des taxons (voir détail des calculs ci-dessous) :

- La période d'observation
- Le stade de vie (activable ou non)
- Les altitudes min et max
- Les altitudes "fiables" en écartant les valeurs extrêmes
- Le nombre de données correspondant à cette "combinaison phénologique"

La fonction ``gn_profiles.refresh_profiles()`` permet de rafraichir ces vues matérialisées.

Pour lancer manuellement cette fonction, ouvrez une console SQL et exécutez la requête ``SELECT gn_profiles.refresh_profiles();``.

Cette fonction est aussi diponible en tant que fonction GeoNature qu'il est préférable d'utiliser : ``geonature profiles update``

Pour automatiser l'éxecution de cette fonction (tous les jours à minuit dans cet exemple), :ref:`créer une tâche planfiée<cron>`.

Usage
`````

Pour chaque taxon (cd_ref) disposant de données dans la vue ``gn_profiles.v_synthese_for_profiles`` (vue filtrée basée sur la synthèse de l'instance), un profil est généré. Il comporte l'aire d'occurrence, les limites altitudinales et les combinaisons phénologiques jugées cohérentes sur la base des données disponibles.

Ces profils sont déclinés sur :

- Le module de validation permet d'attirer l'attention des validateurs sur les données qui sortent du "cadre" déjà connu pour le taxon considéré, et d'apporter des éléments de contexte en complément de la donnée en cours de validation
- Le module Synthèse (fiche d'information, onglet validation) permet d'apporter des éléments de contexte en complément des données brutes consultées
- Le module Occtax permet d'alerter les utilisateurs lors de la saisie de données qui sortent du "cadre" déjà connu pour un taxon considéré

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/validation.png
.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/contexte_donnee.png

Plusieurs fonctions permettent de vérifier si une donnée de la synthèse est cohérente au regard du profil du taxon en question :

- ``gn_profiles.check_profile_distribution`` : permet de vérifier si la donnée testée est totalement incluse dans l'aire d'occurrences déjà connue pour son taxon.
- ``gn_profiles.check_profile_phenology`` : permet de vérifier si la phénologie d'une donnée (période, stade de vie, altitudes) est une combinaison déjà connue dans le profil du taxon
- ``gn_profiles.check_profile_altitudes`` : permet de vérifier si une donnée est bien située dans la fourchette d'altitudes connue pour le taxon en question


Configuration et paramétrage
````````````````````````````

*Paramètres de calcul des profils* :

Le calcul des profils de taxons repose sur plusieurs variables, paramétrables soit pour tout le mécanisme, soit pour des taxons donnés.

Les paramètres généraux dans la table ``gn_profiles.t_parameters`` :

- Le paramètre ``id_valid_status_for_profiles`` : permet de lister les ``id_nomenclatures`` des statuts de validation à prendre en compte pour les calculs des profils. Par exemple, en ne listant que les identifiants des nomenclatures "Certain -très probable" et "Probable", seules ces données valides seront prises en compte lors du calcul des profils (comportement par défaut). En listant tous les identifiants des nomenclatures des statuts de validation, l'ensemble des données alimenteront les profils de taxons.
- Le paramètre ``id_rang_for_profiles`` : permet de lister les ``id_rang`` de Taxref à prendre en compte pour les calculs des profils. Par défaut, les profils ne sont calculés que pour les cd_ref correspondant à des Genres, Espèces et Sous-espèces.
- Le paramètre ``proportion_kept_data`` définit le pourcentage de données à conserver lors du calcul des altitudes valides (``gn_profiles.vm_cor_taxon_phenology``), en retirant ainsi les extrêmes. Ce paramètre, définit à 95% par défaut, doit être compris entre 51 et 100% (voir détails ci-après).

Les deux premiers paramètres permettent de filtrer les données dans la vue ``gn_profiles.v_synthese_for_profiles``. Cette vue comporte les données de la synthèse qui répondent aux paramètres et qui alimenteront les profils de taxons. Les clauses WHERE de cette vue peuvent être adaptées pour filtrer les données sur davantage de critères et répondre aux besoins plus spécifiques, mais sa structure doit rester inchangée.

Les paramètres définis par taxon le sont dans la table ``gn_profiles.cor_taxons_profiles_parameters`` :

Les profils peuvent être calculés avec des règles différentes en fonction des taxons. Ceux-ci sont définis au niveau du cd_nom, à n'importe quel rang (espèce, famille, règne etc). Ils seront appliqués de manière récursive à tous les taxons situés "sous" le cd_ref paramétré.

Dans le cas où un taxon hérite de plusieurs règles (une définie pour son ordre et une autre définie pour sa famille par exemple), les paramètres définis au plus proche du taxon considéré seront pris en compte.

Par exemple, s'il existe des paramètres pour le phylum "Animalia" (cd_nom 183716) et d'autres pour le renard (cd_nom 60585), les paramètres du renard seront appliqués en priorité pour cette espèce, mais les paramètres Animalia s'appliqueront à tous les autres animaux.

Les règles appliquables à chaque taxon sont récupérées par la fonction ``gn_profiles.get_profiles_parameters(cdnom)``.

Pour chaque cd_nom, il est ainsi possible de définir les paramètres suivants :

- ``spatial_precision`` : La précision spatiale utilisée pour calculer les profils. Elle est exprimée selon l'unité de mesure de la projection locale de l'instance GeoNature : mètres pour le Lambert93, degré pour le WGS84 etc. Elle définit à la fois la taille de la zone tampon appliquée autour de chaque observation pour définir l'aire d'occurrences du taxon, ainsi que la distance maximale admise entre le centroïde et les limites d'une observation pour qu'elle soit prise en compte lors du calcul des profils (évite qu'une donnée imprécise valide à elle seule une grande zone).
- ``temporal_precision_days`` : La précision temporelle en jours utilisée pour calculer les profils. Elle définit à la fois le pas de temps avec lequel la phénologie est calculée, ainsi que la précision temporelle minimale requise (différence entre date début et date fin de l'observation) pour qu'une donnée soit prise en compte dans le calcul des profils. Une précision de 365 jours ou plus permettra de ne pas tenir compte de la période (toutes les données seront dans une unique période de l'année).
- ``active_life_stage`` : Définit si le stade de vie doit être pris en compte ou non lors du calcul des profils.

Par défaut, une précision spatiale de 2000m et une précision spatiale de 10j (décade) sont paramétrés pour tous les phylums, sans tenir compte des stades de vie.

A terme, d'autres variables pourront compléter ces profils : habitats (habref) ou comportement (nidification, reproduction, migration...) notamment.

*Configuration - Activer/désactiver les profils* :

Il est possible de désactiver l'ensemble des fonctionnalités liées aux profils dans l'interface, en utilisant le paramètre suivant dans le fichier ``geonature/config/geonature_config.toml``

::

    [FRONTEND]
      ENABLE_PROFILES = true/false


Calcul des phénologies
``````````````````````

Pour chaque taxon, la phénologie est calculée en croisant dans un premier temps les périodes d'observations et, selon les paramètres, les stades de vie.

Pour chacune des combinaisons obtenues (période x stade de vie), sont alors calculées :

- L'altitude minimale (toutes données comprises)
- L'altitude maximale (toutes données comprises)
- L'altitude minimale fiable (en retirant x% de données extrêmes selon le paramètre ``proportion_kept_data``)
- L'altitude maximale fiable (en retirant x% de données extrêmes selon le paramètre ``proportion_kept_data``)
- Le nombre de données valides correspondantes

*Exclusion des données extrêmes*

Afin que des données exceptionnelles, bien que valides, ne soient pas considérées comme une "norme", les profils permettent d'exclure un certain pourcentage de données extrêmes. Pour ce faire :

- Le nombre de données exclues est systématiquement arrondi à l'entier supérieur, pour les extrêmes "bas" et les extrêmes "hauts"
- Aucune altitude fiable n'est calculée s'il y a davantage de données exclues que de données conservées
- Le paramètre ``proportion_kept_data`` doit donc être compris entre 51 et 100% : en dessous de 50%, le nombre de données supprimées est supérieur au nombre de données conservées, aucune altitude fiable ne sera calculée. Si le paramètre est à 100%, les altitudes fiables seront identiques aux altitudes extrêmes observées pour la période (et le stade) donnés

Il faut donc (1/[1- ``proportion_kept_data`` /100])+1 données pour que des altitudes fiables soient calculées, soit :

- 101 données minimum par période/stade si ``proportion_kept_data`` =99
- 51 données minimum par période/stade si ``proportion_kept_data`` =98
- 21 données minimum par période/stade si ``proportion_kept_data`` =95
- 11 données minimum par période/stade si ``proportion_kept_data`` =90
- 3 données minimum par période/stade si ``proportion_kept_data`` =51


.. include:: sensitivity.rst


Fonctions
"""""""""

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


**gn_profiles**

.. code:: sql

  gn_profiles.get_profiles_parameters(mycdnom integer)
  RETURNS TABLE (cd_ref integer, spatial_precision integer, temporal_precision_days integer, active_life_stage boolean,  distance smallint)
  -- fonction permettant de récupérer les paramètres les plus adaptés (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
  -- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard, les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce


.. code:: sql

  gn_profiles.check_profile_distribution(
      in_geom geometry,
      profil_geom geometry
  )
  RETURNS boolean
  --fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que sa localisation est totalement incluse dans l'aire d'occurrences valide définie par le profil du taxon en question


.. code:: sql

  gn_profiles.check_profile_phenology(
      in_cd_ref integer,
      in_date_min date,
      in_date_max date,
      in_altitude_min integer,
      in_altitude_max integer,
      in_id_nomenclature_life_stage integer,
      check_life_stage boolean
  )
  RETURNS boolean
  --fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que sa phénologie (dates, altitude, stade de vie selon les paramètres) correspond bien à la phénologie valide définie par le profil du taxon en question
  --La fonction renvoie 'false' pour les données trop imprécises (durée d'observation supérieure à la précision temporelle définie dans les paramètres des profils).


.. code:: sql

  gn_profiles.check_profile_altitudes(
    in_alt_min integer,
    in_alt_max integer,
    profil_altitude_min integer,
    profil_altitude_max integer
  )
  RETURNS boolean
  --fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que son altitude se trouve entièrement comprise dans la fourchette altitudinale valide du taxon en question



Tables transversales
""""""""""""""""""""

GeoNature contient aussi des tables de stockage transversales qui peuvent être utilisées par tous les modules. C'est le cas pour la validation, la sensibilité, l'historisation des modifications et les médias.

Cela permet de ne pas avoir à mettre en place des tables et mécanismes dans chaque module, mais de s'appuyer sur un stockage, des fonctions et développements factorisés, centralisés et partagés.

Ces tables utilisent notamment le mécanisme des UUID (identifiant unique) pour retrouver les enregistrements. Depuis une table source (Occtax ou un autre module) on peut retrouver les enregistrements stockées dans les tables transversales en utilisant un ``WHERE <TABLE_TRANSVERSALE>.uuid_attached_row = <MON_UUID_SOURCE>`` et ainsi retrouver l'historique de validation, les médias ou encore la sensibilité associés à une donnée.

Voir https://github.com/PnX-SI/GeoNature/issues/339

Triggers vers la synthèse
"""""""""""""""""""""""""

Voir ceux mis en place de Occtax vers Synthèse.

Cheminement d'une donnée Occtax :

1. Formulaire Occtax
2. Ecriture dans la table ``cor_counting_occtax`` et génération d'un nouvel UUID
3. Trigger d'écriture dans la table verticale ``t_validations`` à partir de la valeur par défaut de la nomenclature de validation (``gn_common.ref_nomenclatures.defaults_nomenclatures_value``)
4. Trigger d'écriture d'Occtax vers la synthèse (on ne maitrise pas l'ordre de ces 2 triggers qui sont lancés en même temps)
5. Trigger de rapatriement du dernier statut de validation de la table verticale vers la synthèse.

Triggers dans la synthèse
"""""""""""""""""""""""""

Version 2.1.0 de GeoNature

.. image :: https://geonature.fr/docs/img/2019-06-triggers-gn_synthese.jpg

**Table : synthese**

Table contenant l’ensemble des données.
Respecte le standard Occurrence de taxon du SINP.

* tri_meta_dates_change_synthese

  - BEFORE INSERT OR UPDATE
  - Mise à jour des champs ``meta_create_date`` et ``meta_update_date``

* tri_insert_cor_area_synthese

  - AFTER INSERT OR UPDATE OF the_geom_local
  - Mise à jour de la table ``cor_area_synthese``
  - Actions :

    1. Si update : suppression des enregistrements de la table ``gn_synthese.cor_area_synthese`` avec l'id_synthese concerné
    2. Insertion des id_areas intersectant la géométrie de la synthèse dans ``gn_synthese.cor_area_synthese``. *Prise en compte de toutes les aires qu’elles soient ou non actives. Manque enable = true*

* tri_del_area_synt_maj_corarea_tax

  - BEFORE DELETE
  - Mise à jour des tables ``cor_area_taxon`` et ``cor_area_synthese``
  - Actions :

    1. Récupération de l’ensemble des aires intersectant la donnée de synthèse
    2. Suppression des enregistrement de ``cor_area_taxon`` avec le cd_nom et les aires concernés
    3. Insertion dans ``cor_area_taxon`` recalculant les max, nb_obs et couleur pour chaque aire pour l’ensemble des données avec les aires concernées et le cd_nom concerné ne correspondant pas à la donnée supprimée
    4. Suppression des enregistrements de ``gn_synthese.cor_area_synthese``

* tri_update_cor_area_taxon_update_cd_nom

  - AFTER UPDATE OF cd_nom
  - Mise à jour de la table cor_area_taxon
  - Actions :

    1. Récupération de l’ensemble des aires intersectant la donnée de synthèse
    2. Recalcul ``cor_area_taxon`` pour l’ancien cd_nom via fonction ``gn_synthese.delete_and_insert_area_taxon``
    3. Recalcul ``cor_area_taxon`` pour le nouveau cd_nom via fonction ``gn_synthese.delete_and_insert_area_taxon``


**Table : cor_area_synthese**

Table contenant l’ensemble des id_areas intersectant les enregistrements de la synthèse

* tri_maj_cor_area_taxon

  - AFTER INSERT OR UPDATE
  - Mise à jour des données de cor_area_taxon
  - Actions :

    1. Récupération du cd_nom en lien avec l’enregistrement ``cor_area_synthese``
    2. Suppression des données de ``cor_area_taxon`` avec le ``cd_nom`` et ``id_area`` concernés
    3. Insertion des données dans ``cor_area_taxon`` en lien avec le ``cd_nom`` et ``id_area``

**Table : cor_observer_synthese**

* trg_maj_synthese_observers_txt

  - AFTER INSERT OR UPDATE OR DELETE
  - Mise à jour du champ ``observers`` de la table ``synthese``
  - Actions :

    1. Construction de la valeur textuelle des observateurs
    2. Mise à jour du champ observer de l’enregistrement de la table ``synthese``

**FONCTIONS**

* delete_and_insert_area_taxon

  - Fonction qui met à jour la table ``cor_area_taxon`` en fonction d’un ``cd_nom`` et d'une liste d'``id area``
  - Actions :

    1. Suppression des enregistrement de la table ``cor_area_taxon`` avec le ``cd_nom`` et les ``id_area`` concernés
    2. Insertion des données dans ``cor_area_taxon``

* color_taxon

  - Fonction qui associe une couleur à une durée
  - *Passer les couleurs en paramètres : table  gn_commons.t_parameters ?*
  - *Passer la fonction en immutable*


Modularité
----------

Chaque module doit avoir son propre schéma dans la BDD, avec ses propres fichiers SQL de création comme le module OccTax : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/data

Côté Backend, chaque module a aussi son modèle et ses routes : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/backend

Idem côté Frontend, où chaque module a sa configuration et ses composants : https://github.com/PnX-SI/GeoNature/tree/develop/contrib/occtax/frontend/app

Mais en pouvant utiliser des composants du Cœur comme expliqué dans la documentation Developpeur.

Plus d'infos sur le développement d'un module : https://github.com/PnX-SI/GeoNature/blob/master/docs/development.rst#d%C3%A9velopper-et-installer-un-gn_module


Configuration
-------------

Pour configurer GeoNature, actuellement il y a :

- Une configuration pour l'installation : ``config/settings.ini``
- Une configuration globale de l'application : ``<GEONATURE_DIRECTORY>/config/geonature_config.toml`` (générée lors de l'installation de GeoNature)
- Une configuration par module : ``<GEONATURE_DIRECTORY>/external_modules/<nom_module>/config/conf_gn_module.toml`` (générée lors de l'installation d'un module)
- Une table ``gn_commons.t_parameters`` pour des paramètres gérés dans la BDD

.. image :: http://geonature.fr/docs/img/admin-manual/administration-geonature.png

Configuration générale de l'application
"""""""""""""""""""""""""""""""""""""""

L'installation de GeoNature génère le fichier de configuration globale ``<GEONATURE_DIRECTORY>/config/geonature_config.toml``. Ce fichier est aussi copié dans le frontend (``frontend/conf/app.config.ts``), à ne pas modifier.

Par défaut, le fichier ``<GEONATURE_DIRECTORY>/config/geonature_config.toml`` est minimaliste et généré à partir des infos présentes dans le fichier ``config/settings.ini``.

Il est possible de le compléter en surcouchant les paramètres présents dans le fichier ``config/default_config.toml.example``.

A chaque modification du fichier global de configuration (``<GEONATURE_DIRECTORY>/config/geonature_config.toml``), il faut regénérer le fichier de configuration du frontend.

Ainsi après chaque modification des fichiers de configuration globale, placez-vous dans le backend de GeoNature (``/home/monuser/GeoNature/backend``) et lancez les commandes :

.. code-block:: console

    source venv/bin/activate
    geonature update_configuration
    sudo systemctl restart geonature
    deactivate

Configuration d'un gn_module
""""""""""""""""""""""""""""

Lors de l'installation d'un module, un fichier de configuration est créé : ``<MODULE_DIRECTORY>/config/conf_gn_module.toml``.

Comme pour la configuration globale, ce fichier est minimaliste et peut être surcouché. Le fichier ``conf_gn_module.toml.example``, situé dans le répertoire ``config`` du module, décrit l'ensemble des variables de configuration disponibles ainsi que leurs valeurs par défaut.

A chaque modification de ce fichier, lancer les commandes suivantes depuis le backend de GeoNature (``/home/monuser/GeoNature/backend``). Le fichier est copié à destination du frontend ``<nom_module>/frontend/app/module.config.ts``, qui est alors recompilé automatiquement.

.. code-block:: console

    source venv/bin/activate
    geonature update_module_configuration <NOM_DE_MODULE>
    deactivate

Exploitation
------------

Logs
""""

* Logs d’installation de GeoNature : ``geonature/install/install.log``
* Logs de GeoNature : ``/var/log/geonature/geonature.log``
* Logs du worker Celery : ``/var/log/geonature/geonature-worker.log``
* Logs de TaxHub : ``/var/log/taxhub.log``
* Logs de UsersHub : ``/var/log/usershub.log``

Commandes GeoNature
"""""""""""""""""""

GeoNature est fourni avec une série de commandes pour administrer l'application.
Pour les exécuter, il est nécessaire d'être dans le virtualenv python de GeoNature

.. code-block:: console

    cd <GEONATURE_DIRECTORY>/backend
    source venv/bin/activate

Le préfixe (venv) se met alors au début de votre invite de commande.

Voici la liste des commandes disponibles (aussi disponibles en tapant la commande ``geonature --help``) :

- ``activate_gn_module`` : Active un gn_module installé (Possibilité d'activer seulement le backend ou le frontend)
- ``deactivate_gn_module`` : Désactive gn_un module activé (Possibilté de désactiver seulement le backend ou le frontend)
- ``dev_back`` : Lance le backend en mode développement
- ``generate_frontend_module_route`` : Génère ou regénère le fichier de routing du frontend en incluant les gn_module installés (Fait automatiquement lors de l'installation d'un module)
- ``install_gn_module`` : Installe un gn_module
- ``update_configuration`` : Met à jour la configuration du cœur de l'application. A exécuter suite à une modification du fichier ``geonature_config.toml``
- ``update_module_configuration`` : Met à jour la configuration d'un module. A exécuter suite à une modification du fichier ``conf_gn_module.toml``.

Effectuez ``geonature <nom_commande> --help`` pour accéder à la documentation et à des exemples d'utilisation de chaque commande.

Démarrer / arrêter les API
""""""""""""""""""""""""""

* Démarrer GeoNature : ``systemctl start geonature``
* Arrêter GeoNature : ``systemctl stop geonature``
* Redémarrer GeoNature : ``systemctl restart geonature``
* Vérifier l’état de GeoNature : ``systemctl status geonature``

Les mêmes commandes sont disponibles pour TaxHub en remplacant ``geonature`` par ``taxhub``.

Supervision des services
""""""""""""""""""""""""

- Vérifier que les applications GeoNature et TaxHub sont accessibles en http
- Vérifier que leurs services (API) sont lancés et fonctionnent correctement (tester les deux routes ci-dessous).

  - Exemple de route locale pour tester l'API GeoNature : http://127.0.0.1:8000/occtax/defaultNomenclatures qui ne doit pas renvoyer de 404. URL absolue : https://urlgeonature/api/occtax/defaultNomenclatures
  - Exemple de route locale pour tester l'API TaxHub : http://127.0.0.1:5000/api/taxref/regnewithgroupe2 qui ne doit pas renvoyer de 404. URL absolue : https://urltaxhub/api/taxref/regnewithgroupe2

- Vérifier que les fichiers de logs de TaxHub et GeoNature ne sont pas trop volumineux pour la capacité du serveur
- Vérifier que les services nécessaires au fonctionnement de l'application tournent bien (Apache, PostgreSQL)

Maintenance
"""""""""""

Lors d'une opération de maintenance (montée en version, modification de la base de données...), vous pouvez rendre l'application momentanémment indisponible.

Pour cela, désactivez la configuration Apache de GeoNature, puis activez la configuration du mode de maintenance :

.. code-block:: console

    sudo a2dissite geonature
    sudo a2ensite geonature_maintenance
    sudo apachectl restart

A la fin de l'opération de maintenance, effectuer la manipulation inverse :

.. code-block:: console

    sudo a2dissite geonature_maintenance
    sudo a2ensite geonature
    sudo apachectl restart

Attention : ne pas stopper le backend (des opérations en BDD en cours pourraient être corrompues)

- Redémarrage de PostgreSQL

  Si vous effectuez des manipulations de PostgreSQL qui nécessitent un redémarrage du SGBD (``sudo service postgresql restart``), il faut impérativement lancer un redémarrage des API GeoNature et TaxHub pour que celles-ci continuent de fonctionner. Pour cela, lancez les commandes ``sudo systemctl restart geonature`` et ``sudo systemctl restart taxhub`` (GeoNature 2.8+).

  **NB**: Ne pas faire ces manipulations sans avertir les utilisateurs d'une perturbation temporaire des applications.

Paramètres Gunicorn
"""""""""""""""""""

Voici les paramètres de Gunicorn par défaut :

  * ``GUNICORN_PROC_NAME=geonature``
  * ``GUNICORN_NUM_WORKERS=4``
  * ``GUNICORN_HOST=127.0.0.1``
  * ``GUNICORN_PORT=8000``
  * ``GUNICORN_TIMEOUT=30``

Pour modifier une de ces variables, créer un fichier ``environ`` à la racine de votre dossier GeoNature, et indiquer la variable d’environnement avec sa valeur modifiée.

Si vous souhaitez modifier de manière plus avancé la ligne de commande ``gunicorn``, surcouchez le service systemd :

  * Lancez ``sudo systemctl edit geonature`` ce qui va créer le fichier ``/etc/systemd/system/geonature.service.d/override.conf`` et ouvrir un éditeur pour vous permettre de le modifier
  * Indiquez :
  
    .. code::

      [Service]
      ExecStart=
      ExecStart=/path/to/venv/bin/unicorn geonature:create_app() …

    Note : le premier ``ExecStart`` permet de réinitialiser la commande de lancement de gunicorn.
    

Sauvegarde et restauration
--------------------------

Sauvegarde
""""""""""

* Sauvegarde de la base de données :

Les sauvegardes de la BDD sont à faire avec l'utilisateur ``postgres``. Commencer par créer un répertoire et lui donner des droits sur le répertoire où seront faites les sauvegardes.

.. code-block:: console

    $ # Créer le répertoire pour stocker les sauvegardes
    $ mkdir /home/`whoami`/backup
    $ # Ajouter l'utilisateur postgres au groupe de l'utilisateur linux courant pour qu'il ait les droits d'écrire dans les mêmes répertoires
    $ sudo adduser postgres `whoami`
    $ # ajout de droit aux groupes de l'utilisateur courant sur le répertoire `backup`
    $ chmod g+rwx /home/`whoami`/backup

Connectez-vous avec l'utilisateur linux ``postgres`` pour lancer une sauvegarde de la BDD :

.. code-block:: console

    sudo su postgres
    pg_dump -Fc geonature2db  > /home/`whoami`/backup/`date +%Y-%m-%d-%H:%M`-geonaturedb.backup
    exit

Si la sauvegarde ne se fait pas, c'est qu'il faut revoir les droits du répertoire où sont faites les sauvegardes pour que l'utilisateur ``postgres`` puisse y écrire

Opération à faire régulièrement grâce à une tâche cron.

* Sauvegarde des fichiers de configuration :

  .. code-block:: console

    cd /home/`whoami`/geonature/config
    tar -zcvf /home/`whoami`/backup/`date +%Y%m%d%H%M`-geonature_config.tar.gz ./

Opération à faire à chaque modification d'un paramètre de configuration.

* Sauvegarde des fichiers de customisation :

  .. code-block:: console

    cd /home/`whoami`/geonature/frontend/src/custom
    tar -zcvf /home/`whoami`/`date +%Y%m%d%H%M`-geonature_custom.tar.gz ./

Opération à faire à chaque modification de la customisation de l'application.

* Sauvegarde des modules externes :

  .. code-block:: console

    cd /home/`whoami`/geonature/external_modules
    tar -zcvf /home/`whoami`/backup/`date +%Y%m%d%H%M`-external_modules.tar.gz ./

Restauration
""""""""""""

* Restauration de la base de données :

  - Créer une base de données vierge (on part du principe que la base de données ``geonature2db`` n'existe pas ou plus). Sinon adaptez le nom de la BDD et également la configuration de connexion de l'application à la BDD dans ``<GEONATURE_DIRECTORY>/config/geonature_config.toml``

    .. code-block:: console

        sudo -n -u postgres -s createdb -O <MON_USER> geonature2db
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS hstore;"
        sudo -n -u postgres -s psql -d geonature2db -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
        sudo -n -u postgres -s psql -d geonature2db -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;"  # postgis>=3.0 (Debian 11)
        

  - Restaurer la BDD à partir du backup

    .. code-block:: console

        sudo su postgres
        pg_restore -d geonature2db <MY_BACKUP_DIRECTORY_PATH>/201803150917-geonaturedb.backup

* Restauration de la configuration et de la customisation :

  - Décompresser les fichiers précedemment sauvegardés pour les remettre au bon emplacement :

    .. code-block:: console

        sudo rm <GEONATURE_DIRECTORY>/config/*
        cd <GEONATURE_DIRECTORY>/config
        sudo tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_config.tar.gz

        cd /home/<MY_USER>/geonature/frontend/src/custom
        rm -r <MY_USER>/geonature/frontend/src/custom/*
        tar -zxvf <MY_BACKUP_DIRECTORY>/201803150953-geonature_custom.tar.gz

        rm /home/<MY_USER>/geonature/external_modules/*
        cd <GEONATURE_DIRECTORY>/external_modules
        tar -zxvf <MY_BACKUP_DIRECTORY>/201803151036-external_modules.tar.gz

* Relancer l’application GeoNature


Customisation
-------------

La customisation de l'application nécessite de relancer la compilation du frontend à chaque modification. Cette opération étant relativement longue, une solution alternative (mais avancée) consiste à passer le frontend de manière temporaire en mode 'developpement'.

Pour cela exécuter la commande suivante depuis le répertoire ``frontend``

.. code-block:: console

    npm run start -- --host=0.0.0.0 --disable-host-check

L'application est désormais disponible sur un serveur de développement à la même addresse que précédemment, mais sur le port 4200 : http://test.geonature.fr:4200

Ouvrez un nouveau terminal (pour laisser tourner le serveur de développement), puis modifier la variable ``URL_APPLICATION`` dans le fichier ``geonature_config.toml`` en mettant l'adresse ci-dessus et relancer l'application (``sudo supervisorctl restart geonature2`` ou ``sudo systemctl restart geonature``)

A chaque modification d'un fichier du frontend, une compilation rapide est relancée et votre navigateur se rafraichit automatiquement en intégrant les dernières modifications.

Une fois les modifications terminées, remodifier le fichier ``geonature_config.toml`` pour remettre l'URL initiale, relancez l'application (``sudo supervisorctl restart geonature2`` ou ``sudo systemctl restart geonature``), puis relancez la compilation du frontend (``npm run build``). Faites enfin un ``ctrl+c`` dans le terminal ou le frontend a été lancé pour stopper le serveur de développement.

Si la manipulation vous parait compliquée, vous pouvez suivre la documentation qui suit, qui fait relancer la compilation du frontend à chaque modification.

Intégrer son logo
"""""""""""""""""

Le logo affiché dans la barre de navigation de GeoNature peut être modifié dans le répertoire ``geonature/frontend/src/custom/images``. Remplacez alors le fichier ``logo_structure.png`` par votre propre logo, en conservant ce nom pour le nouveau fichier. Le bandeau fait 50px de hauteur, vous pouvez donc mettre une image faisant cette hauteur. Il est également possible de modifier la taille de l'image en CSS dans le fichier ``frontend/src/assets/custom.css`` de la manière suivante:

.. code:: css

  /* la balise img affichant l'image a l'id 'logo-structure */
  #logo-structure {
      height: 50px;
      width: 80px;
  }

Relancez la construction de l’interface :

.. code-block:: console

    cd /home/`whoami`/geonature/frontend
    npm run build


Customiser le contenu
"""""""""""""""""""""

* Customiser le contenu de la page d’introduction :

Le texte d'introduction et le titre de la page d'Accueil de GeoNature peuvent être modifiés à tout moment, sans réinstallation de l'application. Il en est de même pour le bouton d’accès à la synthèse.

Il suffit pour cela de mettre à jour le fichier ``introduction.component.html``, situé dans le répertoire ``geonature/frontend/src/custom/components/introduction``.

Afin que ces modifications soient prises en compte dans l'interface, il est nécessaire de relancer les commandes suivantes :

.. code-block:: console

    cd /home/`whoami`/geonature/frontend
    npm run build


* Customiser le contenu du pied de page :

Le pied de page peut être customisé de la même manière, en renseignant le fichier ``footer.component.html``, situé dans le répertoire ``geonature/frontend/src/custom/components/footer``

De la même manière, il est nécessaire de relancer les commandes suivantes pour que les modifications soient prises en compte :

.. code-block:: console

    cd /home/`whoami`/geonature/frontend
    npm run build

Customiser l'aspect esthétique
""""""""""""""""""""""""""""""

Les couleurs de textes, couleurs de fonds, forme des boutons etc peuvent être adaptées en renseignant le fichier ``custom.css``, situé dans le répertoire ``geonature/frontend/src/assets``.

Pour remplacer la couleur de fond du bandeau de navigation par une image, on peut par exemple apporter la modification suivante :

.. code-block:: css

    html body pnx-root pnx-nav-home mat-sidenav-container.sidenav-container.mat-drawer-container.mat-sidenav-container mat-sidenav-content.mat-drawer-content.mat-sidenav-content mat-toolbar#app-toolbar.row.mat-toolbar
   {
      background :
      url(bandeau_test.jpg)
   }

Dans ce cas, l’image ``bandeau_test.jpg`` doit se trouver dans le répertoire ``geonature/frontend/src``.

Comme pour la modification des contenus, il est nécessaire de relancer la commande suivante pour que les modifications soient prises en compte :

.. code-block:: console

    cd /home/`whoami`/geonature/frontend
    npm run build

Customiser les noms et pictos des modules
"""""""""""""""""""""""""""""""""""""""""

Vous pouvez modifier l'intitulé et le pictogramme des modules dans le menu des modules. Pour cela, adaptez le contenu des champs ``module_label`` et ``module_picto`` (avec des icones de la librairie Font Awesome - https://fontawesome.com) dans la table ``gn_commons.t_modules``.

Exemple :

.. code-block:: SQL

    -- Module Occtax
    UPDATE gn_commons.t_modules SET module_label = 'Occtax' WHERE module_code = 'OCCTAX';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-map-marker' WHERE module_code = 'OCCTAX';
    -- Module Occhab
    UPDATE gn_commons.t_modules SET module_label = 'Occhab' WHERE module_code = 'OCCHAB';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-leaf' WHERE module_code = 'OCCHAB';
    -- Module Import
    UPDATE gn_commons.t_modules SET module_label = 'Import' WHERE module_code = 'IMPORT';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-upload' WHERE module_code = 'IMPORT';
    -- Module Export
    UPDATE gn_commons.t_modules SET module_label = 'Export' WHERE module_code = 'EXPORTS';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-download' WHERE module_code = 'EXPORTS';
    -- Module Dashboard
    UPDATE gn_commons.t_modules SET module_label = 'Dashboard' WHERE module_code = 'DASHBOARD';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-bar-chart' WHERE module_code = 'DASHBOARD';
    -- Module Validation
    UPDATE gn_commons.t_modules SET module_label = 'Validation' WHERE module_code = 'VALIDATION';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-check' WHERE module_code = 'VALIDATION';
    -- Module Monitorings (Suivis)
    UPDATE gn_commons.t_modules SET module_label = 'Suivis' WHERE module_code = 'MONITORINGS';
    UPDATE gn_commons.t_modules SET module_picto = 'fa-eye' WHERE module_code = 'MONITORINGS';

Depuis la version 2.5.0, il est aussi possible de customiser l'ordre des modules dans le menu, par ordre alphabétique par défaut, en renseignant le champs ``gn_commons.t_modules.module_order``.

Customiser les exports PDF
""""""""""""""""""""""""""

Vous pouvez modifier le bandeau et le logo fournis par défaut dans les exports PDF en modifiant les images ``Bandeau_pdf.png`` et ``Logo_pdf.png`` dans ``backend/static/images``.
Le style des fichiers est également customisable grâce au fichier "backend/geonature/static/css/custom.css". La classe ``main-color`` permet notamment de changer la couleur des séparateurs (orange par défaut).

Intégrer des données
--------------------

Référentiel géographique
""""""""""""""""""""""""

GeoNature est fourni avec des données géographiques de base sur la métropôle (MNT national à 250m et communes de métropôle).

**1.** Si vous souhaitez modifier le MNT pour mettre celui de votre territoire :

* Videz le contenu des tables ``ref_geo.dem`` et éventuellement ``ref_geo.dem_vector``
* Uploadez le(s) fichier(s) du MNT sur le serveur
* Suivez la procédure de chargement du MNT en l'adaptant :
  * https://github.com/PnX-SI/GeoNature/blob/master/backend/geonature/migrations/versions/1715cf31a75d_insert_ign_250m_bd_alti_in_dem.py
  * https://github.com/PnX-SI/GeoNature/blob/master/backend/geonature/migrations/versions/87651375c2e8_vectorize_ign_bd_alti.py

*TODO : Procédure à améliorer et simplifier : https://github.com/PnX-SI/GeoNature/issues/235*

Si vous n'avez pas choisi d'intégrer le raster MNT national à 250m fourni par défaut lors de l'installation ou que vous souhaitez le remplacer, voici les commandes qui vous permettront de le faire.

Suppression du MNT par défaut (adapter le nom de la base de données : MYDBNAME).

.. code-block:: console

    sudo -n -u postgres -s psql -d MYDBNAME -c "TRUNCATE TABLE ref_geo.dem;"
    sudo -n -u postgres -s psql -d MYDBNAME -c "TRUNCATE TABLE ref_geo.dem_vector;"

Placer votre propre fichier MNT (ou vos différents fichiers "dalles") dans le répertoire ``/tmp/geonature`` (adapter le nom du fichier et son chemin ainsi que les paramètres en majuscule).

Pour utiliser celui proposé par défaut :

.. code-block:: console

    wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P /tmp/geonature
    unzip /tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d /tmp/geonature
    export PGPASSWORD=MYUSERPGPASS;raster2pgsql -s MYSRID -c -C -I -M -d -t 5x5 /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h localhost -U MYPGUSER -d MYDBNAME
    sudo -n -u postgres -s psql -d MYDBNAME -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;"

Si votre MNT source est constitué de plusieurs fichiers (dalles),
assurez vous que toutes vos dalles ont le même système de projection
et le même format de fichier (tiff, asc, ou img par exemple).
Après avoir chargé vos fichiers dans ``tmp/geonature`` (par exemple),
vous pouvez lancer la commande ``export`` en remplacant le nom des
fichiers par \*.asc :

.. code-block:: console

    export PGPASSWORD=MYUSERPGPASS;raster2pgsql -s MYSRID -c -C -I -M -d -t 5x5 /tmp/geonature/*.asc ref_geo.dem|psql -h localhost -U MYPGUSER -d MYDBNAME

Si vous souhaitez vectoriser le raster MNT pour de meilleures performances lors des calculs en masse de l'altitude à partir de la localisation des observations, vous pouvez le faire en lançant les commandes ci-dessous. Sachez que cela prendra du temps et beaucoup d'espace disque (2.8Go supplémentaires environ pour le fichier DEM France à 250m).

.. code-block:: console

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

Pour des exemples plus précis, illustrées et commentées, vous pouvez consulter les 2 exemples d'import dans cette documentation (Import niveau et Import niveau 2).

Vous pouvez aussi vous inspirer des exemples avancés de migration des données de GeoNature V1 vers GeoNature V2 : https://github.com/PnX-SI/GeoNature/tree/master/data/migrations/v1tov2

* Import depuis SICEN (ObsOcc) : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/sicen
* Import depuis SERENA : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/serena
* Import continu : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/generic
* Import d'un CSV historique (Flavia) : https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/2018-12-csv-vers-synthese-FLAVIA.sql

Création de compte
------------------

Configuration de la création de compte
""""""""""""""""""""""""""""""""""""""

Depuis la version 2.1.0, UsersHub propose une API de création de compte utilisateur. Une interface a été ajoutée à GeoNature pour permettre aux futurs utilisateurs de faire des demandes de création de compte depuis la page d'authentification de GeoNature. Ce mode est activable/désactivable depuis la configuration globale de GeoNature.

Pour des raisons de sécurité, l'API de création de compte est réservée aux utilisateurs "admin" grâce à un token secret. GeoNature a donc besoin de se connecter en tant qu'administrateur à UsersHub pour éxecuter les requêtes d'administration de compte.
Renseigner les paramètres suivants dans le fichier de configuration (``geonature_config.toml``). L'utilisateur doit avoir des droits 6 dans UsersHub

::

    [USERSHUB]
        URL_USERSHUB = 'http://mon_adresse_usershub.fr' # sans slash final
        # Administrateur de mon application
        ADMIN_APPLICATION_LOGIN = "login_admin_usershub"
        ADMIN_APPLICATION_PASSWORD = "password_admin_usershub

Les fonctionnalités de création de compte nécessitent l'envoi d'emails pour vérifier l'identité des demandeurs de compte. Il est donc nécessaire d'avoir un serveur SMTP capable d'envoyer des emails. Renseigner la rubrique ``MAIL_CONFIG`` de la configuration. La description détaillées des paramètres de configuration d'envoie des emails est disponible dans `la documentation de Flask-Mail <https://flask-mail.readthedocs.io/en/latest/#configuring-flask-mail>`_. Exemple :

::

    [MAIL_CONFIG]
        MAIL_SERVER = 'mail.espaces-naturels.fr'
        MAIL_PORT = 465
        MAIL_USE_TLS = false
        MAIL_USE_SSL = true
        MAIL_USERNAME = 'mon_email@email.io'
        MAIL_PASSWORD = 'monpassword'
        MAIL_DEFAULT_SENDER = 'mon_email@email.io'
        MAIL_ASCII_ATTACHMENTS = false

Pour activer cette fonctionnalité (qui est par défaut désactivée), modifier le fichier de configuration de la manière suivante :

NB : tous les paramètres décrits ci-dessous doivent être dans la rubrique ``[ACCOUNT_MANAGEMENT]``

::

    [ACCOUNT_MANAGEMENT]
        ENABLE_SIGN_UP = true

Deux modes sont alors disponibles. Soit l'utilisateur est automatiquement accepté et un compte lui est créé après une confirmation de son email, soit un mail est envoyé à un administrateur pour confirmer la demande. Le compte ne sera crée qu'après validation par l'administrateur. Le paramètre ``AUTO_ACCOUNT_CREATION`` contrôle ce comportement (par défaut le compte créé sans validation par un administrateur: true). Dans le mode "création de compte validé par administrateur", il est indispensable de renseigner un email où seront envoyés les emails de validation (paramètre ``VALIDATOR_EMAIL``)

::

    # automatique
    [ACCOUNT_MANAGEMENT]
        ENABLE_SIGN_UP = true
        AUTO_ACCOUNT_CREATION = true

    # validé par admin
    [ACCOUNT_MANAGEMENT]
        ENABLE_SIGN_UP = true
        AUTO_ACCOUNT_CREATION = false
        VALIDATOR_EMAIL = 'email@validateur.io'

L'utilisateur qui demande la création de compte est automatiquement mis dans un "groupe" UsersHub (par défaut, il s'agit du groupe "En poste"). Ce groupe est paramétrable depuis la table ``utilisateurs.cor_role_app_profil``. (La ligne où ``is_default_group_for_app = true`` sera utilisée comme groupe par défaut pour GeoNature). Il n'est pas en paramètre de GeoNature pusqu'il serait falsifiable via l'API. ⚠️ **Attention**, si vous effectuez une migration depuis une version de GeoNature < 2.2.0, aucun groupe par défaut n'est défini, vous devez définir à la main le groupe par défaut pour l'application GeoNature dans la table ``utilisateurs.cor_role_app_profil``.

Dans le mode "création de compte validé par administrateur", lorsque l'inscription est validée par un administrateur, un email est envoyé à l'utilisateur pour lui indiquer la confirmation de son inscription.
Il est possible de personnaliser le texte de la partie finale de cet email située juste avant la signature à l'aide du paramètre ``ADDON_USER_EMAIL`` (toujours à ajouter à la rubrique ``[ACCOUNT_MANAGEMENT]``).
Vous pouvez utiliser des balises HTML compatibles avec les emails pour ce texte.

::

    [ACCOUNT_MANAGEMENT]
        ADDON_USER_EMAIL = """<p>
            Toute l'équipe de GeoNature vous remercie pour votre inscription.
          </p>"""


Il est également possible de créer automatiquement un jeu de données et un cadre d'acquisition "personnel" à l'utilisateur afin qu'il puisse saisir des données dès sa création de compte via le paramètre ``AUTO_DATASET_CREATION``. Par la suite l'administrateur pourra rattacher l'utilisateur à des JDD et CA via son organisme.

::

    [ACCOUNT_MANAGEMENT]
        AUTO_ACCOUNT_CREATION = true
        ENABLE_SIGN_UP = true
        AUTO_DATASET_CREATION = true


Customisation du formulaire
"""""""""""""""""""""""""""

Le formulaire de création de compte est par défaut assez minimaliste (nom, prénom, email, mot de passe, organisme, remarque).

*NB* l'organisme est demandé à l'utilisateur à titre "informatif", c'est à l'administrateur de rattacher individuellement l'utilisateur à son organisme, et éventuellement de le créer, s'il n'existe pas.

Il est possible d'ajouter des champs au formulaire grâce à un générateur controlé par la configuration. Plusieurs type de champs peuvent être ajoutés (text, textarea, number, select, checkbox mais aussi taxonomy, nomenclature etc...).

L'exemple ci-dessous permet de créer un champs de type "checkbox" obligatoire, avec un lien vers un document (une charte par exemple) et un champ de type "select", non obligatoire. (voir le fichier ``config/geonature_config.toml.example`` pour un exemple plus exhaustif).

::

        [ACCOUNT_MANAGEMENT]
        [[ACCOUNT_MANAGEMENT.ACCOUNT_FORM]]
            type_widget = "checkbox"
            attribut_label = """
              <a target="_blank" href="http://docs.geonature.fr">
                J'ai lu et j'accepte la charte
              </a>"""
            attribut_name = "validate_charte"
            values = [true]
            required = true

        [[ACCOUNT_MANAGEMENT.ACCOUNT_FORM]]
            type_widget = "select"
            attribut_label = "Exemple select"
            attribut_name = "select_test"
            values = ["value1", "value2"]
            required = false


Espace utilisateur
""""""""""""""""""

Enfin, un espace "utilisateur" est accessible lorsque l'on est connecté, permettant de modifier ses informations personnelles, y compris son mot de passe.

Cet espace est activable grâce au paramètre ``ENABLE_USER_MANAGEMENT``. Par défaut, il est désactivé.

::

        [ACCOUNT_MANAGEMENT]
        AUTO_ACCOUNT_CREATION = true
        ENABLE_SIGN_UP = true
        ENABLE_USER_MANAGEMENT = true

Accès public
------------

Cette section de la documentation concerne l'implémentation d'un utilisateur-lecteur pour votre instance GeoNature. 

Etapes :

1/ UsersHub :
   - Aller dans la section `Utilisateurs` 
   - Créer un utilisateur 
   - Définir un identifiant et un mot de passe (par défaut utilisateur 'public' et mot de passe 'public')
   - Aller ensuite dans la section `Applications`
   - Pour GeoNature, cliquer sur le premier icône 'Voir les membres'
   - Cliquer sur ajouter un rôle 
   - Choisir l'utilisateur juste créé
   - Attribuer le rôle 1, 'lecteur' 

2/ Configuration GeoNature : 
  - Reporter identifiant et mot de passe dans le fichier de configuration de GeoNature

.. code-block::

    $ cd config
    $ nano geonature_config.toml
    PUBLIC_LOGIN = 'public'
    PUBLIC_PASSWORD = 'public'
..

   - Mettre à jour la configuration de GeoNature

.. code-block::

    $ source backend/venv/bin/activate
    $ geonature update_configuration
    $ sudo systemctl restart geonature
..

A ce moment là, cet utilisateur a tous les droits sur GeoNature.
Il s'agit donc de gérer ses permissions dans GeoNature même. 

3/ GeoNature 

   - Se connecter à GeoNature avec un utilisateur administrateur
   - Aller dans le module Admin
   - Cliquer sur 'Gestion des permissions'
   - Choisissez l'utilisateur sélectionné 
   - Editer le CRUVED pour chacun des modules de l'instance. Passer à 0 tous les droits et tous les modules devant être supprimés. Laisser '3' pour les modules d'intérêt. 


Module OCCTAX
-------------

Installer le module
"""""""""""""""""""

Le module est fourni par défaut avec l'installation de GeoNature.

Si vous l'avez supprimé, lancez les commandes suivantes depuis le repertoire ``backend`` de GeoNature

.. code-block:: console

    source venv/bin/activate
    geonature install_gn_module /home/<mon_user>/geonature/contrib/occtax occtax


Configuration du module
"""""""""""""""""""""""

Le fichier de configuration du module se trouve ici : ``<GEONATURE_DIRECTORY>/external_modules/occtax/config/conf_gn_module.toml``.

Pour voir l'ensemble des variables de configuration disponibles du module ainsi que leurs valeurs par défaut, ouvrir le fichier ``/home/<mon_user>/geonature/external_modules/occtax/config/conf_gn_module.toml.example``.

Les surcouches de configuration doivent être faites dans le fichier ``conf_gn_module.toml``, en ne modifiant jamais le fichier ``conf_gn_module.toml.example``.

Après toute modification de la configuration d'un module, il faut regénérer le fichier de configuration du frontend comme expliqué ici : `Configuration d'un gn_module`_

Afficher/masquer des champs du formulaire
`````````````````````````````````````````

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
``````````````````````````````

Par défaut le champ ``Observateurs`` est une liste déroulante qui pointe vers une liste du schéma ``utilisateurs``.
Il est possible de passer ce champ en texte libre en mettant à ``true`` la variable ``observers_txt``.

Le paramètre ``id_observers_list`` permet de changer la liste d'observateurs proposée dans le formulaire. Vous pouvez modifier le numéro de liste du module ou modifier le contenu de la liste dans UsersHub (``utilisateurs.t_listes`` et ``utilisateurs.cor_role_liste``)

Par défaut, l'ensemble des observateurs de la liste 9 (observateurs faune/flore) sont affichés.

Personnaliser la liste des taxons saisissables dans le module
`````````````````````````````````````````````````````````````

Le module est fourni avec une liste restreinte de taxons (8 seulement). C'est à l'administrateur de changer ou de remplir cette liste.

Le paramètre ``id_taxon_list = 100`` correspond à un ID de liste de la table ``taxonomie.bib_listes`` (L'ID 100 correspond à la liste "Saisie Occtax"). Vous pouvez changer ce paramètre avec l'ID de liste que vous souhaitez, ou bien garder cet ID et changer le contenu de cette liste.

Voici les requêtes SQL pour remplir la liste 100 avec tous les taxons de Taxref à partir du rang ``genre`` :

Il faut d'abord remplir la table ``taxonomie.bib_noms`` (table des taxons de sa structure), puis remplir la liste 100, avec l'ensemble des taxons de ``bib_noms`` :

.. code-block:: sql

    DELETE FROM taxonomie.cor_nom_liste;
    DELETE FROM taxonomie.bib_noms;

    INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
    SELECT cd_nom, cd_ref, nom_vern
    FROM taxonomie.taxref
    WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
      'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR');

    INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
    SELECT 100,n.id_nom FROM taxonomie.bib_noms n;

Il est également possible d'éditer des listes à partir de l'application TaxHub.

Gérer les valeurs par défaut des nomenclatures
``````````````````````````````````````````````

Le formulaire de saisie pré-remplit des valeurs par défaut pour simplifier la saisie. Ce sont également ces valeurs qui sont prises en compte pour remplir dans la BDD les champs du formulaire qui sont masqués.

La table ``pr_occtax.defaults_nomenclatures_value`` définit les valeurs par défaut pour chaque nomenclature.

La table contient les deux colonnes suivantes :

- l'``id_type`` de nomenclature (voir table ``ref_nomenclature.bib_nomenclatures_types``)
- l'``id_nomenclature`` (voir table ``ref_nomenclature.t_nomenclatures``)

Pour chaque type de nomenclature, on associe l'ID de la nomenclature que l'on souhaite voir apparaitre par défaut.

Le mécanisme peut être poussé plus loin en associant une nomenclature par défaut par organisme, règne et group2_inpn.
La valeur 0 pour ses champs revient à mettre la valeur par défaut pour tous les organismes, tous les règnes et tous les group2_inpn.

Une interface de gestion des nomenclatures est prévue d'être développée pour simplifier cette configuration.

TODO : valeur par défaut de la validation

Personnaliser l'interface Map-list
``````````````````````````````````

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

Ajouter une contrainte d'échelle de saisie sur la carte
```````````````````````````````````````````````````````

Il est possible de contraindre la saisie de la géométrie d'un relevé sur la carte par un seuil d'échelle minimum avec le paramètre ``releve_map_zoom_level``.

Par défaut :

::

    # Zoom level on the map from which you can add point/line/polygon
    releve_map_zoom_level = 6


Il suffit de modifier la valeur qui correspond au niveau de zoom sur la carte.
Par exemple, pour contraindre la saisie à l'affichage de la carte IGN au 1/25000e :

::

    releve_map_zoom_level = 15


Gestion des exports
"""""""""""""""""""

Les exports du module sont basés sur une vue (par défaut ``pr_occtax.export_occtax_sinp``)

Il est possible de définir une autre vue pour avoir des exports personnalisés.
Pour cela, créer votre vue, et modifier les paramètres suivants :

::

    # Name of the view based export
    export_view_name = 'v_export_occtax'

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

L'administration des droits des utilisateurs pour le module Occtax se fait dans le backoffice de gestion des permissions de GeoNature.


Module Admin
-------------

Administration des champs additionnels
""""""""""""""""""""""""""""""""""""""

Certains protocoles nécessitent la saisie de champs qui vont au-delà des standards du SINP sur lesquels GeoNature s'appuie. Les champs additionnels permettent ainsi d'étendre les formulaires en ajoutant des informations spécifiques pour des jeux de données (JDD) ou pour l'ensemble d'un module.

Les champs additionnels ne sont pas créés comme des colonnes à part entière, mais leurs valeurs sont stockées dans un champs ``additional_data`` au format JSON.

Actuellement seul le module Occtax implémente la gestion de ces champs additionnels.

Le backoffice de GeoNature offre une interface de création et de gestion de ces champs additionnels. 
Un champ additionnel est définit par:

- son nom (nom dans la base de données)
- son label (nom tel qu'il sera affiché sur l'interface)
- son type de widget : vous devez définir si le champs est une liste déroulante, une checkbox, une nomenclature, un entier, un champ texte, etc...
- le (ou les) module(s) auquel il est rattaché 
- le (ou les) objet(s) auquel il est rattaché. Il s'agit du placement et de la table de rattachement du champs dans le module. Par exemple Occtax est composé de 3 "objets/table". Les objets "relevé", "occurrence" et "dénombrement".
- le (ou les) JDD auquel il est rattaché. Si aucun JDD n'est renseigné le champ sera proposé dans tout le module pour tous les JDD. S'il est rattaché à un JDD, le champs sera chargé dynamiquement à la selection du JDD dans le formulaire 
- une série d'autres options pour paramétrer le comportement du champs (obligatoire, ordre, description, exportable etc...)

Exemples de configuration :

- Un champs type "select" :

.. image :: _static/select_exemple.png

- Un champs type "multiselect" (la clé "value" est obligatoire dans le dictionnaire de valeurs) : 

.. image :: _static/multiselect3.png

- Un champs type "html". C'est un champs de type "présentation", aucune valeur ne sera enregistré en base de données pour ce champs :

.. image :: _static/html1.png

- Un champs de type "datalist". Ce champs permet de générer une liste de valeurs à partir d'une API. Dans le champ "attributs additionnels", renseignez les éléments suivants : 

::

    ``{"api": "url_vers_la_ressource", "keyValue": "champ à stocker en base", "keyLabel": "champ à afficher en interface"}

Configuration avancée des champs
````````````````````````````````

Le champs "Attribut additionnels" permet d'ajouter des éléments de configuration sur les formulaires sour forme de JSON:
- Ajouter une icone "?" et un tooltip au survol du formulaire : `{"description" : "mon toolitp"}`
- Ajouter un sous-titre descriptif : `{"help" : "mon sous titre"}`
- Ajouter des valeurs min/max pour un input `number` : `{"min": 1, "max": 10}`

Module OCCHAB
-------------

Installer le module
"""""""""""""""""""

Le module OCCHAB fait parti du coeur de GeoNature. Son installation est au choix de l'administrateur.

Pour l'installer, lancer les commande suivante:

.. code-block:: console

    cd backend
    source venv/bin/activate
    geonature install_gn_module /home/`whoami`/geonature/contrib/gn_module_occhab occtax


Base de données
"""""""""""""""

Le module s'appuie sur deux schémas.:
``ref_habitats``:  Le réferentiel habitat du MNHN
``pr_occhab``: le schéma qui contient les données d'occurrence d'habitat, basé sur standard du MNHN

Configuration
""""""""""""""

Le parametrage du module OCCHAB se fait depuis le fichier ``/home/`whoami`/geonature/contrib/config/conf_gn_module.toml``
Après toute modification de la configuration d'un module, il faut regénérer le fichier de configuration du frontend comme expliqué ici : `Configuration d'un gn_module`_


Formulaire
``````````

- La liste des habitats fournit pour la saisie est basé sur une liste définit en base de données (table ``ref_habitat.cor_list_habitat`` et ``ref_habitat.bib_list_habitat``). Il est possible d'éditer cette liste directement den base de données, d'en créer une autre et de changer la liste utiliser par le module. Editer alors ce paramètre:

``ID_LIST_HABITAT = 1``

- Le formulaire permet de saisir des observateur basés sur le referentiel utilisateurs ( ``false``) ou de les saisir en texte libre (``true``).

``OBSERVER_AS_TXT = false``

- L'ensemble des champs du formulaire son masquables. Pour en masquer certains, passer à ``false`` les variables suivantes:

::

    [formConfig]
      date_min = true
      date_max = true
      depth_min = true
      depth_max = true
      altitude_min = true
      altitude_max = true
      exposure = true
      area = true
      comment = true
      area_surface_calculation = true
      geographic_object = true
      determination_type = true
      determiner = true
      collection_technique = true
      technical_precision = true
      recovery_percentage = true
      abundance = true
      community_interest = true

Voir le fichier ``conf_gn_module.toml.example`` qui liste l'ensemble des paramètres de configuration du module.

Module SYNTHESE
---------------

Le module Synthèse est un module du coeur de GeoNature, fourni par défaut lors de l'installation.

Configuration
""""""""""""""

L'ensemble des paramètres de configuration du module se trouve dans le fichier général de configuration de GeoNature ``config/geonature_config.toml`` puisqu'il s'agit d'un module du coeur.

**1.** Modifier les filtres géographiques disponibles par défaut dans l'interface de recherche.

Editer la variable ``AREA_FILTERS`` en y ajoutant le label et le code du type d'entité géographique que vous souhaitez rajouter. Voir table ``ref_geo.bib_areas_types``. Dans l'exemple on ajoute le type ZNIEFF1 (``code_type = "ZNIEFF1"``). Attention, dans ce cas les entités géographiques correspondantes au type `ZNIEFF1`, doivent également être présentes dans la table ``ref_geo.l_areas``.
Attention : Si des données sont déjà présentes dans la synthèse et que l'on ajoute de nouvelles entités géographiques à ``ref_geo.l_areas``, il faut également recalculer les valeurs de la table ``gn_synthese.cor_area_synthese`` qui assure la correspondance entre les données de la synthèse et les entités géographiques.

::

    [SYNTHESE]
        # Liste des entités géographiques sur lesquels les filtres
        # géographiques de la synthese s'appuient (type_code = code du type de l'entité géo, table ref_geo.bib_areas_types)
        AREA_FILTERS = [
            { label = "Communes", "type_code": "COM" },
            { label = "ZNIEFF1", "type_code": "ZNIEFF1" },
        ]

Il est aussi possible de passer plusieurs ``type_code`` regroupés dans un même filtre géographique (exemple : ``{ label = "Zonages réglementaires", type_code = ["ZC", "ZPS", "SIC"] }``).

**2.** Configurer les champs des exports

Dans tous les exports, l'ordre et le nom des colonnes sont basés sur la vue servant l'export. Il est possible de les modifier en éditant le SQL des vues en respectant bien les consignes ci-dessous.

**Export des observations**

Les exports (CSV, GeoJson, Shapefile) sont basés sur la vue ``gn_synthese.v_synthese_for_export``.

Il est possible de ne pas intégrer certains champs présents dans cette vue d'export. Pour cela modifier le paramètre ``EXPORT_COLUMNS``.

Enlevez la ligne de la colonne que vous souhaitez désactiver. Les noms de colonne de plus de 10 caractères seront tronqués dans le fichier shapefile.

::

    [SYNTHESE]
        EXPORT_COLUMNS   = [
          "date_debut",
          "date_fin",
          "heure_debut",
          "heure_fin",
          "cd_nom",
          "cd_ref",
          "nom_valide",
          "nom_vernaculaire",
          "nom_cite",
          "regne",
          "group1_inpn",
          "group2_inpn",
          "classe",
          "ordre",
          "famille",
          "rang_taxo",
          "nombre_min",
          "nombre_max",
          "alti_min",
          "alti_max",
          "prof_min",
          "prof_max",
          "observateurs",
          "determinateur",
          "communes",
          "x_centroid_4326",
          "y_centroid_4326",
          "geometrie_wkt_4326",
          "nom_lieu",
          "comment_releve",
          "comment_occurrence",
          "validateur",
          "niveau_validation",
          "date_validation",
          "comment_validation",
          "preuve_numerique_url",
          "preuve_non_numerique",
          "jdd_nom",
          "jdd_uuid",
          "jdd_id",
          "ca_nom",
          "ca_uuid",
          "ca_id",
          "cd_habref",
          "cd_habitat",
          "nom_habitat",
          "precision_geographique",
          "nature_objet_geo",
          "type_regroupement",
          "methode_regroupement",
          "technique_observation",
          "biologique_statut",
          "etat_biologique",
          "biogeographique_statut",
          "naturalite",
          "preuve_existante",
          "niveau_precision_diffusion",
          "stade_vie",
          "sexe",
          "objet_denombrement",
          "type_denombrement",
          "niveau_sensibilite",
          "statut_observation",
          "floutage_dee",
          "statut_source",
          "type_info_geo",
          "methode_determination",
          "comportement",
          "reference_biblio",
          "id_synthese",
          "id_origine",
          "uuid_perm_sinp",
          "uuid_perm_grp_sinp",
          "date_creation",
          "date_modification"
        ]

:Note:

    L'entête ``[SYNTHESE]`` au dessus ``EXPORT_COLUMNS`` indique simplement que cette variable appartient au bloc de configuration de la synthese. Ne pas rajouter l'entête à chaque paramètre de la synthese mais une seule fois au dessus de toutes les variables de configuration du module.

Il est également possible de personnaliser ses exports en éditant le SQL de la vue ``gn_synthese.v_synthese_for_export`` (niveau SQL et administration GeoNature avancé).

Attention, certains champs sont cependant obligatoires pour assurer la réalisation des fichiers d'export (csv, geojson et shapefile) et des filtres CRUVED.

La vue doit OBLIGATOIREMENT contenir les champs :

- geojson_4326
- geojson_local
- id_synthese,
- jdd_id (l'ID du jeu de données)
- id_digitiser
- observateurs

Ces champs doivent impérativement être présents dans la vue, mais ne seront pas nécessairement dans le fichier d'export si ils ne figurent pas dans la variable ``EXPORT_COLUMNS``. De manière générale, préférez rajouter des champs plutôt que d'en enlever !

Le nom de ces champs peut cependant être modifié. Dans ce cas, modifiez le fichier ``geonature_config.toml``, section ``SYNTHESE`` parmis les variables suivantes (``EXPORT_ID_SYNTHESE_COL, EXPORT_ID_DATASET_COL, EXPORT_ID_DIGITISER_COL, EXPORT_OBSERVERS_COL, EXPORT_GEOJSON_4326_COL, EXPORT_GEOJSON_LOCAL_COL``).

NB : Lorsqu'on effectue une recherche dans la synthèse, on interroge la vue ``gn_synthese.v_synthese_for_web_app``. L'interface web passe ensuite une liste d'``id_synthese`` à la vue ``gn_synthese.v_synthese_for_export`` correspondant à la recherche précedemment effectuée (ce qui permet à cette seconde vue d'être totalement modifiable).

La vue ``gn_synthese.v_synthese_for_web_app`` est taillée pour l'interface web, il ne faut donc PAS la modifier.

**Export des métadonnées**

En plus des observations brutes, il est possible d'effectuer un export des métadonnées associées aux observations. L'export est au format CSV et est construit à partir de la table ``gn_synthese.v_metadata_for_export``. Vous pouvez modifier le SQL de création de cette vue pour customiser votre export (niveau SQL avancé).

Deux champs sont cependant obligatoire dans la vue :

- ``jdd_id`` (qui corespond à l'id du JDD de la table ``gn_meta.t_datasets``). Le nom de ce champs est modifiable. Si vous le modifiez, éditez la variable ``EXPORT_METADATA_ID_DATASET_COL``.
- ``acteurs``:  Le nom de ce champs est modifiable. Si vous le modifiez, éditez la variable ``EXPORT_METADATA_ACTOR_COL``

**Export des statuts taxonomiques (réglementations)**

Cet export n'est pas basé sur une vue, il n'est donc pas possible de l'adapter.

**3.** Configurer les seuils du nombre de données pour la recherche et les exports

Par défaut et pour des questions de performance (du navigateur et du serveur) on limite à 50000 le nombre de résultat affiché sur la carte et le nombre d'observations dans les exports.

Ces seuils sont modifiables respectivement par les variables ``NB_MAX_OBS_MAP`` et ``NB_MAX_OBS_EXPORT`` :

Le mode cluster activé par défaut peut être désactivé via le paramètre ``ENABLE_LEAFLET_CLUSTER``. Dans ce cas, il est conseillé de repasser le paramètre `NB_MAX_OBS_MAP` à 10000.

::

    [SYNTHESE]
        # Nombre d'observation maximum à afficher sur la carte après une recherche
        NB_MAX_OBS_MAP = 10000
        # Nombre max d'observation dans les exports
        NB_MAX_OBS_EXPORT = 40000

**4.** Désactiver des filtres génériques

L'interface de recherche de la synthèse permet de filtrer sur l'ensemble des nomenclatures de la table ``gn_synthese``, il est cependant possible de désactiver les filtres de certains champs.

Modifiez la variable ``EXCLUDED_COLUMNS``

::

    [SYNTHESE]
        EXCLUDED_COLUMNS = ['non_digital_proof'] # pour enlever le filtre 'preuve non numérique'


D'autres élements sont paramètrables dans le module synthese. La liste complète est disponible dans le fichier ``config/geonature_config.toml`` rubrique ``SYNTHESE``.

Module VALIDATION
-----------------

Le module VALIDATION, integré depuis la version 2.1.0 dans le coeur de GeoNature permet de valider des occurrences de taxon en s'appuyant sur les données présentes dans la SYNTHESE. Le module s'appuie sur le `standard Validation <http://www.naturefrance.fr/la-reunion/protocole-de-validation>`_ du SINP et sur ses `nomenclatures officiels <http://standards-sinp.mnhn.fr/nomenclature/80-niveaux-de-validation-validation-manuelle-ou-combinee-2018-05-14/>`_.

Afin de valider une occurrence, celle-ci doit impérativement avoir un UUID. En effet, la validation est stockée en BDD dans la table transversale ``gn_commons.t_validations``  (`voir doc <admin-manual.html#tables-transversales>`_ ) qui impose la présence de cet UUID.

La table ``gn_commons.t_validations`` contient l'ensemble de l'historique de validation des occurrences. Pour une même occurrence (identifiée par un UUID unique) on peut donc retrouver plusieurs lignes dans la table correspondant au différents statuts de validation attribués à cet occurrence dans le temps.

La vue ``gn_commons.v_latest_validation`` permet de récupérer le dernier statut de validation d'une occurrence.

NB : une donnée non présente dans la SYNTHESE, ne remontera pas dans l'interface du module VALIDATION. Cependant rien n'empêche un administrateur avancé d'utiliser la table de validation et son mécanisme pour des données qui ne seraient pas en SYNTHESE (du moment que les données disposent d'un UUID).

Au niveau de l'interface, le formulaire de recherche est commun avec le module SYNTHESE. Les paramètres de configuration du formulaire sont donc également partagés et administrables depuis le fichier ``geonature_config.toml``, rubrique SYNTHESE.


Configuration
""""""""""""""

Le parametrage du module VALIDATION se fait depuis le fichier ``/home/`whoami`/geonature/contrib/gn_module_validation/config/conf_gn_module.toml``
Après toute modification de la configuration d'un module, il faut regénérer le fichier de configuration du frontend comme expliqué ici : `Configuration d'un gn_module`_

Liste des champs visibles
`````````````````````````

Gestion de l'affichage des colonnes de la liste via le paramètre ``COLUMN_LIST`` :

::

    [[COLUMN_LIST]]
    column_label = "nomenclature_life_stage.label_default" # Champs de la synthèse, éventuellement en suivant des relationships
    column_name = "Stade de vie" # Titre de la colonne
    min_width = 100 # Taille minimale de la colonne
    max_width = 100 # Taille maximale de la colonne

E-mail
``````

Il est possible de personnaliser le message du mail envoyé aux observateurs.
Pour ce faire il faut modifier les  paramètres ``MAIL_BODY`` et ``MAIL_SUBJECT``

Pour afficher dans le mail des données relatives à l'observation ou au taxon il faut respecter la syntaxe suivante:
``${ d.NOM_PROPRIETE }``

Liste des propriétés disponibles :

- communes : liste des communes
- medias : Titre, auteur et lien vers le média associée
- data_link : lien vers l'observation dans son module de saisie
- tous les champs de la synthèse (acquisition_framework, altitude_max, altitude_min, bio_status, blurring, cd_hab, cd_nom, comment_context, comment_description, date_min, depth_max, depth_min, determiner, diffusion_level, digital_proof, entity_source_pk_value, exist_proof, grp_method, grp_typ, last_action, life_stage, meta_create_date, meta_update_date, meta_v_taxref, meta_validation_date, nat_obj_geo, naturalness, nom_cite, non_digital_proof, obj_count, obs_technique, observation_status, observers, occ_behaviour, occ_stat_biogeo, place_name, precision, sample_number_proof, sensitivity, sex, source, type_count, unique_id_sinp, unique_id_sinp_grp, valid_status, validation_comment)
- tous les champs du taxon (cd_nom, cd_ref, cd_sup, cd_taxsup, regne, ordre, classe, famille, group1_inpn, group2_inpn, id_rang, nom_complet, nom_habitat, nom_rang, nom_statut, nom_valide, nom_vern)
