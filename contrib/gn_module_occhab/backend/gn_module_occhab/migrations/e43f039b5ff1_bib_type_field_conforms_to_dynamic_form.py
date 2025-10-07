"""bib.type_field conforms to dynamic form

Revision ID: e43f039b5ff1
Revises: 650f1d749b3b
Create Date: 2024-12-13 14:37:45.171977

"""

import json
from alembic import op
import sqlalchemy as sa
from sqlalchemy.orm import Session
from sqlalchemy.schema import Table, MetaData


# revision identifiers, used by Alembic.
revision = "e43f039b5ff1"
down_revision = "650f1d749b3b"
branch_labels = None
depends_on = ("a94bea44ab56",)


def upgrade():
    session = Session(bind=op.get_bind())
    conn = op.get_bind()
    meta = sa.MetaData(bind=conn)
    bib_fields = sa.Table("bib_fields", meta, autoload_with=conn, schema="gn_imports")

    id_destination = session.scalar(
        sa.text("SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'occhab'")
    )

    updates = {
        "altitude_max": "number",
        "altitude_min": "number",
        "area": "number",
        "cd_hab": "number",
        "comment": "textarea",
        "date_max": "date",
        "date_min": "date",
        "depth_max": "number",
        "depth_min": "number",
        "determiner": "textarea",
        "geom_4326": "textarea",
        "geom_local": "textarea",
        "id_dataset": "textarea",
        "id_digitiser": "number",
        "id_habitat": "number",
        "id_nomenclature_abundance": "nomenclature",
        "id_nomenclature_area_surface_calculation": "nomenclature",
        "id_nomenclature_collection_technique": "nomenclature",
        "id_nomenclature_community_interest": "nomenclature",
        "id_nomenclature_determination_type": "nomenclature",
        "id_nomenclature_exposure": "nomenclature",
        "id_nomenclature_geographic_object": "nomenclature",
        "id_nomenclature_sensitivity": "nomenclature",
        "id_nomenclature_type_mosaique_habitat": "nomenclature",
        "id_station": "number",
        "id_station_source": "number",
        "latitude": "number",
        "longitude": "number",
        "nom_cite": "taxonomy",
        "numerization_scale": "textarea",
        "observers_txt": "textarea",
        "precision": "textarea",
        "recovery_percentage": ["number", '{"min":0, "max":100}'],
        "station_name": "textarea",
        "technical_precision": "textarea",
        "unique_dataset_id": "dataset",
        "unique_id_sinp_grp_occtax": "textarea",
        "unique_id_sinp_grp_phyto": "textarea",
        "unique_id_sinp_habitat": "textarea",
        "unique_id_sinp_station": "textarea",
        "WKT": "textarea",
    }

    for name_field, value in updates.items():
        if isinstance(value, str):
            values = {
                "type_field": value,
            }
        else:
            values = {
                "type_field": value[0],
                "type_field_params": json.loads(value[1]),
            }

        op.execute(
            sa.update(bib_fields)
            .where(
                bib_fields.c.name_field == name_field, bib_fields.c.id_destination == id_destination
            )
            .values(values)
        )


def downgrade():
    pass
