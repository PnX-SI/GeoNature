DROP VIEW IF EXISTS pr_occtax.v_releve_list;

CREATE OR REPLACE VIEW pr_occtax.v_releve_list AS 
 SELECT rel.id_releve_occtax,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.meta_device_entry,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    rel.observers_txt,
    dataset.dataset_name,
    string_agg(t.nom_valide::text, ','::text) AS taxons,
    (((string_agg(t.nom_valide::text, ','::text) || '<br/>'::text) || rel.date_min::date) || '<br/>'::text) || COALESCE(string_agg(DISTINCT (obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS leaflet_popup,
    COALESCE(string_agg(DISTINCT (obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS observateurs
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
     LEFT JOIN gn_meta.t_datasets dataset ON dataset.id_dataset = rel.id_dataset
  GROUP BY dataset.dataset_name, rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.meta_device_entry;



-- ajout cd_nom dans cor_area_synthese

ALTER TABLE ONLY gn_synthese.cor_area_synthese
ADD COLUMN cd_nom integer;

ALTER TABLE ONLY gn_synthese.cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese AS id_synthese,
        a.id_area AS id_area,
        s.cd_nom AS cd_nom
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s ON ST_INTERSECTS(s.the_geom_local, a.geom)
        WHERE s.id_synthese = NEW.id_synthese;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  UPDATE gn_synthese.cor_area_synthese cor
  SET cd_nom = (
     SELECT cd_nom FROM gn_synthese.synthese WHERE id_synthese = cor.id_synthese
  );


CREATE TABLE gn_synthese.cor_area_taxon AS 
   SELECT
   DISTINCT(cor.cd_nom) AS cd_nom,
   count(s.id_synthese) AS nb_obs, 
   cor.id_area AS id_area, 
   max(s.date_min) AS last_date, 
   gn_synthese.color_taxon(b.cd_nom, max(s.date_min)) AS color
   FROM gn_synthese.cor_area_synthese cor
   JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
   GROUP BY cor.cd_nom, a.id_area;

-- PK
ALTER TABLE gn_synthese.cor_area_taxon
  ADD CONSTRAINT pk_cor_area_taxon PRIMARY KEY (id_area, cd_nom);

-- FK
ALTER TABLE gn_synthese.cor_area_taxon
  ADD CONSTRAINT fk_cor_area_taxon_cd_nom FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE gn_synthese.cor_area_taxon
  ADD CONSTRAINT fk_cor_area_taxon_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;



CREATE OR REPLACE FUNCTION gn_synthese.calcul_cor_area_taxon(my_id_area integer, my_cd_nom integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
  -- on supprime cor_area_taxon et recree à chaque fois
  -- cela evite de regarder dans cor_area_taxon s'il y a deja une ligne, de faire un + 1  ou -1 sur nb_obs etc...
  DELETE FROM gn_synthese.cor_area_taxon WHERE cd_nom = my_cd_nom AND id_area = my_id_area;
-- puis on réinsert
-- on récupère la dernière date de l'obs dans l'aire concernée depuis cor_area_synthese et synthese
	INSERT INTO gn_synthese.cor_area_taxon (id_area, cd_nom, last_date, color, nb_obs)
	SELECT id_area, s.cd_nom,  max(s.date_min) AS last_date, gn_synthese.color_taxon(s.cd_nom, max(s.date_min)) AS color, count(s.id_synthese) AS nb_obs
	FROM gn_synthese.cor_area_synthese cor
  JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
	WHERE s.cd_nom = my_cd_nom
	AND id_area = my_id_area
  GROUP BY id_area, s.cd_nom
  ;
  END;
$$;



CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_maj_cor_unite_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF (TG_OP = 'INSERT') THEN
			PERFORM gn_synthese.calcul_cor_area_taxon(NEW.id_area, NEW.cd_nom);
		RETURN NULL;
  ELSEIF (TG_OP = 'DELETE') THEN
    PERFORM gn_synthese.calcul_cor_area_taxon(OLD.id_area, OLD.cd_nom);
    RETURN NULL;
	END IF;
END;
$$;


CREATE TRIGGER tri_maj_cor_area_taxon 
AFTER INSERT OR DELETE 
ON gn_synthese.cor_area_synthese 
FOR EACH ROW 
EXECUTE PROCEDURE gn_synthese.fct_trig_maj_cor_unite_taxon();