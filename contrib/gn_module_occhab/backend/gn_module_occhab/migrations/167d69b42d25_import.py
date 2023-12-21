"""import

Revision ID: 167d69b42d25
Revises: 85efc9bb5a47
Create Date: 2023-11-07 16:09:58.406426

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData
from sqlalchemy.dialects.postgresql import HSTORE, JSONB, UUID
from geoalchemy2 import Geometry


# revision identifiers, used by Alembic.
revision = "167d69b42d25"
down_revision = "85efc9bb5a47"
branch_labels = None
depends_on = ("92f0083cf735",)


def upgrade():
    meta = MetaData(bind=op.get_bind())
    id_module_occhab = (
        op.get_bind()
        .execute("SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCHAB'")
        .scalar()
    )
    destination = Table("bib_destinations", meta, autoload=True, schema="gn_imports")
    id_dest_occhab = (
        op.get_bind()
        .execute(
            sa.insert(destination)
            .values(
                id_module=id_module_occhab,
                code="occhab",
                label="Occhab",
                table_name="t_imports_occhab",
            )
            .returning(destination.c.id_destination)
        )
        .scalar()
    )
    entity = Table("bib_entities", meta, autoload=True, schema="gn_imports")
    id_entity_station = (
        op.get_bind()
        .execute(
            sa.insert(entity)
            .values(
                id_destination=id_dest_occhab,
                code="station",
                label="Station",
                order=1,
                validity_column="station_valid",
                destination_table_schema="pr_occhab",
                destination_table_name="t_stations",
            )
            .returning(entity.c.id_entity)
        )
        .scalar()
    )
    id_entity_habitat = (
        op.get_bind()
        .execute(
            sa.insert(entity)
            .values(
                id_destination=id_dest_occhab,
                code="habitat",
                label="Habitat",
                order=2,
                validity_column="habitat_valid",
                destination_table_schema="pr_occhab",
                destination_table_name="t_habitats",
            )
            .returning(entity.c.id_entity)
        )
        .scalar()
    )
    op.create_table(
        "t_imports_occhab",
        sa.Column(
            "id_import",
            sa.Integer,
            sa.ForeignKey("gn_imports.t_imports.id_import"),
            primary_key=True,
        ),
        sa.Column("line_no", sa.Integer, primary_key=True),
        sa.Column("station_valid", sa.Boolean, nullable=True, server_default=sa.false()),
        sa.Column("habitat_valid", sa.Boolean, nullable=True, server_default=sa.false()),
        # Station fields
        sa.Column("src_id_station", sa.String),
        sa.Column("id_station", sa.Integer),
        sa.Column("src_unique_id_sinp_station", sa.String),
        sa.Column("unique_id_sinp_station", UUID(as_uuid=True)),
        sa.Column("src_unique_dataset_id", sa.String),
        sa.Column("unique_dataset_id", UUID(as_uuid=True)),
        sa.Column("id_dataset", sa.Integer),
        sa.Column("src_date_min", sa.String),
        sa.Column("date_min", sa.DateTime),
        sa.Column("src_date_max", sa.String),
        sa.Column("date_max", sa.DateTime),
        sa.Column("observers_txt", sa.String),
        sa.Column("station_name", sa.String),
        sa.Column("src_is_habitat_complex", sa.String),
        sa.Column("is_habitat_complex", sa.Boolean),
        sa.Column("src_id_nomenclature_exposure", sa.String),
        sa.Column(
            "id_nomenclature_exposure",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("src_altitude_min", sa.String),
        sa.Column("altitude_min", sa.Integer),
        sa.Column("src_altitude_max", sa.String),
        sa.Column("altitude_max", sa.Integer),
        sa.Column("src_depth_min", sa.String),
        sa.Column("depth_min", sa.Integer),
        sa.Column("src_depth_max", sa.String),
        sa.Column("depth_max", sa.Integer),
        sa.Column("src_area", sa.String),
        sa.Column("area", sa.Integer),
        sa.Column("src_id_nomenclature_area_surface_calculation", sa.String),
        sa.Column(
            "id_nomenclature_area_surface_calculation",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("comment", sa.String),
        sa.Column("src_WKT", sa.Unicode),
        sa.Column("src_latitude", sa.Unicode),
        sa.Column("src_longitude", sa.Unicode),
        sa.Column("geom_local", Geometry("GEOMETRY")),
        sa.Column("geom_4326", Geometry("GEOMETRY", 4326)),
        sa.Column("src_precision", sa.String),
        sa.Column("precision", sa.Integer),
        sa.Column("src_id_digitiser", sa.String),
        sa.Column("id_digitiser", sa.Integer),
        sa.Column("src_numerization_scale", sa.String),
        sa.Column("numerization_scale", sa.String(15)),
        sa.Column("src_id_nomenclature_geographic_object", sa.String),
        sa.Column(
            "id_nomenclature_geographic_object",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        # Habitat fields
        sa.Column("src_id_habitat", sa.String),
        sa.Column("id_habitat", sa.Integer),
        # already declared: id_station
        sa.Column("src_unique_id_sinp_hab", sa.String),
        sa.Column("unique_id_sinp_hab", UUID(as_uuid=True)),
        sa.Column("src_cd_hab", sa.String),
        sa.Column("cd_hab", sa.Integer),
        sa.Column("nom_cite", sa.String),
        sa.Column("src_id_nomenclature_determination_type", sa.String),
        sa.Column(
            "id_nomenclature_determination_type",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("determiner", sa.String),
        sa.Column("src_id_nomenclature_collection_technique", sa.String),
        sa.Column(
            "id_nomenclature_collection_technique",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("src_recovery_percentage", sa.String),
        sa.Column("recovery_percentage", sa.Integer),
        sa.Column("src_id_nomenclature_abundance", sa.String),
        sa.Column(
            "id_nomenclature_abundance",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("technical_precision", sa.String),
        sa.Column("src_unique_id_sinp_grp_occtax", sa.String),
        sa.Column("unique_id_sinp_grp_occtax", UUID(as_uuid=True)),
        sa.Column("src_unique_id_sinp_grp_phyto", sa.String),
        sa.Column("unique_id_sinp_grp_phyto", UUID(as_uuid=True)),
        sa.Column("src_id_nomenclature_sensitivity", sa.String),
        sa.Column(
            "id_nomenclature_sensitivity",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        sa.Column("src_id_nomenclature_community_interest", sa.String),
        sa.Column(
            "id_nomenclature_community_interest",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        ),
        schema="gn_imports",
    )
    theme = Table("bib_themes", meta, autoload=True, schema="gn_imports")
    id_theme_general = (
        op.get_bind()
        .execute(sa.select([theme.c.id_theme]).where(theme.c.name_theme == "general_info"))
        .scalar()
    )
    fields_entities = [
        ### Stations & habitats
        (
            {
                "name_field": "id_station",
                "fr_label": "Identifiant station",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_id_station",
                "dest_field": "id_station",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 1,
                    "comment": "Correspondance champs standard: identifiantOrigineStation",
                },
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 1,
                    "comment": "Correspondance champs standard: identifiantOrigineStation",
                },
            },
        ),
        ### Stations
        (
            {
                "name_field": "unique_id_sinp_station",
                "fr_label": "Identifiant station (UUID)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_unique_id_sinp_station",
                "dest_field": "unique_id_sinp_station",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 2,
                    "comment": "Correspondance champs standard: identifiantStaSINP ou permId",
                },
            },
        ),
        # TODO: générer les identifiants SINP manquant
        (
            {
                "name_field": "unique_dataset_id",
                "fr_label": "Identifiant JDD (UUID)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_unique_dataset_id",
                "dest_field": "unique_dataset_id",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 3,
                    "comment": "Correspondance champs standard: metadonneeId ou jddMetaId",
                },
            },
        ),
        (
            {
                "name_field": "id_dataset",
                "fr_label": "Identifiant JDD",
                "mandatory": False,
                "autogenerated": False,
                "display": False,
                "mnemonique": None,
                "source_field": None,
                "dest_field": "id_dataset",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 3,
                    "comment": "",
                },
            },
        ),
        (
            {
                "name_field": "date_min",
                "fr_label": "Date début",
                "mandatory": True,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_date_min",
                "dest_field": "date_min",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 4,
                    "comment": "Correspondance champs standard: dateDebut",
                },
            },
        ),
        (
            {
                "name_field": "date_max",
                "fr_label": "Date fin",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_date_max",
                "dest_field": "date_max",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 5,
                    "comment": "Correspondance champs standard: dateFin",
                },
            },
        ),
        (
            {
                "name_field": "observers_txt",
                "fr_label": "Observateurs",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "observers_txt",
                "dest_field": "observers_txt",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 6,
                    "comment": "Correspondance champs standard: observateur",
                },
            },
        ),
        (
            {
                "name_field": "station_name",
                "fr_label": "Nom de la station",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "station_name",
                "dest_field": "station_name",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 7,
                    "comment": "Correspondance champs standard: nomStation",
                },
            },
        ),
        (
            {
                "name_field": "is_habitat_complex",
                "fr_label": "Complexe d’habitats",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_is_habitat_complex",
                "dest_field": "is_habitat_complex",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 8,
                    "comment": "Correspondance champs standard: estComplexeHabitats",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_exposure",
                "fr_label": "Exposition de la station",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "EXPOSITION",
                "source_field": "src_id_nomenclature_exposure",
                "dest_field": "id_nomenclature_exposure",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 9,
                    "comment": "Correspondance champs standard: exposition",
                },
            },
        ),
        (
            {
                "name_field": "altitude_min",
                "fr_label": "Altitude minimum",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_altitude_min",
                "dest_field": "altitude_min",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 10,
                    "comment": "Correspondance champs standard: altitudeMin",
                },
            },
        ),
        (
            {
                "name_field": "altitude_max",
                "fr_label": "Altitude maximum",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_altitude_max",
                "dest_field": "altitude_min",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 11,
                    "comment": "Correspondance champs standard: altitudeMax",
                },
            },
        ),
        (
            {
                "name_field": "depth_min",
                "fr_label": "Profondeur minimum",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_depth_min",
                "dest_field": "depth_min",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 12,
                    "comment": "Correspondance champs standard: profondeurMin",
                },
            },
        ),
        (
            {
                "name_field": "depth_max",
                "fr_label": "Profondeur maximale",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_depth_max",
                "dest_field": "depth_min",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 13,
                    "comment": "Correspondance champs standard: profondeurMax",
                },
            },
        ),
        (
            {
                "name_field": "area",
                "fr_label": "Surface de la station",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_area",
                "dest_field": "area",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 14,
                    "comment": "Correspondance champs standard: surface",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_area_surface_calculation",
                "fr_label": "Méthode de détermination de la surface",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "METHOD_CALCUL_SURFACE",
                "source_field": "src_id_nomenclature_area_surface_calculation",
                "dest_field": "id_nomenclature_area_surface_calculation",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 15,
                    "comment": "Correspondance champs standard: methodeCalculSurface",
                },
            },
        ),
        (
            {
                "name_field": "comment",
                "fr_label": "Commentaire",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "comment",
                "dest_field": "comment",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 16,
                    "comment": "Correspondance champs standard: commentaire",
                },
            },
        ),
        (
            {
                "name_field": "WKT",
                "fr_label": "Géometrie (WKT)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_WKT",
                "dest_field": None,
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 17,
                    "comment": "Correspondance champs standard: ",
                },
            },
        ),
        (
            {
                "name_field": "longitude",
                "fr_label": "Longitude (coord x)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_longitude",
                "dest_field": None,
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 18,
                    "comment": "Correspondance champs standard: ",
                },
            },
        ),
        (
            {
                "name_field": "latitude",
                "fr_label": "Latitude (coord y)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_latitude",
                "dest_field": None,
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 19,
                    "comment": "Correspondance champs standard: ",
                },
            },
        ),
        (
            {
                "name_field": "geom_local",
                "fr_label": "Géométrie (SRID local)",
                "mandatory": False,
                "autogenerated": False,
                "display": False,
                "mnemonique": None,
                "source_field": None,
                "dest_field": "geom_local",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 20,
                    "comment": "",
                },
            },
        ),
        (
            {
                "name_field": "geom_4326",
                "fr_label": "Géométrie (SRID 4326)",
                "mandatory": False,
                "autogenerated": False,
                "display": False,
                "mnemonique": None,
                "source_field": None,
                "dest_field": "geom_4326",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 21,
                    "comment": "",
                },
            },
        ),
        (
            {
                "name_field": "precision",
                "fr_label": "Précision géométrique (mètres)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_precision",
                "dest_field": "precision",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 22,
                    "comment": "Correspondance champs standard: precisionGeometrie",
                },
            },
        ),
        (
            {
                "name_field": "id_digitiser",
                "fr_label": "Identifiant de l’auteur de la saisie (id_role dans l’instance cible)",
                "mandatory": False,
                "autogenerated": False,
                "display": False,  # To be implemented
                "mnemonique": None,
                "source_field": "src_id_digitiser",
                "dest_field": "id_digitiser",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 23,
                    "comment": "Fournir un id_role GeoNature",
                },
            },
        ),
        (
            {
                "name_field": "numerization_scale",
                "fr_label": "Échelle de carte utilisée pour la numérisation",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_numerization_scale",
                "dest_field": "numerization_scale",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 24,
                    "comment": "Correspondance champs standard: echelleNumerisation",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_geographic_object",
                "fr_label": "Nature de la localisation",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "NAT_OBJ_GEO",
                "source_field": "src_id_nomenclature_geographic_object",
                "dest_field": "id_nomenclature_geographic_object",
            },
            {
                id_entity_station: {
                    "id_theme": id_theme_general,
                    "order_field": 25,
                    "comment": "Correspondance champs standard: natureObjetGeo",
                },
            },
        ),
        ### Habitats
        (
            {
                "name_field": "id_habitat",
                "fr_label": "Identifiant habitat",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_id_habitat",
                "dest_field": "id_habitat",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 2,
                    "comment": "Correspondance champs standard: identifiantOrigine",
                },
            },
        ),
        (
            {
                "name_field": "unique_id_sinp_habitat",
                "fr_label": "Identifiant habitat (UUID)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_unique_id_sinp_hab",
                "dest_field": "unique_id_sinp_hab",  # abbreviated in pr_occhab.t_habitats table
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 3,
                    "comment": "Correspondance champs standard: identifiantHabSINP",
                },
            },
        ),
        # TODO: générer les identifiants SINP manquant
        (
            {
                "name_field": "cd_hab",
                "fr_label": "Code habitat",
                "mandatory": True,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_cd_hab",
                "dest_field": "cd_hab",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 4,
                    "comment": "Correspondance champs standard: cdHab",
                },
            },
        ),
        (
            {
                "name_field": "nom_cite",
                "fr_label": "Nom cité",
                "mandatory": True,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "nom_cite",
                "dest_field": "nom_cite",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 5,
                    "comment": "Correspondance champs standard: nomCite",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_determination_type",
                "fr_label": "Type de détermination",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "DETERMINATION_TYP_HAB",
                "source_field": "src_id_nomenclature_determination_type",
                "dest_field": "id_nomenclature_determination_type",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 6,
                    "comment": "Correspondance champs standard: typeDeterm",
                },
            },
        ),
        (
            {
                "name_field": "determiner",
                "fr_label": "Déterminateur du code",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "determiner",
                "dest_field": "determiner",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 7,
                    "comment": "Correspondance champs standard: determinateur",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_collection_technique",
                "fr_label": "Technique de collecte",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "TECHNIQUE_COLLECT_HAB",
                "source_field": "src_id_nomenclature_collection_technique",
                "dest_field": "id_nomenclature_collection_technique",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 8,
                    "comment": "Correspondance champs standard: techniqueCollecte",
                },
            },
        ),
        (
            {
                "name_field": "recovery_percentage",
                "fr_label": "Pourcentage de recouvrement",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_recovery_percentage",
                "dest_field": "recovery_percentage",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 9,
                    "comment": "Correspondance champs standard: recouvrement",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_abundance",
                "fr_label": "Abondance relative de l'habitat",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "ABONDANCE_HAB",
                "source_field": "src_id_nomenclature_abundance",
                "dest_field": "id_nomenclature_abundance",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 10,
                    "comment": "Correspondance champs standard: abondanceHabitat",
                },
            },
        ),
        (
            {
                "name_field": "technical_precision",
                "fr_label": "Précisions sur la technique de collecte",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "technical_precision",
                "dest_field": "technical_precision",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 11,
                    "comment": "Correspondance champs standard: precisionTechnique",
                },
            },
        ),
        (
            {
                "name_field": "unique_id_sinp_grp_occtax",
                "fr_label": "",
                "mandatory": False,
                "autogenerated": False,
                "display": False,  # XXX I dont know the purpose of this field
                "mnemonique": None,
                "source_field": "src_unique_id_sinp_grp_occtax",
                "dest_field": "unique_id_sinp_grp_occtax",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 12,
                    "comment": "",
                },
            },
        ),
        (
            {
                "name_field": "unique_id_sinp_grp_phyto",
                "fr_label": "Identifiant d'un relevé phytosociologique (UUID)",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": None,
                "source_field": "src_unique_id_sinp_grp_phyto",
                "dest_field": "unique_id_sinp_grp_phyto",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 13,
                    "comment": "Correspondance champs standard: relevePhyto",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_sensitivity",
                "fr_label": "Sensibilité de l'habitat",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "SENSIBILITE",
                "source_field": "src_id_nomenclature_sensitivity",
                "dest_field": "id_nomenclature_sensitivity",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 14,
                    "comment": "Correspondance champs standard: sensibiliteHab",
                },
            },
        ),
        (
            {
                "name_field": "id_nomenclature_community_interest",
                "fr_label": "Intérêt communautaire",
                "mandatory": False,
                "autogenerated": False,
                "display": True,
                "mnemonique": "HAB_INTERET_COM",
                "source_field": "src_id_nomenclature_community_interest",
                "dest_field": "id_nomenclature_community_interest",
            },
            {
                id_entity_habitat: {
                    "id_theme": id_theme_general,
                    "order_field": 15,
                    "comment": "Correspondance champs standard: habitatInteretCommunautaire",
                },
            },
        ),
    ]
    field = Table("bib_fields", meta, autoload=True, schema="gn_imports")
    id_fields = [
        id_field
        for id_field, in op.get_bind()
        .execute(
            sa.insert(field)
            .values([{"id_destination": id_dest_occhab, **field} for field, _ in fields_entities])
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
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET 
            type = 'occhab'
        WHERE
            module_code = 'OCCHAB'
        """
    )


def downgrade():
    op.drop_table(schema="gn_imports", table_name="t_imports_occhab")
    op.execute("DELETE FROM gn_imports.bib_destinations WHERE code = 'occhab'")
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET 
            type = 'base'
        WHERE
            module_code = 'OCCHAB'
        """
    )
