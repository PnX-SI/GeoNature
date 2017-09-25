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
