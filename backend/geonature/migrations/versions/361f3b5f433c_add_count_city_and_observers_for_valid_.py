"""[Fiche espèce] Add count city and observers for valid obs

Revision ID: 361f3b5f433c
Revises: 9f4db1786c22
Create Date: 2024-07-22 08:43:44.975518

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "361f3b5f433c"
down_revision = "9f4db1786c22"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
DROP VIEW gn_profiles.v_consistancy_data;
DROP MATERIALIZED VIEW gn_profiles.vm_valid_profiles;
        """
    )
    op.execute(
        """
CREATE MATERIALIZED VIEW gn_profiles.vm_valid_profiles
TABLESPACE pg_default
AS select
	distinct cd_ref,
	st_union(st_buffer(vsfp.the_geom_local,
	coalesce(vsfp.spatial_precision,
	1)::double precision)) as valid_distribution,
	min(vsfp.altitude_min) as altitude_min,
	max(vsfp.altitude_max) as altitude_max,
	min(vsfp.date_min) as first_valid_data,
	max(vsfp.date_max) as last_valid_data,
	count(vsfp.*) as count_valid_data,
	vsfp.active_life_stage,
	count(distinct(s.observers)) as count_observers,
	count(distinct communes.id_area) as count_city
from
	gn_profiles.v_synthese_for_profiles vsfp
	join gn_synthese.synthese s on
	vsfp.id_synthese = s.id_synthese
	join gn_synthese.cor_area_synthese on
	vsfp.id_synthese = gn_synthese.cor_area_synthese.id_synthese
join (
	select
		ref_geo.l_areas.id_area as id_area FROM ref_geo.l_areas,
		ref_geo.bib_areas_types WHERE ref_geo.l_areas.id_type = ref_geo.bib_areas_types.id_type
			and ref_geo.bib_areas_types.type_code = 'COM') as communes on
	gn_synthese.cor_area_synthese.id_area = communes.id_area
join ref_geo.l_areas on
	gn_synthese.cor_area_synthese.id_area = ref_geo.l_areas.id_area
join ref_geo.bib_areas_types on
	ref_geo.l_areas.id_type = ref_geo.bib_areas_types.id_type
group by
	cd_ref,
	active_life_stage
WITH DATA;

-- View indexes:
CREATE UNIQUE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref);
        """
    )
    op.execute(
        """
        CREATE VIEW gn_profiles.v_consistancy_data AS
SELECT s.id_synthese,
    s.unique_id_sinp AS id_sinp,
    t.cd_ref,
    t.lb_nom AS valid_name,
    gn_profiles.check_profile_distribution(s.the_geom_local, p.valid_distribution) AS valid_distribution,
    gn_profiles.check_profile_phenology(
      t.cd_ref, s.date_min::date, s.date_max::date, s.altitude_min, s.altitude_max, s.id_nomenclature_life_stage, p.active_life_stage
    ) AS valid_phenology,
    gn_profiles.check_profile_altitudes(
        s.altitude_min, s.altitude_max, p.altitude_min, p.altitude_max
    ) AS valid_altitude,
    n.label_default AS valid_status
FROM gn_synthese.synthese s
JOIN taxonomie.taxref t
    ON s.cd_nom = t.cd_nom
JOIN gn_profiles.vm_valid_profiles p
    ON p.cd_ref = t.cd_ref
LEFT JOIN ref_nomenclatures.t_nomenclatures n
    ON s.id_nomenclature_valid_status = n.id_nomenclature
;
        """
    )


def downgrade():
    op.execute(
        """
DROP VIEW gn_profiles.v_consistancy_data;
DROP MATERIALIZED VIEW gn_profiles.vm_valid_profiles;
        """
    )

    op.execute(
        """
        CREATE MATERIALIZED VIEW gn_profiles.vm_valid_profiles
        TABLESPACE pg_default
        AS SELECT DISTINCT cd_ref,
            st_union(st_buffer(the_geom_local, COALESCE(spatial_precision, 1)::double precision)) AS valid_distribution,
            min(altitude_min) AS altitude_min,
            max(altitude_max) AS altitude_max,
            min(date_min) AS first_valid_data,
            max(date_max) AS last_valid_data,
            count(vsfp.*) AS count_valid_data,
            active_life_stage
        FROM gn_profiles.v_synthese_for_profiles vsfp
        GROUP BY cd_ref, active_life_stage
        WITH DATA;

        -- View indexes:
        CREATE UNIQUE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref);
        """
    )
    op.execute(
        """
        CREATE VIEW gn_profiles.v_consistancy_data AS
SELECT s.id_synthese,
    s.unique_id_sinp AS id_sinp,
    t.cd_ref,
    t.lb_nom AS valid_name,
    gn_profiles.check_profile_distribution(s.the_geom_local, p.valid_distribution) AS valid_distribution,
    gn_profiles.check_profile_phenology(
      t.cd_ref, s.date_min::date, s.date_max::date, s.altitude_min, s.altitude_max, s.id_nomenclature_life_stage, p.active_life_stage
    ) AS valid_phenology,
    gn_profiles.check_profile_altitudes(
        s.altitude_min, s.altitude_max, p.altitude_min, p.altitude_max
    ) AS valid_altitude,
    n.label_default AS valid_status
FROM gn_synthese.synthese s
JOIN taxonomie.taxref t
    ON s.cd_nom = t.cd_nom
JOIN gn_profiles.vm_valid_profiles p
    ON p.cd_ref = t.cd_ref
LEFT JOIN ref_nomenclatures.t_nomenclatures n
    ON s.id_nomenclature_valid_status = n.id_nomenclature
;
        """
    )
