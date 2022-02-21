--
-- PostgreSQL database dump
--

-- Dumped from database version 11.12 (Debian 11.12-0+deb10u1)
-- Dumped by pg_dump version 11.12 (Debian 11.12-0+deb10u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA gn_profiles;

-------------
--FUNCTIONS--
-------------

CREATE FUNCTION gn_profiles.check_profile_altitudes(
  in_alt_min integer,
  in_alt_max integer,
  profil_altitude_min integer,
   profil_altitude_max integer
) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
   BEGIN
    RETURN in_alt_min >= profil_altitude_min AND
      in_alt_max <= profil_altitude_max;
  END;
$$;

CREATE FUNCTION gn_profiles.check_profile_distribution(
  in_geom geometry,
  profil_geom geometry
  ) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que sa
--localisation est totalement incluse dans l'aire d'occurrences valide définie par le profil du
--taxon en question
  BEGIN
     RETURN ST_Contains(profil_geom, in_geom);
  END;
$$;


CREATE FUNCTION gn_profiles.check_profile_phenology(
    in_cd_ref integer,
    in_date_min date,
    in_date_max date,
    in_altitude_min integer,
    in_altitude_max integer,
    in_id_nomenclature_life_stage integer,
    check_life_stage boolean
) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  BEGIN


  IF check_life_stage THEN
    -- Suppression des valeurs inconnue et non renseignée
    IF
        in_id_nomenclature_life_stage = ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0')
        OR
        in_id_nomenclature_life_stage = ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1')
    THEN
        in_id_nomenclature_life_stage := NULL;
    END IF;

    RETURN EXISTS (
        SELECT *
        FROM gn_profiles.vm_cor_taxon_phenology c
        WHERE in_cd_ref = c.cd_ref
            AND date_part('doy', in_date_min) >= c.doy_min
            AND date_part('doy', in_date_max) <= c.doy_max
            AND in_altitude_min >= calculated_altitude_min
            AND in_altitude_max <= calculated_altitude_max
            AND in_id_nomenclature_life_stage = c.id_nomenclature_life_stage
    );
  ELSE
      RETURN EXISTS (
        SELECT *
        FROM gn_profiles.vm_cor_taxon_phenology c
        WHERE in_cd_ref = c.cd_ref
            AND date_part('doy', in_date_min) >= c.doy_min
            AND date_part('doy', in_date_max) <= c.doy_max
            AND in_altitude_min >= calculated_altitude_min
            AND in_altitude_max <= calculated_altitude_max
    );
   END IF;
  END;
$$;

CREATE FUNCTION gn_profiles.get_parameters(my_cd_nom integer) RETURNS TABLE(cd_ref integer, spatial_precision integer, temporal_precision_days integer, active_life_stage boolean, distance smallint)
    LANGUAGE plpgsql IMMUTABLE
    AS $$
-- fonction permettant de récupérer les paramètres les plus adaptés
-- (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
-- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard,
-- les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce
  DECLARE
   my_cd_ref integer := t.cd_ref FROM taxonomie.taxref t WHERE t.cd_nom=my_cd_nom;
  BEGIN
   RETURN QUERY
    WITH all_parameters AS (
     SELECT my_cd_ref, param.spatial_precision, param.temporal_precision_days,
     param.active_life_stage, parents.distance
     FROM gn_profiles.cor_taxons_parameters param
   JOIN taxonomie.find_all_taxons_parents(my_cd_ref) parents ON parents.cd_nom=param.cd_nom)
  SELECT * FROM all_parameters all_param WHERE all_param.distance=(
   SELECT min(all_param2.distance) FROM all_parameters all_param2
  )
   ;
  END;
$$;


CREATE FUNCTION gn_profiles.refresh_profiles() RETURNS void
    LANGUAGE plpgsql
    AS $$
-- Rafraichissement des vues matérialisées des profils
-- USAGE : SELECT gn_profiles.refresh_profiles()
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_valid_profiles;
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_cor_taxon_phenology;
END
$$;



----------
--TABLES--
----------

SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE gn_profiles.cor_taxons_parameters (
    cd_nom integer NOT NULL,
    spatial_precision integer,
    temporal_precision_days integer,
    active_life_stage boolean DEFAULT false
);



CREATE TABLE gn_profiles.t_parameters (
    id_parameter serial NOT NULL,
    name character varying(100) NOT NULL,
    "desc" text,
    value text NOT NULL
);

COMMENT ON TABLE gn_profiles.t_parameters IS 'Define global parameters for profiles calculation';


------------------
-- DEFAULT DATA --
------------------

INSERT INTO gn_profiles.cor_taxons_parameters(
	cd_nom, spatial_precision, temporal_precision_days, active_life_stage
)
SELECT
	DISTINCT t.cd_nom,
	2000,
	10,
	false
FROM taxonomie.taxref t
WHERE id_rang='KD';

-- Ajout d'un paramètre pour définir le niveau de validatation requis pour que les données alimentent
-- le calcul des profils
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
SELECT
	'id_valid_status_for_profiles',
	'Liste des id_nomenclature du statut de validation permettant de définir les données à prendre
	en compte dans le calcul des profils d''espèces. A renseigner sous forme de liste id1,id2,id3.',
	string_agg(DISTINCT n.id_nomenclature::text, ','::text)
FROM ref_nomenclatures.t_nomenclatures n
WHERE n.id_type=(
	SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types bnt WHERE mnemonique='STATUT_VALID'
	)
AND n.cd_nomenclature IN ('1','2') -- Commenter pour considérer l'ensemble des données;
;

-- Ajout d'un paramètre pour définir le niveau de validatation requis pour que les données alimentent
-- le calcul des profils
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
VALUES (
	'id_rang_for_profiles',
	'Liste des id_rang du taxref pour lesquels les profils doivent être calculés. A renseigner sous forme de liste id1,id2,id3.',
	'GN,ES,SSES'
)
;

-- Ajout d'un paramètre pour définir le pourcentage de données à conserver dans le calcul des profils
-- afin d'exclure les données aux altitudes extrêmes
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
VALUES (
	'proportion_kept_data',
	'Pourcentage de données à conserver dans le calcul des profils afin d''exclure les données aux
	altitudes extrêmes. Ce paramètre doit être supérieur à 50 pour que la phénologie soit calculée.',
	95
);


-----------------------------------
-----VIEW AND MATERIALIZED VIEW----
-----------------------------------

CREATE VIEW gn_profiles.v_decode_profiles_parameters AS
 SELECT t.cd_ref,
    t.lb_nom,
    t.id_rang,
    p.spatial_precision,
    p.temporal_precision_days,
    p.active_life_stage
   FROM (gn_profiles.cor_taxons_parameters p
     LEFT JOIN taxonomie.taxref t ON ((p.cd_nom = t.cd_nom)));


CREATE VIEW gn_profiles.v_synthese_for_profiles AS
WITH excluded_live_stage AS (
	SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') AS id_n_excluded
	UNION
	SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1') AS id_n_excluded
) SELECT s.id_synthese,
    s.cd_nom,
    s.nom_cite,
    t.cd_ref,
    t.nom_valide,
    t.id_rang,
    s.date_min,
    s.date_max,
    s.the_geom_local,
    s.the_geom_4326,
    s.altitude_min,
    s.altitude_max,
    CASE
    	WHEN s.id_nomenclature_life_stage IN (SELECT id_n_excluded FROM excluded_live_stage) THEN NULL
    	ELSE s.id_nomenclature_life_stage
    END AS id_nomenclature_life_stage,
    s.id_nomenclature_valid_status,
    p.spatial_precision,
    p.temporal_precision_days,
    p.active_life_stage,
    p.distance
   FROM ((gn_synthese.synthese s
     LEFT JOIN taxonomie.taxref t ON ((s.cd_nom = t.cd_nom)))
     CROSS JOIN LATERAL gn_profiles.get_parameters(s.cd_nom) p(cd_ref, spatial_precision, temporal_precision_days, active_life_stage, distance))
  WHERE ((p.spatial_precision IS NOT NULL) AND (
	  public.st_maxdistance(public.st_centroid(s.the_geom_local), s.the_geom_local) < (p.spatial_precision)::double precision
	  )
    AND s.altitude_max IS NOT NULL AND s.altitude_min IS NOT NULL
    AND (
		  s.id_nomenclature_valid_status IN ( SELECT (regexp_split_to_table(t_parameters.value, ','::text))::integer AS regexp_split_to_table
           FROM gn_profiles.t_parameters
          WHERE ((t_parameters.name)::text = 'id_valid_status_for_profiles'::text))
		) 
    AND ((t.id_rang)::text IN ( SELECT regexp_split_to_table(t_parameters.value, ','::text) AS regexp_split_to_table
           FROM gn_profiles.t_parameters
          WHERE ((t_parameters.name)::text = 'id_rang_for_profiles'::text))
        ));

COMMENT ON VIEW gn_profiles.v_synthese_for_profiles IS 'View containing synthese data feeding profiles calculation.
 cd_ref, date_min, date_max, the_geom_local, altitude_min, altitude_max and
 id_nomenclature_life_stage fields are mandatory.
 WHERE clauses have to apply your t_parameters filters (valid_status)';


CREATE MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology
AS
WITH exlude_live_stage AS (
	SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') AS id_n_excluded
	UNION
	SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1') AS id_n_excluded
),  params AS (
	SELECT (value::double PRECISION / 100 ) AS proportion_kept_data
	FROM gn_profiles.t_parameters parameters
	WHERE parameters.name = 'proportion_kept_data'
), classified_data AS (
    SELECT DISTINCT
        vsfp.cd_ref,
        unnest(
            ARRAY[
                floor(date_part('doy', vsfp.date_min) / vsfp.temporal_precision_days::double precision) * vsfp.temporal_precision_days::double precision,
                floor(date_part('doy', vsfp.date_max) / vsfp.temporal_precision_days::double precision) * vsfp.temporal_precision_days::double precision
            ]
        ) AS doy_min,
        unnest(
            ARRAY[
                floor(date_part('doy', vsfp.date_min) / vsfp.temporal_precision_days::double precision) * vsfp.temporal_precision_days::double precision + vsfp.temporal_precision_days::double precision,
                floor(date_part('doy', vsfp.date_max) / vsfp.temporal_precision_days::double precision) * vsfp.temporal_precision_days::double precision + vsfp.temporal_precision_days::double precision
                ]
        ) AS doy_max,
        CASE
            WHEN vsfp.active_life_stage = true AND NOT vsfp.id_nomenclature_life_stage IN (SELECT id_n_excluded FROM exlude_live_stage)
                THEN vsfp.id_nomenclature_life_stage
            ELSE NULL::integer
        END AS id_nomenclature_life_stage,
        count(vsfp.*) AS count_valid_data,
        min(vsfp.altitude_min) AS extreme_altitude_min,
        percentile_disc((SELECT proportion_kept_data FROM params)) WITHIN GROUP (ORDER BY vsfp.altitude_min DESC) AS p_min,
        max(vsfp.altitude_max) AS extreme_altitude_max,
        percentile_disc((SELECT proportion_kept_data FROM params)) WITHIN GROUP (ORDER BY vsfp.altitude_max) AS p_max
    FROM  gn_profiles.v_synthese_for_profiles  vsfp
    WHERE vsfp.temporal_precision_days IS NOT NULL
    AND vsfp.spatial_precision IS NOT NULL
    AND vsfp.active_life_stage IS NOT NULL
    AND date_part('day', vsfp.date_max - vsfp.date_min) < vsfp.temporal_precision_days::double precision
    AND vsfp.altitude_min IS NOT NULL AND vsfp.altitude_max IS NOT NULL
    GROUP BY
    vsfp.cd_ref,
    doy_min,
    doy_max,
    4  --id_nomenclature_life_stage
)
SELECT classified_data.cd_ref,
    classified_data.doy_min,
    classified_data.doy_max,
    classified_data.id_nomenclature_life_stage,
    classified_data.count_valid_data,
    classified_data.extreme_altitude_min,
    p_min AS calculated_altitude_min,
    classified_data.extreme_altitude_max,
    p_max AS calculated_altitude_max
    FROM classified_data ;

COMMENT ON MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology IS 'View containing phenological combinations and corresponding valid data for each taxa';


CREATE MATERIALIZED VIEW gn_profiles.vm_valid_profiles AS
 SELECT DISTINCT vsfp.cd_ref,
    public.st_union(public.st_buffer(vsfp.the_geom_local, (COALESCE(vsfp.spatial_precision, 1))::double precision)) AS valid_distribution,
    min(vsfp.altitude_min) AS altitude_min,
    max(vsfp.altitude_max) AS altitude_max,
    min(vsfp.date_min) AS first_valid_data,
    max(vsfp.date_max) AS last_valid_data,
    count(vsfp.*) AS count_valid_data,
    vsfp.active_life_stage
   FROM  gn_profiles.v_synthese_for_profiles vsfp
  GROUP BY vsfp.cd_ref, vsfp.active_life_stage
  WITH DATA;




CREATE VIEW gn_profiles.v_consistancy_data AS
SELECT s.id_synthese,
    s.unique_id_sinp AS id_sinp,
    t.cd_ref,
    t.lb_nom AS valid_name,
    gn_profiles.check_profile_distribution(s.the_geom_local, p.valid_distribution) AS valid_distribution,
    gn_profiles.check_profile_phenology(
      t.cd_ref, s.date_min::date, s.date_max::date, s.altitude_min, s.altitude_max, s.id_nomenclature_life_stage, p.active_life_stage
    ) AS valid_phenology,
    gn_profiles.check_profile_altitudes(
        s.altitude_min, s.altitude_max, p.altitude_min, p.altitude_max
    ) AS valid_altitude,
    n.label_default AS valid_status
FROM gn_synthese.synthese s
JOIN taxonomie.taxref t
    ON s.cd_nom = t.cd_nom
JOIN gn_profiles.vm_valid_profiles p
    ON p.cd_ref = t.cd_ref
LEFT JOIN ref_nomenclatures.t_nomenclatures n
    ON s.id_nomenclature_valid_status = n.id_nomenclature
;


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY gn_profiles.t_parameters
    ADD CONSTRAINT pk_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters
    ADD CONSTRAINT pk_taxons_parameters PRIMARY KEY (cd_nom);


-----------
-- INDEX --
-----------
CREATE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref);
CREATE INDEX index_vm_cor_taxon_phenology_cd_ref ON gn_profiles.vm_cor_taxon_phenology USING btree (cd_ref);
CREATE UNIQUE INDEX vm_cor_taxon_phenology_cd_ref_period_id_nomenclature_life_s_idx ON gn_profiles.vm_cor_taxon_phenology USING btree (cd_ref, doy_min, doy_max, id_nomenclature_life_stage);



-----------------
-- FOREIGN KEY --
-----------------

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters
    ADD CONSTRAINT fk_cor_taxons_parameters_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


