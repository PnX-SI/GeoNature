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
  geom public.geometry NOT NULL,
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone
);

CREATE TABLE t_base_visits
(
  id_base_visit serial NOT NULL,
  id_base_site integer,
  id_digitiser integer,
  visit_date date NOT NULL,
  comments text,
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone
);

CREATE TABLE cor_visit_observer
(
  id_base_visit integer NOT NULL,
  id_role integer NOT NULL
);

CREATE TABLE cor_site_application (
  id_base_site integer NOT NULL,
  id_application integer NOT NULL
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

ALTER TABLE ONLY cor_site_application
    ADD CONSTRAINT pk_cor_site_application PRIMARY KEY (id_base_site, id_application);

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


ALTER TABLE ONLY cor_visit_observer
  ADD CONSTRAINT fk_cor_visit_observer_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_observer
  ADD CONSTRAINT fk_cor_visit_observer_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_site_application
  ADD CONSTRAINT fk_cor_site_application_id_base_site FOREIGN KEY (id_base_site) REFERENCES t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_site_application
  ADD CONSTRAINT fk_cor_site_application_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications (id_application);


ALTER TABLE ONLY cor_site_area
  ADD CONSTRAINT fk_cor_site_area_id_base_site FOREIGN KEY (id_base_site) REFERENCES t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_site_area
  ADD CONSTRAINT fk_cor_site_area_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area);


--------------
--CONSTRAINS--
--------------
ALTER TABLE t_base_sites
  ADD CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326));

ALTER TABLE t_base_sites
  ADD CONSTRAINT enforce_dims_geom CHECK ((public.st_ndims(geom) = 2));

ALTER TABLE t_base_sites
  ADD CONSTRAINT check_t_base_sites_type_site CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_site,116));


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
--Trigger permettant de fournir le geom du site à la visite s'il n'est pas rempli pour la visite.
CREATE OR REPLACE FUNCTION fct_trg_add_obs_geom()
  RETURNS trigger AS
$BODY$
begin
	if(NEW.geom is NULL and NEW.id_base_site IS NOT NULL) THEN
		NEW.geom = (select geom from gn_monitoring.t_base_sites WHERE id_base_site=NEW.id_base_site);
	end if;
	return NEW;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--@ TODO Trigger de calcul des intersections avec la table l_areas ????


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_base_sites
  BEFORE INSERT OR UPDATE
  ON t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_change_base_visits
  BEFORE INSERT OR UPDATE
  ON t_base_visits
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
