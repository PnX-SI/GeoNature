"""fill English labels of the Synthese import fields and of the themes

Revision ID: 334f26c6fd38
Revises: ed1de98c65aa
Create Date: 2026-10-29 18:00:00

Only empty labels are filled. The downgrade sets back to NULL the labels still equal to
the ones set here, a label typed by hand with the same text included.
"""

from alembic import op

revision = "334f26c6fd38"
down_revision = "ed1de98c65aa"
branch_labels = None
depends_on = None

FIELDS = """
        ('WKT', 'Geometry (WKT)'),
        ('additional_data', 'Additional fields'),
        ('altitude_max', 'Maximum altitude'),
        ('altitude_min', 'Minimum altitude'),
        ('altitudes_generate', 'Generate missing altitudes'),
        ('cd_hab', 'Habitat code'),
        ('cd_nom', 'TaxRef cd_nom'),
        ('codecommune', 'Municipality code'),
        ('codedepartement', 'Department code'),
        ('codemaille', 'Grid cell code'),
        ('comment_context', 'Survey comment'),
        ('comment_description', 'Occurrence comment'),
        ('count_max', 'Maximum count'),
        ('count_min', 'Minimum count'),
        ('date_max', 'End date'),
        ('date_min', 'Start date'),
        ('datetime_max', 'End date'),
        ('datetime_min', 'Start date'),
        ('depth_max', 'Maximum depth'),
        ('depth_min', 'Minimum depth'),
        ('determiner', 'Determiner'),
        ('digital_proof', 'Digital proof'),
        ('entity_source_pk_value', 'Source identifier'),
        ('grp_method', 'Grouping method'),
        ('hour_max', 'End time'),
        ('hour_min', 'Start time'),
        ('id_area_attachment', 'Geographic attachment of the observation'),
        ('id_dataset', 'Dataset ID'),
        ('id_digitiser', 'Digitiser ID (id_role in the target instance)'),
        ('id_nomenclature_behaviour', 'Behaviour'),
        ('id_nomenclature_bio_condition', 'Biological condition'),
        ('id_nomenclature_bio_status', 'Biological status'),
        ('id_nomenclature_biogeo_status', 'Biogeographic status'),
        ('id_nomenclature_blurring', 'Blurring level'),
        ('id_nomenclature_determination_method', 'Determination method'),
        ('id_nomenclature_diffusion_level', 'Diffusion level'),
        ('id_nomenclature_exist_proof', 'Existence of a proof'),
        ('id_nomenclature_geo_object_nature', 'Geographic object nature'),
        ('id_nomenclature_grp_typ', 'Survey/grouping type'),
        ('id_nomenclature_life_stage', 'Life stage'),
        ('id_nomenclature_naturalness', 'Naturalness'),
        ('id_nomenclature_obj_count', 'Counted object'),
        ('id_nomenclature_obs_technique', 'Observation techniques'),
        ('id_nomenclature_observation_status', 'Observation status'),
        ('id_nomenclature_sensitivity', 'Sensitivity'),
        ('id_nomenclature_sex', 'Sex'),
        ('id_nomenclature_source_status', 'Source status'),
        ('id_nomenclature_type_count', 'Count type'),
        ('id_nomenclature_valid_status', 'Validation status'),
        ('latitude', 'Latitude (y coord)'),
        ('longitude', 'Longitude (x coord)'),
        ('meta_create_date', 'Record creation date'),
        ('meta_update_date', 'Record update date'),
        ('meta_v_taxref', 'Taxonomic reference version'),
        ('meta_validation_date', 'Validation date'),
        ('nom_cite', 'Cited taxon name'),
        ('non_digital_proof', 'Non-digital proof'),
        ('observers', 'Observer(s)'),
        ('place_name', 'Place name'),
        ('precision', 'Pointing accuracy (m)'),
        ('reference_biblio', 'Bibliographic reference'),
        ('the_geom_4326', 'Geometry (SRID 4326)'),
        ('the_geom_local', 'Geometry (local SRID)'),
        ('the_geom_point', 'Geometry (Point)'),
        ('unique_dataset_id', 'Dataset ID (UUID)'),
        ('unique_id_sinp', 'SINP ID (uuid)'),
        ('unique_id_sinp_generate', 'Generate missing SINP identifiers'),
        ('unique_id_sinp_grp', 'Survey ID (uuid)'),
        ('validation_comment', 'Validation comment'),
        ('validator', 'Validator')
"""

THEMES = """
        ('general_info', 'General information'),
        ('statement_info', 'Survey information'),
        ('occurrence_sensitivity', 'Occurrence information & sensitivity'),
        ('enumeration', 'Counts'),
        ('validation', 'Determination and validity'),
        ('additional_data', 'Additional fields')
"""


def upgrade():
    op.execute(f"""
        UPDATE gn_imports.bib_fields f SET eng_label = v.label
        FROM gn_imports.bib_destinations d, (VALUES
{FIELDS}
        ) AS v (name_field, label)
        WHERE f.id_destination = d.id_destination AND d.code = 'synthese'
          AND f.name_field = v.name_field AND coalesce(f.eng_label, '') = ''
        """)
    op.execute(f"""
        UPDATE gn_imports.bib_themes t SET eng_label_theme = v.label
        FROM (VALUES
{THEMES}
        ) AS v (name_theme, label)
        WHERE t.name_theme = v.name_theme AND coalesce(t.eng_label_theme, '') = ''
        """)


def downgrade():
    op.execute(f"""
        UPDATE gn_imports.bib_fields f SET eng_label = NULL
        FROM gn_imports.bib_destinations d, (VALUES
{FIELDS}
        ) AS v (name_field, label)
        WHERE f.id_destination = d.id_destination AND d.code = 'synthese'
          AND f.name_field = v.name_field AND f.eng_label = v.label
        """)
    op.execute(f"""
        UPDATE gn_imports.bib_themes t SET eng_label_theme = NULL
        FROM (VALUES
{THEMES}
        ) AS v (name_theme, label)
        WHERE t.name_theme = v.name_theme AND t.eng_label_theme = v.label
        """)
