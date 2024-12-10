"""add_default_mapping

Revision ID: aed662bbd88a
Revises: fcf1e091b636
Create Date: 2024-07-19 11:04:52.224271

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import Session
from sqlalchemy.sql import table, column
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.ext.mutable import MutableDict

# revision identifiers, used by Alembic.
revision = "aed662bbd88a"
down_revision = "69494f900cab"
branch_labels = None
depends_on = None


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

    session.execute(
        sa.insert(FieldMapping).values(
            id=id_occhab_mapping,
            values={
                "WKT": "geometry",
                "altitude_max": "altitude_max",
                "altitude_min": "altitude_min",
                "area": "area",
                "cd_hab": "cd_hab",
                "comment": "comment",
                "date_max": "date_fin",
                "date_min": "date_debut",
                "depth_max": "depth_max",
                "depth_min": "depth_min",
                "id_nomenclature_area_surface_calculation": "methode_calcul_surface",
                "id_nomenclature_exposure": "exposition",
                "id_nomenclature_geographic_object": "nature_objet_geo",
                "id_station_source": "id_station",
                "nom_cite": "nom_cite",
                "observers_txt": "observateurs",
                "technical_precision": "precision_technique",
                "unique_dataset_id": "uuid_jdd",
                "unique_id_sinp_habitat": "uuid_habitat",
                "unique_id_sinp_station": "uuid_station",
            },
        )
    )

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

    session.execute(
        sa.insert(FieldMapping).values(
            id=id_mapping_sinp,
            values={
                "WKT": "WKT",
                "altitude_max": "altMax",
                "altitude_min": "altMin",
                "area": "surf",
                "cd_hab": "cdHab",
                "comment": "comment",
                "date_max": "dateFin",
                "date_min": "dateDebut",
                "depth_max": "profMax",
                "depth_min": "profMin",
                "determiner": "persDeterm",
                "id_habitat": "idOrigine",
                "id_nomenclature_abundance": "abondHab",
                "id_nomenclature_area_surface_calculation": "methodeCalculSurface",
                "id_nomenclature_collection_technique": "techCollec",
                "id_nomenclature_community_interest": "habitatInteretCommunautaire ",
                "id_nomenclature_determination_type": "typeDeterm",
                "id_nomenclature_exposure": "exposition",
                "id_nomenclature_geographic_object": "natObjGeo",
                "id_nomenclature_sensitivity": "sensibiliteHab",
                "id_station_source": "idOrigEvt",
                "is_habitat_complex": "mosaique",
                "nom_cite": "nomCite",
                "numerization_scale": "echelleNumerisation",
                "observers_txt": "observer",
                "precision": "precisGeo",
                "recovery_percentage": "recouv",
                "station_name": "nomStation",
                "technical_precision": "precisionTechnique",
                "unique_dataset_id": "jddMetaId",
                "unique_id_sinp_grp_phyto": "relevePhyto",
                "unique_id_sinp_habitat": "idSinpHab",
                "unique_id_sinp_station": "permId",
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
