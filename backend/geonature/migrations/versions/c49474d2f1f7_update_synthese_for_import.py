"""update synthese for import

Revision ID: c49474d2f1f7
Revises: a8a17e29f69c
Create Date: 2024-10-01 10:09:10.937073

"""

from alembic import op
from sqlalchemy.orm import Session
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c49474d2f1f7"
down_revision = "a8a17e29f69c"
branch_labels = None
depends_on = None


def upgrade():
    # modifier la suppression de l'import synthese
    # modifier la création de la synthese depuis l'import
    # ajouter un filtre pour filtrer sur l'id_import
    # le mettre par default quand dans l'url
    op.add_column(
        schema="gn_synthese",
        table_name="synthese",
        column=sa.Column("id_import", sa.Integer()),
    )
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_sources = sa.Table("t_sources", metadata, schema="gn_synthese", autoload_with=conn)
    t_modules = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    t_synthese = sa.Table("synthese", metadata, schema="gn_synthese", autoload_with=conn)
    id_import_module = conn.execute(
        sa.select(t_modules.c.id_module).where(t_modules.c.module_code == "IMPORT")
    ).scalar_one()
    results = conn.execute(
        t_sources.insert()
        .values(
            name_source="Import",
            desc_source="Données issues du module Import",
            entity_source_pk_field="entity_source_pk_value",
            id_module=id_import_module,
        )
        .returning(t_sources.c.id_source)
    )
    id_source = [id_source for id_source, in results][0]
    op.execute(
        sa.update(t_synthese)
        .where(t_synthese.c.id_source == t_sources.c.id_source)
        .where(t_sources.c.id_module == id_import_module)
        .values(
            id_source=id_source,
            id_import=sa.func.cast(
                sa.func.regexp_replace(
                    t_sources.c.name_source,
                    r"^Import\(id=(\d+)\)$",
                    r"\1",
                    flags="g",
                ),
                sa.INT,
            ),
        )
    )
    conn.execute(
        t_sources.delete()
        .where(t_sources.c.id_module == id_import_module)
        .where(t_sources.c.id_source != id_source)
    )

    op.execute(
        """
        DROP VIEW gn_synthese.v_synthese_for_web_app;
        """
    )

    op.execute(
        """
        CREATE VIEW gn_synthese.v_synthese_for_web_app AS
        SELECT s.id_synthese,
            s.unique_id_sinp,
            s.unique_id_sinp_grp,
            s.id_source,
            s.entity_source_pk_value,
            s.count_min,
            s.count_max,
            s.nom_cite,
            s.meta_v_taxref,
            s.sample_number_proof,
            s.digital_proof,
            s.non_digital_proof,
            s.altitude_min,
            s.altitude_max,
            s.depth_min,
            s.depth_max,
            s.place_name,
            s."precision",
            s.the_geom_4326,
            st_asgeojson(s.the_geom_4326) AS st_asgeojson,
            s.date_min,
            s.date_max,
            s.validator,
            s.validation_comment,
            s.observers,
            s.id_digitiser,
            s.determiner,
            s.comment_context,
            s.comment_description,
            s.meta_validation_date,
            s.meta_create_date,
            s.meta_update_date,
            s.last_action,
            d.id_dataset,
            d.dataset_name,
            d.id_acquisition_framework,
            s.id_nomenclature_geo_object_nature,
            s.id_nomenclature_info_geo_type,
            s.id_nomenclature_grp_typ,
            s.grp_method,
            s.id_nomenclature_obs_technique,
            s.id_nomenclature_bio_status,
            s.id_nomenclature_bio_condition,
            s.id_nomenclature_naturalness,
            s.id_nomenclature_exist_proof,
            s.id_nomenclature_valid_status,
            s.id_nomenclature_diffusion_level,
            s.id_nomenclature_life_stage,
            s.id_nomenclature_sex,
            s.id_nomenclature_obj_count,
            s.id_nomenclature_type_count,
            s.id_nomenclature_sensitivity,
            s.id_nomenclature_observation_status,
            s.id_nomenclature_blurring,
            s.id_nomenclature_source_status,
            s.id_nomenclature_determination_method,
            s.id_nomenclature_behaviour,
            s.reference_biblio,
            sources.name_source,
            sources.url_source,
            t.cd_nom,
            t.cd_ref,
            t.nom_valide,
            t.lb_nom,
            t.nom_vern,
            s.id_module,
            t.group1_inpn,
            t.group2_inpn,
            t.group3_inpn,
            s.id_import
        FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
        """
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_sources = sa.Table("t_sources", metadata, schema="gn_synthese", autoload_with=conn)
    t_modules = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    t_synthese = sa.Table("synthese", metadata, schema="gn_synthese", autoload_with=conn)
    query = (
        sa.select(
            (sa.func.concat("Import(id=", t_synthese.c.id_import, ")")).label("name_source"),
            (
                sa.func.concat("Imported data from import module (id=", t_synthese.c.id_import, ")")
            ).label("desc_source"),
            (sa.literal("entity_source_pk_value")).label("entity_source_pk_field"),
            ((sa.select(t_modules.c.id_module).where(t_modules.c.module_code == "IMPORT"))).label(
                "id_module"
            ),
        )
        .where(t_synthese.c.id_import != None)
        .distinct(t_synthese.c.id_import)
    )
    conn.execute(
        t_sources.insert().from_select(
            ["name_source", "desc_source", "entity_source_pk_field", "id_module"], query
        )
    )
    conn.execute(
        sa.update(t_synthese)
        .where(t_synthese.c.id_import != None)
        .where(t_sources.c.name_source == sa.func.concat("Import(id=", t_synthese.c.id_import, ")"))
        .values(id_import=None, id_source=t_sources.c.id_source)
    )
    op.execute(t_sources.delete().where(t_sources.c.name_source == "Import"))
    op.drop_column(
        schema="gn_synthese",
        table_name="synthese",
        column_name="id_import",
    )

    op.execute(
        """
        DROP VIEW gn_synthese.v_synthese_for_web_app;
        """
    )

    op.execute(
        """
        CREATE VIEW gn_synthese.v_synthese_for_web_app AS
        SELECT s.id_synthese,
            s.unique_id_sinp,
            s.unique_id_sinp_grp,
            s.id_source,
            s.entity_source_pk_value,
            s.count_min,
            s.count_max,
            s.nom_cite,
            s.meta_v_taxref,
            s.sample_number_proof,
            s.digital_proof,
            s.non_digital_proof,
            s.altitude_min,
            s.altitude_max,
            s.depth_min,
            s.depth_max,
            s.place_name,
            s."precision",
            s.the_geom_4326,
            st_asgeojson(s.the_geom_4326) AS st_asgeojson,
            s.date_min,
            s.date_max,
            s.validator,
            s.validation_comment,
            s.observers,
            s.id_digitiser,
            s.determiner,
            s.comment_context,
            s.comment_description,
            s.meta_validation_date,
            s.meta_create_date,
            s.meta_update_date,
            s.last_action,
            d.id_dataset,
            d.dataset_name,
            d.id_acquisition_framework,
            s.id_nomenclature_geo_object_nature,
            s.id_nomenclature_info_geo_type,
            s.id_nomenclature_grp_typ,
            s.grp_method,
            s.id_nomenclature_obs_technique,
            s.id_nomenclature_bio_status,
            s.id_nomenclature_bio_condition,
            s.id_nomenclature_naturalness,
            s.id_nomenclature_exist_proof,
            s.id_nomenclature_valid_status,
            s.id_nomenclature_diffusion_level,
            s.id_nomenclature_life_stage,
            s.id_nomenclature_sex,
            s.id_nomenclature_obj_count,
            s.id_nomenclature_type_count,
            s.id_nomenclature_sensitivity,
            s.id_nomenclature_observation_status,
            s.id_nomenclature_blurring,
            s.id_nomenclature_source_status,
            s.id_nomenclature_determination_method,
            s.id_nomenclature_behaviour,
            s.reference_biblio,
            sources.name_source,
            sources.url_source,
            t.cd_nom,
            t.cd_ref,
            t.nom_valide,
            t.lb_nom,
            t.nom_vern,
            s.id_module,
            t.group1_inpn,
            t.group2_inpn,
            t.group3_inpn
        FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
        """
    )
