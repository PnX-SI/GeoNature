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


-- pas d'action sur delete entre synthese et cor_area_synthese
ALTER TABLE ONLY gn_synthese.cor_area_synthese
    DROP CONSTRAINT fk_cor_area_synthese_id_synthese,
    ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese) ON DELETE NO ACTION;


CREATE OR REPLACE FUNCTION gn_synthese.color_taxon(cd_nom integer, maxdateobs timestamp) RETURNS text
    LANGUAGE plpgsql
    AS $$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  color text;
  BEGIN
	IF (date_part('day', (now() - maxdateobs))) < 365  THEN color = 'gray';
	ELSE color = 'red';
	END IF;
	return color;
  END;
$$;

CREATE TABLE gn_synthese.cor_area_taxon (
  cd_nom integer NOT NULL,
  id_area integer NOT NULL, 
  nb_obs integer NOT NULL, 
  last_date timestamp without time zone NOT NULL, 
  color character varying(20) NOT NULL
);

INSERT INTO gn_synthese.cor_area_taxon (cd_nom, id_area, nb_obs, last_date, color)
   SELECT
   DISTINCT(s.cd_nom) AS cd_nom,
   count(s.id_synthese) AS nb_obs, 
   cor.id_area AS id_area, 
   max(s.date_min) AS last_date, 
   gn_synthese.color_taxon(s.cd_nom, max(s.date_min)) AS color
   FROM gn_synthese.cor_area_synthese cor
   JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
   GROUP BY s.cd_nom, cor.id_area;

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


-- trigger insertion ou update sur cor_area_syntese - déclenché après insert ou update sur cor_area_synthese
CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_maj_cor_unite_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE the_cd_nom integer;
BEGIN
    SELECT cd_nom INTO the_cd_nom FROM gn_synthese.synthese WHERE id_synthese = NEW.id_synthese;
  -- on supprime cor_area_taxon et recree à chaque fois
    -- cela evite de regarder dans cor_area_taxon s'il y a deja une ligne, de faire un + 1  ou -1 sur nb_obs etc...
    IF (TG_OP = 'INSERT') THEN
      DELETE FROM gn_synthese.cor_area_taxon WHERE cd_nom = the_cd_nom AND id_area IN (NEW.id_area);
    ELSE
      DELETE FROM gn_synthese.cor_area_taxon WHERE cd_nom = the_cd_nom AND id_area IN (NEW.id_area, OLD.id_area);
    END IF;
    -- puis on réinsert
    -- on récupère la dernière date de l'obs dans l'aire concernée depuis cor_area_synthese et synthese
    INSERT INTO gn_synthese.cor_area_taxon (id_area, cd_nom, last_date, color, nb_obs)
    SELECT id_area, s.cd_nom,  max(s.date_min) AS last_date, gn_synthese.color_taxon(s.cd_nom, max(s.date_min)) AS color, count(s.id_synthese) AS nb_obs
    FROM gn_synthese.cor_area_synthese cor
    JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
    WHERE s.cd_nom = the_cd_nom AND id_area = NEW.id_area
    GROUP BY id_area, s.cd_nom;
    RETURN NULL;
END;
$$;


CREATE TRIGGER tri_maj_cor_area_taxon 
AFTER INSERT OR UPDATE 
ON gn_synthese.cor_area_synthese 
FOR EACH ROW 
EXECUTE PROCEDURE gn_synthese.fct_tri_maj_cor_unite_taxon();

-- trigger de suppression à partir de la synthese
-- suppression dans cor_area_taxon
-- recalcule des aires
-- suppression dans cor_area_synthese
-- déclenché en BEFORE DELETE
CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_manage_area_synth_and_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    the_id_areas int[];
BEGIN 
   -- on récupère tous les aires intersectées par l'id_synthese concerné
    SELECT array_agg(id_area) INTO the_id_areas
    FROM gn_synthese.cor_area_synthese
    WHERE id_synthese = OLD.id_synthese;
    -- DELETE AND INSERT sur cor_area_taxon: evite de faire un count sur nb_obs
    DELETE FROM gn_synthese.cor_area_taxon WHERE cd_nom = OLD.cd_nom AND id_area = ANY (the_id_areas);
    -- on réinsert dans cor_area_synthese en recalculant les max, nb_obs et couleur pour chaque aire
    INSERT INTO gn_synthese.cor_area_taxon (cd_nom, nb_obs, id_area, last_date, color)
    SELECT s.cd_nom, count(s.id_synthese), cor.id_area,  max(s.date_min), gn_synthese.color_taxon(s.cd_nom, max(s.date_min))  
    FROM gn_synthese.cor_area_synthese cor
    JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
    -- on ne prend pas l'OLD.synthese car c'est un trigger BEFORE DELETE
    WHERE id_area = ANY (the_id_areas) AND s.cd_nom = OLD.cd_nom AND s.id_synthese != OLD.id_synthese
    GROUP BY cor.id_area, s.cd_nom;
    -- suppression dans cor_area_synthese si tg_op = DELETE
    DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = OLD.id_synthese;
    RETURN OLD;
END;
$$;


CREATE OR REPLACE FUNCTION gn_synthese.delete_and_insert_area_taxon(my_cd_nom integer, my_id_area integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN 
  -- supprime dans cor_area_taxon
  DELETE FROM gn_synthese.cor_area_taxon WHERE cd_nom = my_cd_nom AND id_area = ANY (my_id_area);
  -- réinsertion et calcul
  INSERT INTO gn_synthese.cor_area_taxon (cd_nom, nb_obs, id_area, last_date, color)
  SELECT s.cd_nom, count(s.id_synthese), cor.id_area,  max(s.date_min), gn_synthese.color_taxon(s.cd_nom, max(s.date_min))  
  FROM gn_synthese.cor_area_synthese cor
  JOIN gn_synthese.synthese s ON s.id_synthese = cor.id_synthese
  WHERE id_area = ANY (my_id_area) AND s.cd_nom = my_cd_nom
  GROUP BY cor.id_area, s.cd_nom;
END;
$$;


CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_update_cd_nom() RETURNS trigger
    LANGUAGE plpgsql
  AS $$
DECLARE
    the_id_areas int[];
BEGIN 
   -- on récupère tous les aires intersectées par l'id_synthese concerné
    SELECT array_agg(id_area) INTO the_id_areas
    FROM gn_synthese.cor_area_synthese
    WHERE id_synthese = OLD.id_synthese;

    -- recalcul pour l'ancien taxon
    PERFORM(gn_synthese.delete_and_insert_area_taxon(OLD.cd_nom, the_id_areas));
    -- recalcul pour le nouveau taxon
    PERFORM(gn_synthese.delete_and_insert_area_taxon(NEW.cd_nom, the_id_areas));
    
  RETURN OLD;
END;
$$;


-- trigger suppression dans la synthese
CREATE TRIGGER tri_del_area_synt_maj_corarea_tax
  BEFORE DELETE
  ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_tri_manage_area_synth_and_taxon();

-- trigger update cd_nom dans la synthese
CREATE TRIGGER tri_update_cor_area_taxon_update_cd_nom
  AFTER UPDATE OF cd_nom
  ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_tri_update_cd_nom();