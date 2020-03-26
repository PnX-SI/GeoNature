SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--DROP SCHEMA suivi CASCADE;
CREATE SCHEMA gn_monitoring;

SET search_path = gn_monitoring, pg_catalog;
SET default_with_oids = false;

---------
--TABLE--
---------
CREATE TABLE t_base_sites
(
  id_base_site serial NOT NULL,
  id_inventor integer,
  id_digitiser integer,
  id_nomenclature_type_site integer NOT NULL,
  base_site_name character varying(255) NOT NULL,
  base_site_description text,
  base_site_code character varying(25) DEFAULT NULL::character varying,
  first_use_date date,
  geom public.geometry(Geometry,4326) NOT NULL,
  geom_local public.geometry(Geometry, :MYLOCALSRID),
  altitude_min integer,
  altitude_max integer,
  uuid_base_site UUID DEFAULT public.uuid_generate_v4(),
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone DEFAULT now()
);

CREATE TABLE t_base_visits
(
  id_base_visit serial NOT NULL,
  id_base_site integer,
  id_dataset integer NOT NULL,
  id_module INTEGER NOT NULL,
  id_digitiser integer,
  visit_date_min date NOT NULL,
  visit_date_max date,
  id_nomenclature_obs_technique integer DEFAULT ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),
  id_nomenclature_grp_typ integer DEFAULT ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'PASS'),
  comments text,
  uuid_base_visit UUID DEFAULT public.uuid_generate_v4(),
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone DEFAULT now()
);



CREATE TABLE cor_visit_observer
(
  id_base_visit integer NOT NULL,
  id_role integer NOT NULL
);

CREATE TABLE cor_site_module (
  id_base_site integer NOT NULL,
  id_module integer NOT NULL
);

CREATE TABLE cor_site_area (
  id_base_site integer NOT NULL,
  id_area integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_base_sites
    ADD CONSTRAINT pk_t_base_sites PRIMARY KEY (id_base_site);

ALTER TABLE ONLY t_base_visits
    ADD CONSTRAINT pk_t_base_visits PRIMARY KEY (id_base_visit);

ALTER TABLE ONLY cor_visit_observer
    ADD CONSTRAINT pk_cor_visit_observer PRIMARY KEY (id_base_visit, id_role);

ALTER TABLE ONLY cor_site_module
    ADD CONSTRAINT pk_cor_site_module PRIMARY KEY (id_base_site, id_module);

ALTER TABLE ONLY cor_site_area
    ADD CONSTRAINT pk_cor_site_area PRIMARY KEY (id_base_site, id_area);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_base_sites
  ADD CONSTRAINT  fk_t_base_sites_id_inventor FOREIGN KEY (id_inventor) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_base_sites
    ADD CONSTRAINT fk_t_base_sites_type_site FOREIGN KEY (id_nomenclature_type_site) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_base_sites
    ADD CONSTRAINT fk_t_base_sites_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY t_base_visits
  ADD CONSTRAINT  fk_t_base_visits_id_base_site FOREIGN KEY (id_base_site) REFERENCES t_base_sites (id_base_site) ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ONLY t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE gn_monitoring.t_base_visits ADD CONSTRAINT fk_t_base_visits_t_datasets FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_visit_observer
  ADD CONSTRAINT fk_cor_visit_observer_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_observer
  ADD CONSTRAINT fk_cor_visit_observer_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_site_module
  ADD CONSTRAINT fk_cor_site_module_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_site_module
  ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module);
ALTER TABLE ONLY cor_site_area
  ADD CONSTRAINT fk_cor_site_area_id_base_site FOREIGN KEY (id_base_site) REFERENCES t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_site_area
  ADD CONSTRAINT fk_cor_site_area_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area);

ALTER TABLE ONLY t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module) MATCH SIMPLE
            ON UPDATE CASCADE ON DELETE CASCADE;
--------------
--CONSTRAINS--
--------------
ALTER TABLE t_base_sites
  ADD CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326));

ALTER TABLE t_base_sites
  ADD CONSTRAINT enforce_dims_geom CHECK ((public.st_ndims(geom) = 2));

ALTER TABLE t_base_sites
  ADD CONSTRAINT check_t_base_sites_type_site CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_site,'TYPE_SITE')) NOT VALID;

ALTER TABLE t_base_visits
  ADD CONSTRAINT check_t_base_visits_id_nomenclature_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE t_base_visits
  ADD CONSTRAINT check_t_base_visits_id_nomenclature_grp_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;

---------
--INDEX--
---------
CREATE INDEX idx_t_base_visits_fk_bs_id ON t_base_visits USING btree(id_base_site);


CREATE INDEX idx_t_base_sites_geom ON t_base_sites USING gist (geom);

CREATE INDEX idx_t_base_sites_id_inventor ON t_base_sites USING btree (id_inventor);

CREATE INDEX idx_t_base_sites_type_site ON t_base_sites USING btree (id_nomenclature_type_site);


----------------------
--FUNCTIONS TRIGGERS--
----------------------
--@ TODO Trigger de calcul des intersections avec la table l_areas ????


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_log_changes
  AFTER INSERT OR UPDATE OR DELETE
  ON gn_monitoring.t_base_visits
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes
  AFTER INSERT OR UPDATE OR DELETE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_meta_dates_change_t_base_sites
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_change_t_base_visits
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_visits
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


CREATE FUNCTION fct_trg_cor_site_area()
  RETURNS trigger AS
$BODY$
BEGIN

	DELETE FROM gn_monitoring.cor_site_area WHERE id_base_site = NEW.id_base_site;
	INSERT INTO gn_monitoring.cor_site_area
	SELECT NEW.id_base_site, (ref_geo.fct_get_area_intersection(NEW.geom)).id_area;

  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER trg_cor_site_area
  AFTER INSERT OR UPDATE OF geom ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE gn_monitoring.fct_trg_cor_site_area();

CREATE TRIGGER tri_calculate_geom_local
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_geom_local('geom', 'geom_local');

CREATE TRIGGER tri_t_base_sites_calculate_alt
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_alt_minmax('geom');


------------
--TRIGGERS--
------------
INSERT INTO gn_commons.bib_tables_location(table_desc, schema_name, table_name, pk_field, uuid_field_name)
VALUES
('Table centralisant les sites faisant l''objet de protocole de suivis', 'gn_monitoring', 't_base_sites', 'id_base_site', 'uuid_base_site'),
('Table centralisant les visites réalisées sur un site', 'gn_monitoring', 't_base_visits', 'id_base_visit', 'uuid_base_visit');
