-- recréation de vue lié à la suppression de bib_noms

DROP VIEW gn_synthese.v_tree_taxons_synthese;
CREATE OR REPLACE VIEW gn_synthese.v_tree_taxons_synthese AS
WITH 
  cd_synthese AS(
    SELECT DISTINCT cd_nom FROM gn_synthese.synthese
  )
	,taxon AS (
    SELECT
      t_1.cd_ref,
      t_1.lb_nom AS nom_latin,
      t_1.nom_vern AS nom_francais,
      t_1.cd_nom,
      t_1.id_rang,
      t_1.regne,
      t_1.phylum,
      t_1.classe,
      t_1.ordre,
      t_1.famille,
      t_1.lb_nom
    FROM taxonomie.taxref t_1
    JOIN cd_synthese s ON s.cd_nom = t_1.cd_nom
  )
  ,cd_regne AS (
    SELECT DISTINCT taxref.cd_nom,
      taxref.regne
    FROM taxonomie.taxref
    WHERE taxref.id_rang::text = 'KD'::text 
    AND taxref.cd_nom = taxref.cd_ref
  )
SELECT
  t.cd_ref,
  t.nom_latin,
  t.nom_francais,
  t.id_regne,
  t.nom_regne,
  COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
  COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref') AS nom_embranchement,
  COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
  COALESCE(t.nom_classe, ' Sans classe dans taxref') AS nom_classe,
  COALESCE(t.desc_classe, ' Sans classe dans taxref') AS desc_classe,
  COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
  COALESCE(t.nom_ordre, ' Sans ordre dans taxref') AS nom_ordre,
  COALESCE(t.id_famille, t.id_ordre) AS id_famille,
  COALESCE(t.nom_famille, ' Sans famille dans taxref') AS nom_famille
FROM ( 
  SELECT DISTINCT
    t_1.cd_ref,
    t_1.nom_latin,
    t_1.nom_francais,
    ( SELECT DISTINCT r.cd_nom
      FROM cd_regne r
      WHERE r.regne = t_1.regne
    ) AS id_regne,
    t_1.regne AS nom_regne,
    ph.cd_nom AS id_embranchement,
    t_1.phylum AS nom_embranchement,
    t_1.phylum AS desc_embranchement,
    cl.cd_nom AS id_classe,
    t_1.classe AS nom_classe,
    t_1.classe AS desc_classe,
    ord.cd_nom AS id_ordre,
    t_1.ordre AS nom_ordre,
    f.cd_nom AS id_famille,
    t_1.famille AS nom_famille
  FROM taxon t_1
  LEFT JOIN taxonomie.taxref ph ON ph.id_rang = 'PH' AND ph.cd_nom = ph.cd_ref AND ph.lb_nom = t_1.phylum AND NOT t_1.phylum IS NULL
  LEFT JOIN taxonomie.taxref cl ON cl.id_rang = 'CL' AND cl.cd_nom = cl.cd_ref AND cl.lb_nom = t_1.classe AND NOT t_1.classe IS NULL
  LEFT JOIN taxonomie.taxref ord ON ord.id_rang = 'OR' AND ord.cd_nom = ord.cd_ref AND ord.lb_nom = t_1.ordre AND NOT t_1.ordre IS NULL
  LEFT JOIN taxonomie.taxref f ON f.id_rang = 'FM' AND f.cd_nom = f.cd_ref AND f.lb_nom = t_1.famille AND f.phylum = t_1.phylum AND NOT t_1.famille IS NULL
) t
ORDER BY id_regne, id_embranchement, id_classe, id_ordre, id_famille;



-- Add column 'module_doc_url' on t_modules tables

ALTER TABLE gn_commons.t_modules ADD COLUMN module_doc_url character varying(255);

UPDATE gn_commons.t_modules 
SET module_doc_url = 'https://geonature.readthedocs.io/fr/latest/user-manual.html';

UPDATE gn_commons.t_modules 
SET module_doc_url = 'https://geonature.readthedocs.io/fr/latest/user-manual.html#occtax'
WHERE module_code ILIKE 'OCCTAX';


UPDATE gn_commons.t_modules 
SET module_doc_url = 'https://geonature.readthedocs.io/fr/latest/user-manual.html#admin'
WHERE module_code ILIKE 'ADMIN';

-- Migration du metadata comme un module à part

INSERT INTO gn_commons.t_modules(module_code, module_label, module_picto, module_desc, module_path, module_target, active_frontend, active_backend, module_doc_url) VALUES
('METADATA', 'Metadonnées', 'fa-book', 'Module de gestion des métadonnées', 'metadata', '_self', TRUE, TRUE, 'https://geonature.readthedocs.io/fr/latest/user-manual.html#metadonnees')
;

-- migration des permission dans le nouveau module
INSERT INTO gn_permissions.cor_role_action_filter_module_object(
  id_role,
  id_action,
  id_filter,
  id_module
)
WITH mod_admin AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'ADMIN'
),
obj AS (
    SELECT id_object
    FROM gn_permissions.t_objects
    WHERE code_object ILIKE 'METADATA'
),
mod_metadata AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'METADATA' 
)
SELECT id_role, id_action, id_filter, mod_metadata.id_module
FROM gn_permissions.cor_role_action_filter_module_object cor, mod_admin, obj, mod_metadata
WHERE cor.id_module = mod_admin.id_module AND cor.id_object = obj.id_object;

-- suppression des permissions de l'objet metadata inutiles
DELETE 
FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
) AND id_module = (
    SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'ADMIN'
);


-- suppression relation cor_object_module 
DELETE FROM gn_permissions.cor_object_module WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
);

-- supression de l'objet metadata
DELETE FROM gn_permissions.t_objects where code_object = 'METADATA';

DO $$
BEGIN
    -- Droit limité pour le groupe en poste pour le module METADATA
    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 1, 1, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 2, 3, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 3, 1, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 4, 1, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 5, 3, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

    INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
    SELECT 7, 6, 1, id_module
    FROM gn_commons.t_modules
    WHERE module_code = 'METADATA';

  EXCEPTION WHEN OTHERS THEN

      RAISE NOTICE 'Permissions déjà existante';
  END;
$$;


-- Update taxons_synthese_autocomplete


DROP TABLE gn_synthese.taxons_synthese_autocomplete;

CREATE TABLE gn_synthese.taxons_synthese_autocomplete AS
SELECT t.cd_nom,
  t.cd_ref,
  t.search_name,
  t.nom_valide,
  t.lb_nom,
  t.regne,
  t.group2_inpn
FROM (
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_nom , ']' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1

  UNION
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.nom_vern, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_nom , ']' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  WHERE t_1.nom_vern IS NOT NULL AND t_1.cd_nom = t_1.cd_ref
) t
  WHERE t.cd_nom IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese);

  COMMENT ON TABLE gn_synthese.taxons_synthese_autocomplete
     IS 'Table construite à partir d''une requete sur la base et mise à jour via le trigger trg_refresh_taxons_forautocomplete de la table gn_synthese';

CREATE OR REPLACE FUNCTION gn_synthese.fct_trg_refresh_taxons_forautocomplete()
  RETURNS trigger AS
$BODY$
 DECLARE
  BEGIN

    IF TG_OP in ('DELETE', 'TRUNCATE', 'UPDATE') AND OLD.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese) THEN
        DELETE FROM gn_synthese.taxons_synthese_autocomplete auto
        WHERE auto.cd_nom = OLD.cd_nom;
    END IF;

    IF TG_OP in ('INSERT', 'UPDATE') AND NEW.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.taxons_synthese_autocomplete) THEN
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
              t.cd_ref,
          concat(t.lb_nom, ' = <i>', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']') AS search_name,
          t.nom_valide,
          t.lb_nom,
          t.regne,
          t.group2_inpn
      FROM taxonomie.taxref t  WHERE cd_nom = NEW.cd_nom;
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
        t.cd_ref,
        concat(t.nom_vern, ' =  <i> ', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']' ) AS search_name,
        t.nom_valide,
        t.lb_nom,
        t.regne,
        t.group2_inpn
      FROM taxonomie.taxref t  WHERE t.nom_vern IS NOT NULL AND cd_nom = NEW.cd_nom;
    END IF;
  RETURN NULL;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- DELETE cascade sur ref_geo
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;

ALTER TABLE ref_geo.li_municipalities
  ADD CONSTRAINT fk_li_municipalities_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;

ALTER TABLE ref_geo.li_grids
  ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;


-- Contrainte unique sur UUID en synthese et occtax

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT unique_id_sinp_unique UNIQUE (unique_id_sinp);

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT unique_id_sinp_occtax_unique UNIQUE (unique_id_sinp_occtax);



-- suppression de la nomenclature par défault validation inutilisée dans occtax
DELETE FROM pr_occtax.defaults_nomenclatures_value
WHERE mnemonique_type = 'STATUT_VALID';



-- Création d'un vue lastest validation

CREATE VIEW gn_commons.v_lastest_validation AS (
  SELECT val.*, nom.label_default
   FROM gn_commons.t_validations val
   JOIN ref_nomenclatures.t_nomenclatures nom ON nom.id_nomenclature = val.id_nomenclature_valid_status
JOIN ( SELECT val_max.uuid_attached_row,
            max(val_max.validation_date) AS max
           FROM gn_commons.t_validations val_max
          GROUP BY val_max.uuid_attached_row) v2 ON val.validation_date = v2.max AND v2.uuid_attached_row = val.uuid_attached_row

);


-- ajout de 2 champs commentaires dans la synthese

ALTER TABLE gn_synthese.synthese ADD COLUMN comment_context text;
ALTER TABLE gn_synthese.synthese ADD COLUMN comment_description text;

COMMENT ON COLUMN gn_synthese.synthese.comment_context
  IS 'Commentaire du releve (ou regroupement)';
COMMENT ON COLUMN gn_synthese.synthese.comment_description
  IS 'Commentaire de l''occurrence';

-- migration de l'ancien champs comments dans les nouveaux
UPDATE gn_synthese.synthese
SET comment_context = split_part(comments, '/', 1);

UPDATE gn_synthese.synthese
SET comment_description = split_part(comments, '/', 2);


ALTER TABLE gn_synthese.synthese DROP COLUMN comments CASCADE;


-- Recréation et adaptation des vues suite au drop cascade comments
-- ajout acteur + x_centroid et y_centroid + date_update
-- on n'utilise plus la vue v_decoded_nomenclature pour des questions de perfs
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS 
 WITH deco AS (
         SELECT s_1.id_synthese,
            n1.label_default AS "ObjGeoTyp",
            n2.label_default AS "methGrp",
            n3.label_default AS "obsMeth",
            n4.label_default AS "obsTech",
            n5.label_default AS "ocEtatBio",
            n6.label_default AS "ocStatBio",
            n7.label_default AS "ocNat",
            n8.label_default AS "preuveOui",
            n9.label_default AS "difNivPrec",
            n10.label_default AS "ocStade",
            n11.label_default AS "ocSex",
            n12.label_default AS "objDenbr",
            n13.label_default AS "denbrTyp",
            n14.label_default AS "sensiNiv",
            n15.label_default AS "statObs",
            n16.label_default AS "dEEFlou",
            n17.label_default AS "statSource",
            n18.label_default AS "typInfGeo",
            n19.label_default AS "ocMethDet"
           FROM gn_synthese.synthese s_1
            LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s_1.id_nomenclature_geo_object_nature = n1.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s_1.id_nomenclature_grp_typ = n2.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s_1.id_nomenclature_obs_meth = n3.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n4 ON s_1.id_nomenclature_obs_technique = n4.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s_1.id_nomenclature_bio_status = n5.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s_1.id_nomenclature_bio_condition = n6.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s_1.id_nomenclature_naturalness = n7.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s_1.id_nomenclature_exist_proof = n8.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s_1.id_nomenclature_diffusion_level = n9.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s_1.id_nomenclature_life_stage = n10.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s_1.id_nomenclature_sex = n11.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s_1.id_nomenclature_obj_count = n12.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s_1.id_nomenclature_type_count = n13.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s_1.id_nomenclature_sensitivity = n14.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s_1.id_nomenclature_observation_status = n15.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s_1.id_nomenclature_blurring = n16.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s_1.id_nomenclature_source_status = n17.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s_1.id_nomenclature_info_geo_type = n18.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s_1.id_nomenclature_determination_method = n19.id_nomenclature
        )
 SELECT s.id_synthese AS "idSynthese",
    s.unique_id_sinp AS "permId",
    s.unique_id_sinp_grp AS "permIdGrp",
    s.count_min AS "denbrMin",
    s.count_max AS "denbrMax",
    s.meta_v_taxref AS "vTAXREF",
    s.sample_number_proof AS "sampleNumb",
    s.digital_proof AS "preuvNum",
    s.non_digital_proof AS "preuvNoNum",
    s.altitude_min AS "altMin",
    s.altitude_max AS "altMax",
    st_astext(s.the_geom_4326) AS wkt,
    s.date_min AS "dateDebut",
    s.date_max AS "dateFin",
    s.validator AS validateur,
    s.observers AS observer,
    s.id_digitiser AS id_digitiser,
    s.determiner AS detminer,
    s.comment_context AS "obsCtx",
    s.comment_description AS "obsDescr",
    s.meta_create_date,
    s.meta_update_date,
    d.id_dataset AS "jddId",
    d.dataset_name AS "jddCode",
    d.id_acquisition_framework,
    t.cd_nom AS "cdNom",
    t.cd_ref AS "cdRef",
    s.nom_cite AS "nomCite",
    st_x(st_transform(s.the_geom_point, 2154)) AS x_centroid,
    st_y(st_transform(s.the_geom_point, 2154)) AS y_centroid,
    COALESCE(s.meta_update_date, s.meta_create_date) AS lastact,
    st_asgeojson(s.the_geom_4326) AS geojson_4326,
    st_asgeojson(s.the_geom_local) AS geojson_local,
    deco."ObjGeoTyp",
    deco."methGrp",
    deco."obsMeth",
    deco."obsTech",
    deco."ocEtatBio",
    deco."ocNat",
    deco."preuveOui",
    deco."difNivPrec",
    deco."ocStade",
    deco."ocSex",
    deco."objDenbr",
    deco."denbrTyp",
    deco."sensiNiv",
    deco."statObs",
    deco."dEEFlou",
    deco."statSource",
    deco."typInfGeo"
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     JOIN deco ON deco.id_synthese = s.id_synthese;





CREATE OR REPLACE VIEW gn_synthese.v_metadata_for_export AS 
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
    string_agg(DISTINCT concat(COALESCE(orga.nom_organisme, ((roles.nom_role::text || ' '::text) || roles.prenom_role::text)::character varying), ': ', nomencl.label_default), ' | '::text) AS acteurs,
    count_nb_obs.nb_obs AS nombre_obs
   FROM gn_meta.t_datasets d
     JOIN gn_meta.t_acquisition_frameworks af ON af.id_acquisition_framework = d.id_acquisition_framework
     JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d.id_dataset
     JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
     LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
     LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
     JOIN count_nb_obs ON count_nb_obs.id_dataset = d.id_dataset
  GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, count_nb_obs.nb_obs;



CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app AS 
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
    s.the_geom_4326,
    st_asgeojson(the_geom_4326),
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
    s.id_nomenclature_obs_meth,
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
    sources.name_source,
    sources.url_source,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;



-- MAJ des triggers occtax lié à la modif du champ commentaire
-- Fonction utilisée pour les triggers vers synthese
-- suppression de la récupération de la validation lors du trigger occtax -> synthese
-- redondant car déjà effectué par occtax via l'ecriture dans t_validation puis par le trigger validation -> synthese 
-- ecrivant le dernier statut de valiation
CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
$BODY$
DECLARE
new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
id_module integer;
id_nomenclature_source_status integer;
myobservers RECORD;
id_role_loop integer;

BEGIN
--recupération du counting à partir de son ID
SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;

-- Récupération de l'occurrence
SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

-- Récupération du relevé
SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

-- Récupération de la source
SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';

-- Récupération de l'id_module
SELECT INTO id_module gn_commons.get_id_module_bycode('OCCTAX');


-- Récupération du status_source depuis le JDD
SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

--Récupération et formatage des observateurs
SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
WHERE cor.id_releve_occtax = releve.id_releve_occtax;

-- insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
id_module,
id_nomenclature_geo_object_nature,
id_nomenclature_grp_typ,
id_nomenclature_obs_meth,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_exist_proof,
id_nomenclature_diffusion_level,
id_nomenclature_life_stage,
id_nomenclature_sex,
id_nomenclature_obj_count,
id_nomenclature_type_count,
id_nomenclature_observation_status,
id_nomenclature_blurring,
id_nomenclature_source_status,
id_nomenclature_info_geo_type,
count_min,
count_max,
cd_nom,
nom_cite,
meta_v_taxref,
sample_number_proof,
digital_proof,
non_digital_proof,
altitude_min,
altitude_max,
the_geom_4326,
the_geom_point,
the_geom_local,
date_min,
date_max,
observers,
determiner,
id_digitiser,
id_nomenclature_determination_method,
comment_context,
comment_description,
last_action
)
VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  id_module,
  --nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
  occurrence.id_nomenclature_diffusion_level,
  new_count.id_nomenclature_life_stage,
  new_count.id_nomenclature_sex,
  new_count.id_nomenclature_obj_count,
  new_count.id_nomenclature_type_count,
  occurrence.id_nomenclature_observation_status,
  occurrence.id_nomenclature_blurring,
  -- status_source récupéré depuis le JDD
  id_nomenclature_source_status,
  -- id_nomenclature_info_geo_type: type de rattachement = géoréferencement
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')	,
  new_count.count_min,
  new_count.count_max,
  occurrence.cd_nom,
  occurrence.nom_cite,
  occurrence.meta_v_taxref,
  occurrence.sample_number_proof,
  occurrence.digital_proof,
  occurrence.non_digital_proof,
  releve.altitude_min,
  releve.altitude_max,
  releve.geom_4326,
  ST_CENTROID(releve.geom_4326),
  releve.geom_local,
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  COALESCE (myobservers.observers_name, releve.observers_txt),
  occurrence.determiner,
  releve.id_digitiser,
  occurrence.id_nomenclature_determination_method,
  releve.comment,
  occurrence.comment,
  'I'
);

  RETURN myobservers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
  UPDATE gn_synthese.synthese SET
    id_nomenclature_obs_meth = NEW.id_nomenclature_obs_meth,
    id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
    id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
    id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
    id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
    id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
    id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
    id_nomenclature_blurring = NEW.id_nomenclature_blurring,
    id_nomenclature_source_status = NEW.id_nomenclature_source_status,
    determiner = NEW.determiner,
    id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
    cd_nom = NEW.cd_nom,
    nom_cite = NEW.nom_cite,
    meta_v_taxref = NEW.meta_v_taxref,
    sample_number_proof = NEW.sample_number_proof,
    digital_proof = NEW.digital_proof,
    non_digital_proof = NEW.non_digital_proof,
    comment_description = NEW.comment,
    last_action = 'U'
  WHERE unique_id_sinp IN (SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax);
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- UPDATE Releve
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
  RETURNS trigger AS
$BODY$
DECLARE
  myobservers text;
BEGIN
  --calcul de l'observateur. On privilégie le ou les observateur(s) de cor_role_releves_occtax
  --Récupération et formatage des observateurs
  SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ')
  FROM pr_occtax.cor_role_releves_occtax cor
  JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
  WHERE cor.id_releve_occtax = NEW.id_releve_occtax;
  IF myobservers IS NULL THEN
    myobservers = NEW.observers_txt;
  END IF;
  --mise à jour en synthese des informations correspondant au relevé uniquement
  UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = myobservers,
      id_digitiser = NEW.id_digitiser,
      id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = (to_char(NEW.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
      date_max = (to_char(NEW.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp, 
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326),
      last_action = 'U',
      comment_context = NEW.comment
  WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Modification de a contrainte sur count_min et max pour permettre l'occurrence d'absence

ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_count_min;

ALTER TABLE pr_occtax.cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_count_min CHECK (count_min >= 0);


ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_count_max;

ALTER TABLE pr_occtax.cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_count_max CHECK (count_max >= count_min AND count_max >= 0);


-- suppression de la valeur par défault pour la sensibilité
DELETE FROM gn_synthese.defaults_nomenclatures_value
WHERE mnemonique_type = 'SENSIBILITE';
