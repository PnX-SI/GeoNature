
\restrict QjC6ACYnoiU5hHiwOVs92ohICwdsfQw37MrKHVTItXjtl7hUT5Ym3tPty4XXHGH

CREATE VIEW gn_synthese.v_metadata_for_export AS
 WITH count_nb_obs AS (
         SELECT count(*) AS nb_obs,
            synthese.id_dataset
           FROM gn_synthese.synthese
          GROUP BY synthese.id_dataset
        )
 SELECT d.dataset_name AS jeu_donnees,
    d.id_dataset AS jdd_id,
    d.unique_dataset_id AS jdd_uuid,
    af.acquisition_framework_name AS cadre_acquisition,
    af.unique_acquisition_framework_id AS ca_uuid,
    string_agg(DISTINCT concat(COALESCE(orga.nom_organisme, ((((roles.nom_role)::text || ' '::text) || (roles.prenom_role)::text))::character varying), ' (', nomencl.label_default, ')'), ', '::text) AS acteurs,
    count_nb_obs.nb_obs AS nombre_obs
   FROM ((((((gn_meta.t_datasets d
     JOIN gn_meta.t_acquisition_frameworks af ON ((af.id_acquisition_framework = d.id_acquisition_framework)))
     LEFT JOIN gn_meta.cor_dataset_actor act ON ((act.id_dataset = d.id_dataset)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nomencl ON ((nomencl.id_nomenclature = act.id_nomenclature_actor_role)))
     LEFT JOIN utilisateurs.bib_organismes orga ON ((orga.id_organisme = act.id_organism)))
     LEFT JOIN utilisateurs.t_roles roles ON ((roles.id_role = act.id_role)))
     JOIN count_nb_obs ON ((count_nb_obs.id_dataset = d.id_dataset)))
  GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, af.unique_acquisition_framework_id, count_nb_obs.nb_obs;

\unrestrict QjC6ACYnoiU5hHiwOVs92ohICwdsfQw37MrKHVTItXjtl7hUT5Ym3tPty4XXHGH

