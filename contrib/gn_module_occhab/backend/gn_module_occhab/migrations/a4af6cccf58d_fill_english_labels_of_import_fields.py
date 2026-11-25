"""fill English labels of the Occhab import fields

Revision ID: a4af6cccf58d
Revises: 53e6505aaaa9
Create Date: 2026-10-29 18:00:00

Only empty labels are filled. The downgrade sets back to NULL the labels still equal to
the ones set here, a label typed by hand with the same text included.
"""

from alembic import op

revision = "a4af6cccf58d"
down_revision = "53e6505aaaa9"
branch_labels = None
depends_on = None

FIELDS = """
        ('WKT', 'Geometry (WKT)'),
        ('altitude_max', 'Maximum altitude'),
        ('altitude_min', 'Minimum altitude'),
        ('area', 'Station area'),
        ('cd_hab', 'Habitat code'),
        ('comment', 'Comment'),
        ('date_max', 'End date'),
        ('date_min', 'Start date'),
        ('depth_max', 'Maximum depth'),
        ('depth_min', 'Minimum depth'),
        ('determiner', 'Code determiner'),
        ('geom_4326', 'Geometry (SRID 4326)'),
        ('geom_local', 'Geometry (local SRID)'),
        ('id_dataset', 'Dataset ID'),
        ('id_digitiser', 'Digitiser ID (id_role in the target instance)'),
        ('id_nomenclature_abundance', 'Relative abundance of the habitat'),
        ('id_nomenclature_area_surface_calculation', 'Area calculation method'),
        ('id_nomenclature_collection_technique', 'Collection technique'),
        ('id_nomenclature_community_interest', 'Community interest'),
        ('id_nomenclature_determination_type', 'Determination type'),
        ('id_nomenclature_exposure', 'Station exposure'),
        ('id_nomenclature_geographic_object', 'Location nature'),
        ('id_nomenclature_sensitivity', 'Habitat sensitivity'),
        ('id_nomenclature_type_mosaique_habitat', 'Habitat mosaic'),
        ('id_nomenclature_type_sol', 'Soil type'),
        ('id_station', 'Station ID'),
        ('id_station_source', 'Original station ID'),
        ('latitude', 'Latitude (y coord)'),
        ('longitude', 'Longitude (x coord)'),
        ('nom_cite', 'Cited name'),
        ('numerization_scale', 'Map scale used for digitising'),
        ('observers_txt', 'Observers'),
        ('precision', 'Geometric accuracy (metres)'),
        ('recovery_percentage', 'Cover percentage'),
        ('station_name', 'Station name'),
        ('technical_precision', 'Collection technique details'),
        ('unique_dataset_id', 'Dataset ID (UUID)'),
        ('unique_id_sinp_grp_occtax', 'Occtax survey ID (UUID)'),
        ('unique_id_sinp_grp_phyto', 'Phytosociological survey ID (UUID)'),
        ('unique_id_sinp_habitat', 'Habitat ID (UUID)'),
        ('unique_id_sinp_station', 'Station ID (UUID)')
"""


def upgrade():
    op.execute(f"""
        UPDATE gn_imports.bib_fields f SET eng_label = v.label
        FROM gn_imports.bib_destinations d, (VALUES
{FIELDS}
        ) AS v (name_field, label)
        WHERE f.id_destination = d.id_destination AND d.code = 'occhab'
          AND f.name_field = v.name_field AND coalesce(f.eng_label, '') = ''
        """)


def downgrade():
    op.execute(f"""
        UPDATE gn_imports.bib_fields f SET eng_label = NULL
        FROM gn_imports.bib_destinations d, (VALUES
{FIELDS}
        ) AS v (name_field, label)
        WHERE f.id_destination = d.id_destination AND d.code = 'occhab'
          AND f.name_field = v.name_field AND f.eng_label = v.label
        """)
