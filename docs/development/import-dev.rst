Intégrer l’import de données dans votre module
----------------------------------------------

A partir de la version 2.15, le module d’Import permet l’ajout de nouvelles destinations en plus de la Synthèse. Cela a été l’occasion d’ajouter la possibilité d’importer des données d’habitat dans le module Occhab.
Cette section présente le processus d’ajout de l’import dans votre module GeoNature.

Modification à apporter sur la base de données
**********************************************

Plusieurs points sont essentiels au bon fonctionnement de l’import dans votre module :

1. Avoir une permission C sur votre module de destination
2. Créer un objet destination (`bib_destinations`) et autant d’entités (`bib_entities`) que vous avez d’objets dans votre module (e.g. habitat, station pour Occhab)
3. Créer une table transitoire permettant d’effectuer la complétion et le contrôle des données avant l’import des données vers la table de destination finale.
4. Pour chaque entité, déclarer les attributs rendus accessibles à l’import dans `bib_fields`
5. Si de nouvelles erreurs de contrôle de données doivent être déclarées, ajouter ces dernières dans `bib_errors_type`

N.B. Comme dans le reste de GeoNature, il est conseillé d’effectuer les modifications de base de données à l’aide de migrations Alembic.

Permissions requises
""""""""""""""""""""

Si ce n'est pas le déjà cas, ajouter la permission de création de données dans votre module. Le code ci-dessous donne un exemple fonctionnant dans une révision alembic.

.. code-block:: python

    op.execute(
        """
        INSERT INTO
            gn_permissions.t_permissions_available (id_module,id_object,id_action,label,scope_filter)
        SELECT
            m.id_module,o.id_object,a.id_action,v.label,v.scope_filter
        FROM
            (
                VALUES
                    ('[votreModuleCode', 'ALL', 'C', True, 'Créer [nomEntité]')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """
        )


Créer votre destination et vos entités
""""""""""""""""""""""""""""""""""""""

Dans un premier temps, il faut créer une "destination". Pour cela, il faut enregistrer votre module dans `bib_destinations`.

.. code-block:: python

    # Récupérer l'identifiant de votre module
    id_de_votre_module = (
        op.get_bind()
        .execute("SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'CODE_DE_VOTRE_MODULE'")
        .scalar()
    )

    # Ajouter la destination
    # N.B. table_name correspond au nom de la future table transitoire
    destination = Table("bib_destinations", meta, autoload=True, schema="gn_imports")
    op.get_bind()
    .execute(
        sa.insert(destination)
        .values(
            id_module=id_de_votre_module,
            code="votre_module_code",
            label="VotreModule",
            table_name="t_imports_votre_module",
        )
    )


Dans votre module, plusieurs objets sont manipulés et stockés chacun dans une table. Pour prendre l'exemple du module Occhab, on a deux entités les stations et les habitats.

.. code-block:: python

    id_dest_module= (
    op.get_bind()
    .execute("SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'votre_module_code'")
    .scalar()
    )
    entity = Table("bib_entities", meta, autoload=True, schema="gn_imports")
    op.get_bind()
    .execute(
        sa.insert(entity)
        .values(
            id_destination=id_dest_module,
            code="code_entite1",
            label="Entite1",
            order=1,
            validity_column="entite1_valid",
            destination_table_schema="votre_module_schema",
            destination_table_name="entite1_table_name",
        )
    )



Créer votre table transitoire
"""""""""""""""""""""""""""""

Nécessaire pour le contrôle de données, il est important de créer une table transitoire permettant d’effectuer la complétion et le contrôle des données avant l’import des données vers la table de destination finale. La table transitoire doit contenir les colonnes suivantes :

- id_import : identifiant de l’import
- line_no : entier, numéro de la ligne dans le fichier source
- entityname_valid : booleen, indique si une entité est valide
- pour chaque champ de l'entité, il faudra une colonne VARCHAR contenant la donnée du fichier et une colonne du type du champ qui contiendra la données finales. La convention de nommage est la suivante: "src_nomchamp" pour colonne contenant la données du fichier source et "nomchamp" pour la colonne contenant les données finales. Il est conseillé que le nom de la colonne contenant les données finales soit identiques à celle du champs dans la table de destination.

.. code-block:: python

    op.create_table(
        "t_imports_votremodule",
        sa.Column(
            "id_import",
            sa.Integer,
            sa.ForeignKey("gn_imports.t_imports.id_import", onupdate="CASCADE", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("line_no", sa.Integer, primary_key=True),
        sa.Column("entite1_valid", sa.Boolean, nullable=True, server_default=sa.false()),
        # Station fields
        sa.Column("src_id_entite", sa.Integer),
        sa.Column("id_entite", sa.String),
        sa.Column("src_unique_dataset_id", sa.String),
        sa.Column("unique_dataset_id", UUID(as_uuid=True)),
        [...]
    )


Déclarer les attributs rendus accessibles à l’import dans **bib_fields**
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Pour chaque entité (e.g. une station dans Occhab), il faut déclarer les champs du modèles accessibles à l’import dans `bib_fields`. 

.. code-block:: python

    theme = Table("bib_themes", meta, autoload=True, schema="gn_imports")

    id_theme_general = (
        op.get_bind()
        .execute(sa.select([theme.c.id_theme]).where(theme.c.name_theme == "general_info"))
        .scalar()
    )


    fields_entities=[
        (
            {
                "name_field": "id_entite1",
                "fr_label": "Identifiant entité1",
                "mandatory": True, # Obligatoire ou non 
                "autogenerated": False, # généré automatique (ex. UUID) 
                "display": False, # Afficher dans l'UI
                "mnemonique": None,
                "source_field": None,
                "dest_field": "id_entite1",
            },
            {
                id_entity1: { # récupérer l'id de l'entité entité1 précédement inséré
                    "id_theme": id_theme_general,
                    "order_field": 0,
                    "comment": "", # Utilisé comme tooltip
                },
            },
        ),
        ...
    ]

    field = Table("bib_fields", meta, autoload=True, schema="gn_imports")
    id_fields = [
        id_field
        for id_field, in op.get_bind()
        .execute(
            sa.insert(field)
            .values([{"id_destination": id_votre_dest, **field} for field, _ in fields_entities])
            .returning(field.c.id_field)
        )
        .fetchall()
    ]
    cor_entity_field = Table("cor_entity_field", meta, autoload=True, schema="gn_imports")
    op.execute(
        sa.insert(cor_entity_field).values(
            [
                {"id_entity": id_entity, "id_field": id_field, **props}
                for id_field, field_entities in zip(id_fields, fields_entities)
                for id_entity, props in field_entities[1].items()
            ]
        )
    )


Ajout de nouvelles erreurs de contrôle de données
"""""""""""""""""""""""""""""""""""""""""""""""""

Il est possible que votre module nécessite de déclarer de nouveaux contrôles de données. Ces contrôles
peuvent provoquer de nouvelles erreurs que celle déclaré dans `bib_errors_type`. Il est possible d'en ajouter
comme dans l'exemple suivant :

.. code-block:: python

    error_type = sa.Table("bib_errors_types", metadata, schema="gn_imports", autoload_with=op.get_bind())
    op.bulk_insert(
        error_type,
        [
            {
                "error_type": "Erreur de format booléen",
                "name": "INVALID_BOOL",
                "description": "Le champ doit être renseigné avec une valeur binaire (0 ou 1, true ou false).",
                "error_level": "ERROR",
            },
            {
                "error_type": "Données incohérentes d'une ou plusieurs entités",
                "name": "INCOHERENT_DATA",
                "description": "Les données indiquées pour une ou plusieurs entités sont incohérentes sur différentes lignes.",
                "error_level": "ERROR",
            },
            ...
        ],
    )

Configuration
*************

Il faut d'abord créer une classe héritant de la classe `ImportActions`

.. code-block:: python

    class VotreModuleImportActions(ImportActions):
        def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        # Retourne un objet contenant les labels pour les statistiques

        def preprocess_transient_data(imprt: TImports, df) -> set:
        # Effectue un pré-traitement des données dans un dataframe

        def check_transient_data(task, logger, imprt: TImports) -> None:
        # Effectue la validation des données

        def import_data_to_destination(imprt: TImports) -> None:
        # Importe les données dans la table de destination

        def remove_data_from_destination(imprt: TImports) -> None:
        # Supprime les données de la table de destination

        def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        # Retourne des graphiques sur l'import

        def compute_bounding_box(imprt: TImports) -> None:
        # Calcule la bounding box

Dans cette classe on retrouve toutes les fonctions obligatoires, à implementer pour pouvoir implementer l'import dans un module.

Méthodes à implémenter
"""""""""""""""""""""

``statistics_labels()``

Fonction qui renvoie un objet de la forme suivante :

.. code-block:: python

    {"key": "station_count", "value": "Nombre de stations importées"},
    {"key": "habitat_count", "value": "Nombre d’habitats importés"},


Les statistiques sont calculées en amont, et ajoutés à l'objet import dans la section statistique.
Les valeurs des clés permettent de définir les labels à afficher pour les statistique affichées dans la liste d'imports.

``preprocess_transient_data(imprt: TImports, df)``

Fonction qui permet de faire un pré-traitement sur les données de l'import, elle retourne un dataframe panda.

``check_transient_data(task, logger, imprt: TImports)``

Dans cette fonction est effectuée la validation et le traitement des données de l'import.

La fonction ``check_dates``, par exemple, utilisée dans l'import Occhab permet de valider tous les champs de type date présents dans l'import.
Elle vérifie que le format est respecté.

La fonction ``check_transient_data`` permet de génerer les uuid manquants dans l'import, elle permet notamment de générer un UUID commun à différentes lignes de l'import quand id_origin est le même.

``import_data_to_destination(imprt: TImports)``

Cette fonction permet d'implémenter l'import des données valides dans la table de destination une fois que toutes les vérifications ont été effectuées.

``remove_data_from_destination(imprt: TImports)``

Cette fonction permet de supprimer les données d'un import, lors de la suppression d'un import.
C'est notamment pour pouvoir implémenter cette fonction que la colonne ``id_import`` est préconisée dans les tables de destination.

``report_plot(imprt: TImports)``

Cette fonction permet de créer les graphiques affichés dans le raport d'import.
Pour créer ces graphiques on utilise la librairie bokeh (documentation : https://docs.bokeh.org/en/latest/). Il y a des exemples de création de graphiques dans l'import Occhab.

``compute_bounding_box(imprt: TImports)``

Cette fonction sert à calculer la bounding box des données importées, c'est-à-dire le plus petit polygone dans lequel sont contenues toutes les données géographique importées.
Cette bounding box est affichée dans le rapport d'import une fois toutes les données validées.
