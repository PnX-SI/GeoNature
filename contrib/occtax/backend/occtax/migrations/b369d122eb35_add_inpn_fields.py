"""add inpn fields

Revision ID: b369d122eb35
Revises: b66d30f4e3d1
Create Date: 2025-08-01 10:58:32.347820
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision = "b369d122eb35"
down_revision = "b66d30f4e3d1"
branch_labels = None
depends_on = None


def _backup_view(conn, schema: str, view: str):
    """Return (definition, list of GRANTs) for the specified view."""
    view_def = conn.execute(
        text(f"SELECT pg_get_viewdef('{schema}.{view}'::regclass, true)")
    ).scalar()

    grants = conn.execute(
        text(
            f"""
            SELECT array_agg('GRANT ' || privilege_type || ' ON {schema}.{view} TO ' || grantee)
            FROM information_schema.role_table_grants
            WHERE table_schema = :schema AND table_name = :view
        """
        ),
        {"schema": schema, "view": view},
    ).scalar()

    if grants is None:
        grants = []
    else:
        grants = list(grants)

    return view_def, grants


def _restore_view(conn, schema: str, view: str, view_def: str, grants: list):
    """Recreate the view and reapply its GRANTs."""
    conn.execute(text(f"CREATE VIEW {schema}.{view} AS {view_def};"))
    for grant in grants:
        conn.execute(text(grant))


def upgrade():
    conn = op.get_bind()

    schema = "pr_occtax"
    view = "v_export_occtax"

    # --- Add new columns to t_releves_occtax ---
    # "code_releve" is not in the inpn standard but needed by the community
    op.add_column(
        "t_releves_occtax",
        sa.Column("code_releve", sa.String(length=50), nullable=True),
        schema=schema,
    )
    op.add_column(
        "t_releves_occtax", sa.Column("slope", sa.Numeric(4, 2), nullable=True), schema=schema
    )
    op.add_column(
        "t_releves_occtax", sa.Column("area", sa.Numeric(20, 2), nullable=True), schema=schema
    )
    op.add_column(
        "t_releves_occtax",
        sa.Column("id_nomenclature_exposure", sa.Integer()),
        schema=schema,
    )

    # Add foreign key constraint on id_nomenclature_exposure
    op.execute(
        """
        ALTER TABLE ONLY pr_occtax.t_releves_occtax
        ADD CONSTRAINT fk_t_releves_occtax_id_nomenclature_exposure
        FOREIGN KEY (id_nomenclature_exposure)
        REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
        ON UPDATE CASCADE
    """
    )

    # Add CHECK constraint on id_nomenclature_exposure
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax
        ADD CONSTRAINT check_t_releves_occtax_exposure
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exposure, 'EXPOSITION'))
        NOT VALID
    """
    )

    op.add_column(
        "t_releves_occtax",
        sa.Column("id_nomenclature_location_type", sa.Integer()),
        schema=schema,
    )

    op.add_column(
        "t_releves_occtax",
        sa.Column("id_area_attachement", sa.Integer()),
        schema=schema,
    )

    # --- Add new columns to t_occurrences_occtax ---
    op.add_column(
        "t_occurrences_occtax",
        sa.Column("id_nomenclature_organism_support", sa.Integer()),
        schema=schema,
    )

    # Add foreign key constraint on id_nomenclature_organism_support
    op.execute(
        """
        ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
        ADD CONSTRAINT fk_t_occurrences_occtax_id_nomenclature_organism_support
        FOREIGN KEY (id_nomenclature_organism_support)
        REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
        ON UPDATE CASCADE
    """
    )

    # Add CHECK constraint on id_nomenclature_organism_support
    op.execute(
        """
        ALTER TABLE pr_occtax.t_occurrences_occtax
        ADD CONSTRAINT check_t_occurrences_occtax_organism_support
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_organism_support, 'SUPPORT_ORGANISM'))
        NOT VALID
    """
    )

    # --- Recreate export view ---
    # Backup current view def + grants, drop view (dependency on "precision"), alter column, then recreate with new fields.
    grants = _backup_view(conn, schema, view)[1]
    op.execute(f"DROP VIEW {schema}.{view};")

    op.alter_column(
        "t_releves_occtax",
        "precision",
        type_=sa.Numeric(10, 2),
        schema=schema,
        postgresql_using="precision::NUMERIC(10,2)",
    )

    new_view_def = """
    SELECT rel.unique_id_sinp_grp AS "idSINPRegroupement",
        ref_nomenclatures.get_cd_nomenclature(rel.id_nomenclature_grp_typ) AS "typGrp",
        rel.grp_method AS "methGrp",
        ccc.unique_id_sinp_occtax AS "permId",
        ccc.id_counting_occtax AS "idOrigine",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_observation_status) AS "statObs",
        occ.nom_cite AS "nomCite",
        to_char(rel.date_min, 'YYYY-MM-DD'::text) AS "dateDebut",
        to_char(rel.date_max, 'YYYY-MM-DD'::text) AS "dateFin",
        rel.hour_min AS "heureDebut",
        rel.hour_max AS "heureFin",
        rel.altitude_max AS "altMax",
        rel.altitude_min AS "altMin",
        rel.depth_min AS "profMin",
        rel.depth_max AS "profMax",
        occ.cd_nom AS "cdNom",
        tax.cd_ref AS "cdRef",
        ref_nomenclatures.get_nomenclature_label(d.id_nomenclature_data_origin) AS "dSPublique",
        d.unique_dataset_id AS "jddMetaId",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_source_status) AS "statSource",
        d.dataset_name AS "jddCode",
        d.unique_dataset_id AS "jddId",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_obs_technique) AS "obsTech",
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_tech_collect_campanule) AS "techCollect",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_naturalness) AS "ocNat",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_sex) AS "ocSex",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_life_stage) AS "ocStade",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_status) AS "ocStatBio",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_exist_proof) AS "preuveOui",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method) AS "ocMethDet",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_behaviour) AS "occComp",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_organism_support) AS "ocSupport",
        occ.digital_proof AS "preuvNum",
        occ.non_digital_proof AS "preuvNoNum",
        rel.comment AS "obsCtx",
        occ.comment AS "obsDescr",
        rel.unique_id_sinp_grp AS "permIdGrp",
        ccc.count_max AS "denbrMax",
        ccc.count_min AS "denbrMin",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_obj_count) AS "objDenbr",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_type_count) AS "typDenbr",
        COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
        COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
        COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_geo_object_nature) AS "natObjGeo",
        st_astext(rel.geom_4326) AS "WKT",
        tax.lb_nom AS "nomScienti",
        tax.nom_vern AS "nomVern",
        hab.lb_code AS "codeHab",
        hab.lb_hab_fr AS "nomHab",
        hab.cd_hab,
        rel.date_min,
        rel.date_max,
        rel.id_dataset,
        rel.id_releve_occtax,
        occ.id_occurrence_occtax,
        rel.id_digitiser,
        rel.geom_4326,
        rel.place_name AS "nomLieu",
        rel."precision",
        rel.slope,
        rel.area,
        rel.code_releve,
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_exposure) AS "exposition",
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_location_type) AS "typeLieu",
        ref_nomenclatures.get_nomenclature_label(rel.id_area_attachement) AS "zoneReference",
        (COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb)) || COALESCE(ccc.additional_fields, '{}'::jsonb) AS additional_data
    FROM pr_occtax.t_releves_occtax rel
        LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
        LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
        LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
        LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
        LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
        LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
        LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
        LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = rel.cd_hab
    GROUP BY ccc.id_counting_occtax, occ.id_occurrence_occtax, rel.id_releve_occtax, d.id_dataset, tax.cd_ref, tax.lb_nom, tax.nom_vern, hab.cd_hab, hab.lb_code, hab.lb_hab_fr
    """

    _restore_view(conn, schema, view, new_view_def, grants)


def downgrade():
    conn = op.get_bind()

    schema = "pr_occtax"
    view = "v_export_occtax"

    # Backup view Grants
    grants = _backup_view(conn, schema, view)[1]
    # Drop the current view
    op.execute(f"DROP VIEW {schema}.{view};")

    # Revert the type of precision (NUMERIC -> INTEGER)
    op.alter_column(
        "t_releves_occtax",
        "precision",
        type_=sa.Integer(),
        schema=schema,
        postgresql_using="precision::INTEGER",
    )

    # Recreate the original view
    original_view_select = """
    SELECT rel.unique_id_sinp_grp AS "idSINPRegroupement",
        ref_nomenclatures.get_cd_nomenclature(rel.id_nomenclature_grp_typ) AS "typGrp",
        rel.grp_method AS "methGrp",
        ccc.unique_id_sinp_occtax AS "permId",
        ccc.id_counting_occtax AS "idOrigine",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_observation_status) AS "statObs",
        occ.nom_cite AS "nomCite",
        to_char(rel.date_min, 'YYYY-MM-DD'::text) AS "dateDebut",
        to_char(rel.date_max, 'YYYY-MM-DD'::text) AS "dateFin",
        rel.hour_min AS "heureDebut",
        rel.hour_max AS "heureFin",
        rel.altitude_max AS "altMax",
        rel.altitude_min AS "altMin",
        rel.depth_min AS "profMin",
        rel.depth_max AS "profMax",
        occ.cd_nom AS "cdNom",
        tax.cd_ref AS "cdRef",
        ref_nomenclatures.get_nomenclature_label(d.id_nomenclature_data_origin) AS "dSPublique",
        d.unique_dataset_id AS "jddMetaId",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_source_status) AS "statSource",
        d.dataset_name AS "jddCode",
        d.unique_dataset_id AS "jddId",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_obs_technique) AS "obsTech",
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_tech_collect_campanule) AS "techCollect",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_naturalness) AS "ocNat",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_sex) AS "ocSex",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_life_stage) AS "ocStade",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_status) AS "ocStatBio",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_exist_proof) AS "preuveOui",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method) AS "ocMethDet",
        ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_behaviour) AS "occComp",
        occ.digital_proof AS "preuvNum",
        occ.non_digital_proof AS "preuvNoNum",
        rel.comment AS "obsCtx",
        occ.comment AS "obsDescr",
        rel.unique_id_sinp_grp AS "permIdGrp",
        ccc.count_max AS "denbrMax",
        ccc.count_min AS "denbrMin",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_obj_count) AS "objDenbr",
        ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_type_count) AS "typDenbr",
        COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
        COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
        COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
        ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_geo_object_nature) AS "natObjGeo",
        st_astext(rel.geom_4326) AS "WKT",
        tax.lb_nom AS "nomScienti",
        tax.nom_vern AS "nomVern",
        hab.lb_code AS "codeHab",
        hab.lb_hab_fr AS "nomHab",
        hab.cd_hab,
        rel.date_min,
        rel.date_max,
        rel.id_dataset,
        rel.id_releve_occtax,
        occ.id_occurrence_occtax,
        rel.id_digitiser,
        rel.geom_4326,
        rel.place_name AS "nomLieu",
        rel."precision",
        (COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb)) || COALESCE(ccc.additional_fields, '{}'::jsonb) AS additional_data
    FROM pr_occtax.t_releves_occtax rel
        LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
        LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
        LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
        LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
        LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
        LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
        LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
        LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = rel.cd_hab
    GROUP BY ccc.id_counting_occtax, occ.id_occurrence_occtax, rel.id_releve_occtax, d.id_dataset, tax.cd_ref, tax.lb_nom, tax.nom_vern, hab.cd_hab, hab.lb_code, hab.lb_hab_fr
    """

    _restore_view(conn, schema, view, original_view_select, grants)

    # Remove the columns added by the upgrade
    op.drop_column("t_releves_occtax", "code_releve", schema=schema)
    op.drop_column("t_releves_occtax", "slope", schema=schema)
    op.drop_column("t_releves_occtax", "area", schema=schema)
    # Drop CHECK and foreign key constraints for t_releves_occtax
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax
        DROP CONSTRAINT IF EXISTS check_t_releves_occtax_exposure
    """
    )
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax
        DROP CONSTRAINT IF EXISTS fk_t_releves_occtax_id_nomenclature_exposure
    """
    )
    op.drop_column("t_releves_occtax", "id_nomenclature_exposure", schema=schema)
    op.drop_column("t_releves_occtax", "id_nomenclature_location_type", schema=schema)
    op.drop_column("t_releves_occtax", "id_area_attachement", schema=schema)
    # Drop CHECK and foreign key constraints for t_occurrences_occtax
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax
        DROP CONSTRAINT IF EXISTS check_t_occurrences_occtax_organism_support
    """
    )
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax
        DROP CONSTRAINT IF EXISTS fk_t_relevest_occurrences_occtax_id_nomenclature_organism_support
    """
    )
    op.drop_column("t_occurrences_occtax", "id_nomenclature_organism_support", schema=schema)
