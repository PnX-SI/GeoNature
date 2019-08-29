CREATE SCHEMA hist_bryophytes;


SET default_tablespace = '';
SET default_with_oids = false;

----------
--TABLES--
----------
CREATE TABLE hist_bryophytes.bib_supports
(
  id_support integer NOT NULL,
  nom_support character varying(20) NOT NULL
);

CREATE TABLE hist_bryophytes.bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);

CREATE TABLE hist_bryophytes.bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);

CREATE TABLE hist_bryophytes.cor_bryo_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);

CREATE SEQUENCE hist_bryophytes.cor_bryo_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE hist_bryophytes.cor_bryo_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    id_abondance character(1),
    taxon_saisi character varying(255),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('hist_bryophytes.cor_bryo_taxon_gid_seq'::regclass) NOT NULL,
    diffusable boolean DEFAULT true
);
CREATE SEQUENCE hist_bryophytes.cor_bryo_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE hist_bryophytes.cor_bryo_taxon_id_station_cd_nom_seq OWNED BY hist_bryophytes.cor_bryo_taxon.id_station_cd_nom;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('hist_bryophytes.cor_bryo_taxon_id_station_cd_nom_seq'::regclass);

CREATE TABLE hist_bryophytes.t_stations_bryo (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    dateobs date,
    info_acces character varying(255),
    surface integer DEFAULT 1,
    complet_partiel character(1),
    altitude_saisie integer DEFAULT 0,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    remarques text,
    pdop real DEFAULT 0,
    supprime boolean DEFAULT false,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    insee character(5),
    gid integer NOT NULL,
    the_geom_local public.geometry(Point,2154),
    srid_dessin integer,
    the_geom_3857 public.geometry(Point,3857),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POINT'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154))
);
CREATE SEQUENCE hist_bryophytes.t_stations_bryo_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE hist_bryophytes.t_stations_bryo_gid_seq OWNED BY hist_bryophytes.t_stations_bryo.gid;
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo ALTER COLUMN gid SET DEFAULT nextval('hist_bryophytes.t_stations_bryo_gid_seq'::regclass);


----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY hist_bryophytes.bib_supports
    ADD CONSTRAINT bib_supports_pkey PRIMARY KEY (id_support);
ALTER TABLE ONLY hist_bryophytes.bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);
ALTER TABLE ONLY hist_bryophytes.bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);
ALTER TABLE ONLY hist_bryophytes.cor_bryo_observateur
    ADD CONSTRAINT pk_cor_bryo_observateur PRIMARY KEY (id_role, id_station);
ALTER TABLE ONLY hist_bryophytes.cor_bryo_taxon
    ADD CONSTRAINT pk_cor_bryo_taxons PRIMARY KEY (id_station, cd_nom);
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT pk_t_stations_bryo PRIMARY KEY (id_station);
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT t_stations_bryo_gid_key UNIQUE (gid);


---------------
--IMPORT DATA--
---------------
IMPORT FOREIGN SCHEMA bryophytes EXCEPT (bib_abondances,bib_expositions) FROM SERVER geonature1server INTO v1_compat;
--changement de nom de la table bib_abondances
CREATE FOREIGN TABLE v1_compat.bib_abondances_bryo
 (
	id_abondance character(1),
    nom_abondance varchar
)
SERVER geonature1server
OPTIONS (schema_name 'bryophytes', table_name 'bib_abondances');
--changement de nom de la table bib_expositions
CREATE FOREIGN TABLE v1_compat.bib_expositions_bryo
 (
	id_exposition character(2),
    nom_exposition varchar,
    tri_exposition int
)
SERVER geonature1server
OPTIONS (schema_name 'bryophytes', table_name 'bib_expositions');

INSERT INTO hist_bryophytes.bib_abondances SELECT * FROM v1_compat.bib_abondances_bryo;
INSERT INTO hist_bryophytes.bib_expositions SELECT * FROM v1_compat.bib_expositions_bryo;
INSERT INTO hist_bryophytes.bib_supports SELECT * FROM v1_compat.bib_supports;
INSERT INTO hist_bryophytes.t_stations_bryo SELECT * FROM v1_compat.t_stations_bryo;
INSERT INTO hist_bryophytes.cor_bryo_observateur SELECT * FROM v1_compat.cor_bryo_observateur;
INSERT INTO hist_bryophytes.cor_bryo_taxon SELECT * FROM v1_compat.cor_bryo_taxon;


---------
--INDEX--
---------
CREATE INDEX fki_t_stations_bryo_gid ON hist_bryophytes.t_stations_bryo USING btree (gid);
CREATE INDEX i_fk_t_stations_bryo_bib_exposit ON hist_bryophytes.t_stations_bryo USING btree (id_exposition);
CREATE INDEX index_cd_nom ON hist_bryophytes.cor_bryo_taxon USING btree (cd_nom);
CREATE INDEX index_gist_t_stations_bryo_the_geom_2154 ON hist_bryophytes.t_stations_bryo USING gist (the_geom_local);
CREATE INDEX index_gist_t_stations_bryo_the_geom_3857 ON hist_bryophytes.t_stations_bryo USING gist (the_geom_3857);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_supports FOREIGN KEY (id_support) REFERENCES hist_bryophytes.bib_supports(id_support) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_observateur
    ADD CONSTRAINT cor_bryo_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES hist_bryophytes.t_stations_bryo(id_station) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_abondance_fkey FOREIGN KEY (id_abondance) REFERENCES hist_bryophytes.bib_abondances(id_abondance) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES hist_bryophytes.t_stations_bryo(id_station) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.cor_bryo_observateur
    ADD CONSTRAINT fk_cor_bryo_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_expositions FOREIGN KEY (id_exposition) REFERENCES hist_bryophytes.bib_expositions(id_exposition) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_t_datasets FOREIGN KEY (id_lot) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY hist_bryophytes.t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_sinp_datatype_protocols FOREIGN KEY (id_protocole) REFERENCES gn_meta.sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE;

-------------------------
--SET UUID FOR SYNTHESE--
-------------------------
ALTER TABLE hist_bryophytes.t_stations_bryo ADD COLUMN unique_id_sinp_grp uuid;
UPDATE hist_bryophytes.t_stations_bryo SET unique_id_sinp_grp = uuid_generate_v4();
ALTER TABLE hist_bryophytes.t_stations_bryo ALTER COLUMN unique_id_sinp_grp SET NOT NULL;
ALTER TABLE hist_bryophytes.t_stations_bryo ALTER COLUMN unique_id_sinp_grp SET DEFAULT uuid_generate_v4();

ALTER TABLE hist_bryophytes.cor_bryo_taxon ADD COLUMN unique_id_sinp_bryo uuid;
UPDATE hist_bryophytes.cor_bryo_taxon SET unique_id_sinp_bryo = uuid_generate_v4();
ALTER TABLE hist_bryophytes.cor_bryo_taxon ALTER COLUMN unique_id_sinp_bryo SET NOT NULL;
ALTER TABLE hist_bryophytes.cor_bryo_taxon ALTER COLUMN unique_id_sinp_bryo SET DEFAULT uuid_generate_v4();

------------
--SYNTHESE--
------------
INSERT INTO gn_synthese.synthese
    (
      unique_id_sinp,
      unique_id_sinp_grp,
      id_source,
      entity_source_pk_value,
      id_dataset,
      id_nomenclature_geo_object_nature,
      id_nomenclature_grp_typ,
      id_nomenclature_obs_meth,
      id_nomenclature_bio_status,
      id_nomenclature_bio_condition,
      id_nomenclature_naturalness,
      id_nomenclature_exist_proof,
      id_nomenclature_valid_status,
      id_nomenclature_diffusion_level,
      id_nomenclature_life_stage,
      id_nomenclature_sex,
      id_nomenclature_obj_count,
      id_nomenclature_type_count,
      id_nomenclature_sensitivity,
      id_nomenclature_observation_status,
      id_nomenclature_blurring,
      id_nomenclature_source_status,
      id_nomenclature_info_geo_type,
      count_min,
      count_max,
      cd_nom,
      nom_cite,
      meta_v_taxref,
      altitude_min,
      altitude_max,
      the_geom_4326,
      the_geom_point,
      the_geom_local,
      date_min,
      date_max,
      observers,
      determiner,
      comment_context,
      last_action
    )
    SELECT
      cft.unique_id_sinp_bryo,
      s.unique_id_sinp_grp,
      106,
      cft.gid,
      s.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2'),
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      ref_nomenclatures.get_id_nomenclature('STADE_VIE','1'),
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'),
      NULL,--todo sensitivity
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      -1,--count_min
      -1,--count_max
      cft.cd_nom,
      COALESCE(cft.taxon_saisi,'non disponible'),
      'Taxref V11.0',
      s.altitude_retenue,--altitude_min
      s.altitude_retenue,--altitude_max
      public.st_transform(s.the_geom_3857,4326),
      public.st_transform(s.the_geom_3857,4326),
      s.the_geom_local,
      s.dateobs,--date_min
      s.dateobs,--date_max
      o.observateurs,--observers
      o.observateurs,--determiner
      s.remarques,
      CASE 
         WHEN s.date_insert = s.date_update THEN 'c'
         ELSE 'u'
      END
    FROM hist_bryophytes.t_stations_bryo s
      JOIN hist_bryophytes.cor_bryo_taxon cft ON cft.id_station = s.id_station
      JOIN (
        SELECT c.id_station, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
        FROM hist_bryophytes.cor_bryo_observateur c
        JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
        JOIN hist_bryophytes.t_stations_bryo s ON s.id_station = c.id_station
        GROUP BY c.id_station
      ) o ON o.id_station = s.id_station
    WHERE s.supprime = false AND cft.supprime = false;

INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
SELECT syn.id_synthese, c.id_role
FROM hist_bryophytes.cor_bryo_observateur c 
JOIN hist_bryophytes.cor_bryo_taxon cft ON cft.id_station = c.id_station
JOIN gn_synthese.synthese syn ON syn.entity_source_pk_value::integer = cft.gid AND syn.id_source = 106;

