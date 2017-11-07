---Fonction récupération du label d'un item de la nomenclature

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_nomenclaturelibelle_byid(myid INTEGER, mylg CHAR(2))
  RETURNS CHARACTER VARYING(255) AS
$BODY$
DECLARE
	query TEXT;
	label CHARACTER VARYING(255);
BEGIN
	query := 'SELECT label_'|| mylg||' FROM ref_nomenclatures.t_nomenclatures WHERE id_nomenclature = ' || myid;
	EXECUTE query INTO label;
	RETURN label;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


--Vue représentant l'ensemble des observations du protocole contact pour la représentation du module carte liste
DROP VIEW IF EXISTS pr_contact.v_releve_contact;
CREATE OR REPLACE VIEW pr_contact.v_releve_contact AS
 SELECT rel.id_releve_contact,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.deleted,
    rel.meta_device_entry,
    rel.meta_create_date,
    rel.meta_update_date,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    occ.id_occurrence_contact,
    occ.cd_nom,
    occ.nom_cite,
    occ.deleted as occ_deleted,
    occ.meta_create_date as occ_meta_create_date,
    occ.meta_update_date as occ_meta_update_date,
    t.lb_nom,
    t.nom_valide,
    t.nom_vern,
    nom_complet_html || ' ' || date_min::date || '<br/>' || string_agg(obs.nom_role || ' ' || obs.prenom_role, ', ')as leaflet_popup,
    string_agg(obs.nom_role || ' ' || obs.prenom_role, ', ') as observateurs
   FROM pr_contact.t_releves_contact rel
   LEFT JOIN pr_contact.t_occurrences_contact occ  ON rel.id_releve_contact = occ.id_releve_contact
   LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
   LEFT JOIN  pr_contact.cor_role_releves_contact cor_role on cor_role.id_releve_contact = rel.id_releve_contact
   LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
   GROUP BY rel.id_releve_contact, id_dataset, id_digitiser, date_min, date_max,
       altitude_min, altitude_max, rel.deleted, meta_device_entry, rel.meta_create_date,
       rel.meta_update_date, rel.comment, geom_4326, "precision", t.cd_nom, nom_cite,
       id_occurrence_contact, occ_deleted, occ_meta_create_date, occ_meta_update_date, lb_nom,
       nom_valide, nom_complet_html, nom_vern;




--Vue représentant l'ensemble des relevés du protocole contact pour la représentation du module carte liste
CREATE OR REPLACE VIEW pr_contact.v_releve_list AS
SELECT rel.id_releve_contact,
   rel.id_dataset,
   rel.id_digitiser,
   rel.date_min,
   rel.date_max,
   rel.altitude_min,
   rel.altitude_max,
   rel.deleted,
   rel.meta_device_entry,
   rel.meta_create_date,
   rel.meta_update_date,
   rel.comment,
   rel.geom_4326,
   rel."precision",
   string_agg(nom_valide, ',') AS taxons,
   string_agg(nom_valide, ',') || '<br/>' || rel.date_min::date || '<br/>' || string_agg(obs.nom_role || ' ' || obs.prenom_role, ', ') AS leaflet_popup,
   string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS observateurs
  FROM pr_contact.t_releves_contact rel
    LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
    LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
    LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
    LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
 GROUP BY rel.id_releve_contact, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.deleted,
  rel.meta_device_entry, rel.meta_create_date, rel.meta_update_date, rel.comment, rel.geom_4326, rel."precision";


-- fonction retournant le cd_nomenclature à partir de l'id_type de la nomenclature et de l'id_nomenclature
-- utilisé pour la vue des exports SINP
CREATE OR REPLACE FUNCTION ref_nomenclatures.get_cd_nomenclature(
    p_id_type integer,
    p_id_nomenclature integer)
  RETURNS character varying AS
$BODY$
--Function which return the cd_nomenclature from an id_type and an id_nomenclature
DECLARE ref character varying;
  BEGIN
SELECT INTO ref cd_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE p_id_type = n.id_type AND p_id_nomenclature = n.id_nomenclature;
return ref;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


-- ADD column hour_min hour_max

ALTER TABLE pr_contact.t_releves_contact
ADD COLUMN hour_min time;
ALTER TABLE pr_contact.t_releves_contact
ADD COLUMN hour_max time;


CREATE OR REPLACE VIEW pr_contact.v_releve_contact AS 
 SELECT rel.id_releve_contact,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.deleted,
    rel.meta_device_entry,
    rel.meta_create_date,
    rel.meta_update_date,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    occ.id_occurrence_contact,
    occ.cd_nom,
    occ.nom_cite,
    occ.deleted AS occ_deleted,
    occ.meta_create_date AS occ_meta_create_date,
    occ.meta_update_date AS occ_meta_update_date,
    t.lb_nom,
    t.nom_valide,
    t.nom_vern,
    (((t.nom_complet_html::text || ' '::text) || rel.date_min::date) || '<br/>'::text) || string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
    COALESCE ( string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text),rel.observers_txt) AS observateurs
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
  GROUP BY rel.id_releve_contact, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.deleted, rel.meta_device_entry, rel.meta_create_date, rel.meta_update_date, rel.comment, rel.geom_4326, rel."precision", t.cd_nom, occ.nom_cite, occ.id_occurrence_contact, occ.deleted, occ.meta_create_date, occ.meta_update_date, t.lb_nom, t.nom_valide, t.nom_complet_html, t.nom_vern;


CREATE OR REPLACE VIEW pr_contact.v_releve_list AS 
 SELECT rel.id_releve_contact,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.deleted,
    rel.meta_device_entry,
    rel.meta_create_date,
    rel.meta_update_date,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    string_agg(t.nom_valide::text, ','::text) AS taxons,
    (((string_agg(t.nom_valide::text, ','::text) || '<br/>'::text) || rel.date_min::date) || '<br/>'::text) || string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
    COALESCE(string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt) AS observateurs
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
  GROUP BY rel.id_releve_contact, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.deleted, rel.meta_device_entry, rel.meta_create_date, rel.meta_update_date, rel.comment, rel.geom_4326, rel."precision";



CREATE OR REPLACE FUNCTION ref_nomenclatures.get_cd_nomenclature(
    myidnomenclature integer)
  RETURNS character varying AS
$BODY$
--Function which return the cd_nomenclature from an id_type and an id_nomenclature
DECLARE thecdnomenclature character varying;
  BEGIN
SELECT INTO thecdnomenclature cd_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE myidnomenclature = n.id_nomenclature;
return thecdnomenclature;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_id_nomenclature(
    myidtype integer,
    mycdnomenclature character varying)
  RETURNS character varying AS
$BODY$
--Function which return the cd_nomenclature from an id_type and an id_nomenclature
DECLARE theidnomenclature character varying;
  BEGIN
SELECT INTO theidnomenclature id_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE myidtype = n.id_type AND mycdnomenclature = n.cd_nomenclature;
return theidnomenclature;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_nomenclature_label(
    myidnomenclature integer,
    mylanguage character varying)
  RETURNS character varying AS
$BODY$
--Function which return the label from the id_nomenclature and the language
DECLARE 
	labelfield character varying;
	thelabel character varying;
  BEGIN
	 IF myidnomenclature IS NULL
	 THEN
	 return NULL;
	 END IF;
	 labelfield = 'label_'||mylanguage;
	  EXECUTE format( ' SELECT  %s
	  FROM ref_nomenclatures.t_nomenclatures n
	  WHERE id_nomenclature = %s',labelfield, myidnomenclature  )INTO thelabel;
	return thelabel;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;