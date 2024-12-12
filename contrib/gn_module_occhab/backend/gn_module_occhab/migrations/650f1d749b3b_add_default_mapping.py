"""add_default_mapping

Revision ID: 650f1d749b3b
Revises: c1a6b0793360
Create Date: 2024-12-12 13:21:49.612529

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import Session
from sqlalchemy.sql import table, column
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.ext.mutable import MutableDict


# revision identifiers, used by Alembic.
revision = "650f1d749b3b"
down_revision = "c1a6b0793360"
branch_labels = None
depends_on = "e43b01a18850"


def get_models(conn):
    metadata = sa.MetaData(bind=conn)
    MappingTemplate = sa.Table("t_mappings", metadata, schema="gn_imports", autoload_with=conn)
    FieldMapping = sa.Table("t_fieldmappings", metadata, schema="gn_imports", autoload_with=conn)
    return MappingTemplate, FieldMapping


def upgrade():
    conn = op.get_bind()
    MappingTemplate, FieldMapping = get_models(conn)

    session = Session(bind=op.get_bind())
    id_destination_occhab = session.scalar(
        sa.text("SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'occhab'")
    )

    id_occhab_mapping = session.execute(
        sa.select(MappingTemplate.c.id).where(MappingTemplate.c.label == "Occhab")
    ).scalar()

    if not id_occhab_mapping:
        id_occhab_mapping = session.execute(
            sa.insert(MappingTemplate)
            .values(
                label="Occhab",
                type="FIELD",
                active=True,
                public=True,
                id_destination=id_destination_occhab,
            )
            .returning(MappingTemplate.c.id)
        ).first()[0]

    existing_occhab_fieldmapping = session.execute(
        sa.select(FieldMapping.c.id).where(FieldMapping.c.id == id_occhab_mapping)
    ).first()

    if not existing_occhab_fieldmapping:
        session.execute(
            sa.insert(FieldMapping).values(
                id=id_occhab_mapping,
                values={
                    "WKT": {"column_src": "geometry"},
                    "altitude_max": {"column_src": "altitude_max"},
                    "altitude_min": {"column_src": "altitude_min"},
                    "area": {"column_src": "area"},
                    "cd_hab": {"column_src": "cd_hab"},
                    "comment": {"column_src": "comment"},
                    "date_max": {"column_src": "date_fin"},
                    "date_min": {"column_src": "date_debut"},
                    "depth_max": {"column_src": "depth_max"},
                    "depth_min": {"column_src": "depth_min"},
                    "id_nomenclature_area_surface_calculation": {
                        "column_src": "methode_calcul_surface"
                    },
                    "id_nomenclature_exposure": {"column_src": "exposition"},
                    "id_nomenclature_geographic_object": {"column_src": "nature_objet_geo"},
                    "id_station_source": {"column_src": "id_station"},
                    "nom_cite": {"column_src": "nom_cite"},
                    "observers_txt": {"column_src": "observateurs"},
                    "technical_precision": {"column_src": "precision_technique"},
                    "unique_dataset_id": {"column_src": "uuid_jdd"},
                    "unique_id_sinp_habitat": {"column_src": "uuid_habitat"},
                    "unique_id_sinp_station": {"column_src": "uuid_station"},
                },
            )
        )

    id_mapping_sinp = session.execute(
        sa.select(MappingTemplate.c.id).where(
            MappingTemplate.c.label == "Occurrences d'habitats SINP"
        )
    ).scalar()

    if not id_mapping_sinp:
        id_mapping_sinp = session.execute(
            sa.insert(MappingTemplate)
            .values(
                label="Occurrences d'habitats SINP",
                type="FIELD",
                active=True,
                public=True,
                id_destination=id_destination_occhab,
            )
            .returning(MappingTemplate.c.id)
        ).first()[0]

    existing_sinp_fieldmapping = session.execute(
        sa.select(FieldMapping.c.id).where(FieldMapping.c.id == id_mapping_sinp)
    ).first()

    if not existing_sinp_fieldmapping:
        session.execute(
            sa.insert(FieldMapping).values(
                id=id_mapping_sinp,
                values={
                    "WKT": {"column_src": "WKT"},
                    "altitude_max": {"column_src": "altMax"},
                    "altitude_min": {"column_src": "altMin"},
                    "area": {"column_src": "surf"},
                    "cd_hab": {"column_src": "cdHab"},
                    "comment": {"column_src": "comment"},
                    "date_max": {"column_src": "dateFin"},
                    "date_min": {"column_src": "dateDebut"},
                    "depth_max": {"column_src": "profMax"},
                    "depth_min": {"column_src": "profMin"},
                    "determiner": {"column_src": "persDeterm"},
                    "id_habitat": {"column_src": "idOrigine"},
                    "id_nomenclature_abundance": {"column_src": "abondHab"},
                    "id_nomenclature_area_surface_calculation": {
                        "column_src": "methodeCalculSurface"
                    },
                    "id_nomenclature_collection_technique": {"column_src": "techCollec"},
                    "id_nomenclature_community_interest": {
                        "column_src": "habitatInteretCommunautaire "
                    },
                    "id_nomenclature_determination_type": {"column_src": "typeDeterm"},
                    "id_nomenclature_exposure": {"column_src": "exposition"},
                    "id_nomenclature_geographic_object": {"column_src": "natObjGeo"},
                    "id_nomenclature_sensitivity": {"column_src": "sensibiliteHab"},
                    "id_station_source": {"column_src": "idOrigEvt"},
                    "is_habitat_complex": {"column_src": "mosaique"},
                    "nom_cite": {"column_src": "nomCite"},
                    "numerization_scale": {"column_src": "echelleNumerisation"},
                    "observers_txt": {"column_src": "observer"},
                    "precision": {"column_src": "precisGeo"},
                    "recovery_percentage": {"column_src": "recouv"},
                    "station_name": {"column_src": "nomStation"},
                    "technical_precision": {"column_src": "precisionTechnique"},
                    "unique_dataset_id": {"column_src": "jddMetaId"},
                    "unique_id_sinp_grp_phyto": {"column_src": "relevePhyto"},
                    "unique_id_sinp_habitat": {"column_src": "idSinpHab"},
                    "unique_id_sinp_station": {"column_src": "permId"},
                },
            )
        )

    session.commit()
    session.close()


def downgrade():
    conn = op.get_bind()
    MappingTemplate, FieldMapping = get_models(conn)

    cte = (
        sa.select(MappingTemplate.c.id)
        .where(MappingTemplate.c.label.in_(["Occhab", "Occurrences d'habitats SINP"]))
        .cte("mapping_cte")
    )
    op.execute(sa.delete(FieldMapping).where(FieldMapping.c.id == cte.c.id))
    op.execute(sa.delete(MappingTemplate).where(MappingTemplate.c.id == cte.c.id))
