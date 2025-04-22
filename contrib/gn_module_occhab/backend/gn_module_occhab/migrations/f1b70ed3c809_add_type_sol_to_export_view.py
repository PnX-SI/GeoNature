"""add type sol to export view

Revision ID: f1b70ed3c809
Revises: 8a32dfdef27d
Create Date: 2025-04-22 11:56:47.992073

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f1b70ed3c809"
down_revision = "8a32dfdef27d"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP VIEW pr_occhab.v_export_sinp;")
    op.execute(
        """
        create or replace view pr_occhab.v_export_sinp as
            select
                s.id_station,
                s.id_dataset,
                s.id_digitiser,
                s.unique_id_sinp_station as "uuid_station",
                ds.unique_dataset_id as "uuid_jdd",
                to_char(s.date_min,
                'DD/MM/YYYY'::text)as "date_debut",
                to_char(s.date_max,
                'DD/MM/YYYY'::text)as "date_fin",
                coalesce(string_agg(distinct (r.nom_role::text || ' '::text) || r.prenom_role::text,
                ','::text),
                s.observers_txt::text) as "observateurs",
                nom2.cd_nomenclature as "methode_calcul_surface",
                s.area as "surface",
                public.st_astext(s.geom_4326) as "geometry",
                public.st_asgeojson(s.geom_4326) as geojson,
                s.geom_local,
                nom3.cd_nomenclature as "nature_objet_geo",
                h.unique_id_sinp_hab as "uuid_habitat",
                s.altitude_min as "altitude_min",
                s.altitude_max as "altitude_max",
                nom5.cd_nomenclature as "exposition",
                h.nom_cite as "nom_cite",
                h.cd_hab as "cd_hab",
                h.technical_precision as "precision_technique",
                nom6.cd_nomenclature as "type_sol"
            from
                pr_occhab.t_stations as s
            join pr_occhab.t_habitats h on
                h.id_station = s.id_station
            join gn_meta.t_datasets ds on
                ds.id_dataset = s.id_dataset
            left join pr_occhab.cor_station_observer cso on
                cso.id_station = s.id_station
            left join utilisateurs.t_roles r on
                r.id_role = cso.id_role
            left join ref_nomenclatures.t_nomenclatures nom1 on
                nom1.id_nomenclature = ds.id_nomenclature_data_origin
            left join ref_nomenclatures.t_nomenclatures nom2 on
                nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation
            left join ref_nomenclatures.t_nomenclatures nom3 on
                nom3.id_nomenclature = s.id_nomenclature_geographic_object
            left join ref_nomenclatures.t_nomenclatures nom4 on
                nom4.id_nomenclature = h.id_nomenclature_collection_technique
            left join ref_nomenclatures.t_nomenclatures nom5 on
                nom5.id_nomenclature = s.id_nomenclature_exposure
            left join ref_nomenclatures.t_nomenclatures nom6 on
                nom5.id_nomenclature = s.id_nomenclature_exposure
            group by
                s.id_station,
                s.id_dataset,
                ds.unique_dataset_id,
                nom2.cd_nomenclature ,
                h.technical_precision,
                h.cd_hab,
                h.nom_cite ,
                nom3.cd_nomenclature,
                h.unique_id_sinp_hab,
                nom5.cd_nomenclature,
                nom6.cd_nomenclature
            ;
    """
    )


def downgrade():
    op.execute("DROP VIEW pr_occhab.v_export_sinp;")
    op.execute(
        """
        create or replace view pr_occhab.v_export_sinp as
            select
                s.id_station,
                s.id_dataset,
                s.id_digitiser,
                s.unique_id_sinp_station as "uuid_station",
                ds.unique_dataset_id as "uuid_jdd",
                to_char(s.date_min,
                'DD/MM/YYYY'::text)as "date_debut",
                to_char(s.date_max,
                'DD/MM/YYYY'::text)as "date_fin",
                coalesce(string_agg(distinct (r.nom_role::text || ' '::text) || r.prenom_role::text,
                ','::text),
                s.observers_txt::text) as "observateurs",
                nom2.cd_nomenclature as "methode_calcul_surface",
                s.area as "surface",
                public.st_astext(s.geom_4326) as "geometry",
                public.st_asgeojson(s.geom_4326) as geojson,
                s.geom_local,
                nom3.cd_nomenclature as "nature_objet_geo",
                h.unique_id_sinp_hab as "uuid_habitat",
                s.altitude_min as "altitude_min",
                s.altitude_max as "altitude_max",
                nom5.cd_nomenclature as "exposition",
                h.nom_cite as "nom_cite",
                h.cd_hab as "cd_hab",
                h.technical_precision as "precision_technique"
            from
                pr_occhab.t_stations as s
            join pr_occhab.t_habitats h on
                h.id_station = s.id_station
            join gn_meta.t_datasets ds on
                ds.id_dataset = s.id_dataset
            left join pr_occhab.cor_station_observer cso on
                cso.id_station = s.id_station
            left join utilisateurs.t_roles r on
                r.id_role = cso.id_role
            left join ref_nomenclatures.t_nomenclatures nom1 on
                nom1.id_nomenclature = ds.id_nomenclature_data_origin
            left join ref_nomenclatures.t_nomenclatures nom2 on
                nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation
            left join ref_nomenclatures.t_nomenclatures nom3 on
                nom3.id_nomenclature = s.id_nomenclature_geographic_object
            left join ref_nomenclatures.t_nomenclatures nom4 on
                nom4.id_nomenclature = h.id_nomenclature_collection_technique
            left join ref_nomenclatures.t_nomenclatures nom5 on
                nom5.id_nomenclature = s.id_nomenclature_exposure
            group by
                s.id_station,
                s.id_dataset,
                ds.unique_dataset_id,
                nom2.cd_nomenclature ,
                h.technical_precision,
                h.cd_hab,
                h.nom_cite ,
                nom3.cd_nomenclature,
                h.unique_id_sinp_hab,
                nom5.cd_nomenclature
            ;
    """
    )
