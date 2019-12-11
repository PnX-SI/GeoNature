
SET search_path = public, pg_catalog;
DROP FOREIGN TABLE v1_compat.v_nomade_classes;
IMPORT FOREIGN SCHEMA florepatri FROM SERVER geonature1server INTO v1_compat;

CREATE SCHEMA v1_florepatri;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = v1_florepatri, pg_catalog;

SET default_with_oids = false;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION letypedegeom(mongeom public.geometry)
  RETURNS character varying AS
$BODY$
DECLARE
thetype varchar(18);
montype varchar(15);
BEGIN
select public.st_geometrytype(mongeom) into thetype;
select
	case 	when thetype= 'ST_Polygon'  then 'Polygon'
		when thetype= 'ST_MultiPolygon' then 'Polygon'
		when thetype= 'ST_LineString' then 'LineString'
		when thetype= 'ST_MultiLineString' then 'LineString'
		when thetype= 'ST_Point' then 'Point'
		when thetype= 'ST_MultiPoint' then 'Point'
		into montype
	end;
return montype;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------
--TABLES--
----------
CREATE TABLE bib_comptages_methodo (
    id_comptage_methodo integer NOT NULL,
    nom_comptage_methodo character varying(100)
);

CREATE TABLE bib_frequences_methodo_new (
    id_frequence_methodo_new character(1) NOT NULL,
    nom_frequence_methodo_new character varying(100)
);

CREATE TABLE bib_pentes (
    id_pente integer NOT NULL,
    val_pente real NOT NULL,
    nom_pente character varying(100)
);

CREATE TABLE bib_perturbations (
    codeper smallint NOT NULL,
    classification character varying(30) NOT NULL,
    description character varying(65) NOT NULL
);

CREATE TABLE bib_phenologies (
    codepheno smallint NOT NULL,
    pheno character varying(45) NOT NULL
);

CREATE TABLE bib_physionomies (
    id_physionomie integer NOT NULL,
    groupe_physionomie character varying(20),
    nom_physionomie character varying(100),
    definition_physionomie text,
    code_physionomie character varying(3)
);

CREATE TABLE bib_rezo_ecrins (
    id_rezo_ecrins integer NOT NULL,
    nom_rezo_ecrins character varying(100)
);

CREATE TABLE bib_statuts (
    id_statut integer NOT NULL,
    nom_statut character varying(20) NOT NULL,
    desc_statut text
);


CREATE TABLE bib_taxons_fp (
    num_nomenclatural bigint NOT NULL,
    francais character varying(100),
    latin character varying(100),
    echelle smallint NOT NULL,
    cd_nom integer NOT NULL,
    nomade_ecrins boolean DEFAULT false NOT NULL
);

CREATE TABLE cor_ap_perturb (
    indexap bigint NOT NULL,
    codeper smallint NOT NULL
);

CREATE TABLE cor_ap_physionomie (
    indexap bigint NOT NULL,
    id_physionomie smallint NOT NULL
);

CREATE TABLE cor_taxon_statut (
    id_statut integer NOT NULL,
    cd_nom integer NOT NULL
);

CREATE TABLE cor_zp_obs (
    indexzp bigint NOT NULL,
    codeobs integer NOT NULL
);

CREATE TABLE t_apresence (
    indexap bigint NOT NULL,
    codepheno smallint NOT NULL,
    indexzp bigint NOT NULL,
    altitude_saisie smallint,
    surfaceap integer NOT NULL,
    frequenceap real NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    topo_valid boolean,
    supprime boolean DEFAULT false NOT NULL,
    erreur_signalee boolean DEFAULT false,
    diffusable boolean DEFAULT true,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    insee character(5),
    id_frequence_methodo_new character(1) NOT NULL,
    nb_transects_frequence integer DEFAULT 0,
    nb_points_frequence integer DEFAULT 0,
    nb_contacts_frequence integer DEFAULT 0,
    id_comptage_methodo integer NOT NULL,
    nb_placettes_comptage integer,
    surface_placette_comptage real,
    remarques text,
    the_geom_local public.geometry(Geometry,2154),
    the_geom_3857 public.geometry(Geometry,3857),
    longueur_pas numeric(10,2),
    effectif_placettes_steriles integer,
    effectif_placettes_fertiles integer,
    total_steriles integer,
    total_fertiles integer,
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);

CREATE TABLE t_zprospection (
    indexzp bigint NOT NULL,
    id_secteur integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    dateobs date NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    validation boolean DEFAULT false,
    topo_valid boolean,
    erreur_signalee boolean DEFAULT false,
    supprime boolean DEFAULT false NOT NULL,
    cd_nom integer,
    saisie_initiale character varying(20),
    insee character(5),
    taxon_saisi character varying(100),
    the_geom_local public.geometry(Geometry,2154),
    geom_point_3857 public.geometry(Point,3857),
    geom_mixte_3857 public.geometry(Geometry,3857),
    srid_dessin integer,
    the_geom_3857 public.geometry(Geometry,3857),
    id_rezo_ecrins integer DEFAULT 0 NOT NULL,
    CONSTRAINT enforce_dims_geom_mixte_3857 CHECK ((public.st_ndims(geom_mixte_3857) = 2)),
    CONSTRAINT enforce_dims_geom_point_3857 CHECK ((public.st_ndims(geom_point_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_geom_point_3857 CHECK (((public.geometrytype(geom_point_3857) = 'POINT'::text) OR (geom_point_3857 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POLYGON'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POLYGON'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_geom_mixte_3857 CHECK ((public.st_srid(geom_mixte_3857) = 3857)),
    CONSTRAINT enforce_srid_geom_point_3857 CHECK ((public.st_srid(geom_point_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


---------
--VIEWS--
---------
CREATE VIEW v_ap_line AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_local) = 'MULTILINESTRING'::text) OR (public.geometrytype(a.the_geom_local) = 'LINESTRING'::text));

CREATE VIEW v_ap_point AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_local) = 'POINT'::text) OR (public.geometrytype(a.the_geom_local) = 'MULTIPOINT'::text));

CREATE VIEW v_ap_poly AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_local) = 'POLYGON'::text) OR (public.geometrytype(a.the_geom_local) = 'MULTIPOLYGON'::text));

CREATE VIEW v_mobile_observateurs_fp AS
 SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role
   FROM utilisateurs.t_roles r
  WHERE ((r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE (crm.id_menu = 5)))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM (utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON ((((r_1.id_role = crm.id_role) AND (crm.id_menu = 5)) AND (r_1.groupe = false)))))))
  ORDER BY r.nom_role, r.prenom_role, r.id_role;

CREATE VIEW v_mobile_pentes AS
 SELECT bib_pentes.id_pente,
    bib_pentes.val_pente,
    bib_pentes.nom_pente
   FROM bib_pentes
  ORDER BY bib_pentes.id_pente;

CREATE VIEW v_mobile_perturbations AS
 SELECT bib_perturbations.codeper,
    bib_perturbations.classification,
    bib_perturbations.description
   FROM bib_perturbations
  ORDER BY bib_perturbations.codeper;

CREATE VIEW v_mobile_phenologies AS
 SELECT bib_phenologies.codepheno,
    bib_phenologies.pheno
   FROM bib_phenologies
  ORDER BY bib_phenologies.codepheno;

CREATE VIEW v_mobile_physionomies AS
 SELECT bib_physionomies.id_physionomie,
    bib_physionomies.groupe_physionomie,
    bib_physionomies.nom_physionomie
   FROM bib_physionomies
  ORDER BY bib_physionomies.id_physionomie;


CREATE VIEW v_mobile_taxons_fp AS
 SELECT bt.cd_nom,
    bt.latin AS nom_latin,
    bt.francais AS nom_francais
   FROM bib_taxons_fp bt
  WHERE (bt.nomade_ecrins = true)
  ORDER BY bt.latin;


CREATE VIEW v_mobile_visu_zp AS
 SELECT t_zprospection.indexzp,
    t_zprospection.cd_nom,
    t_zprospection.the_geom_local
   FROM t_zprospection
  WHERE (date_part('year'::text, t_zprospection.dateobs) = date_part('year'::text, now()));

CREATE VIEW v_nomade_taxon AS
 SELECT bt.cd_nom,
    bt.latin,
    bt.francais,
    bt.echelle,
    '1,2,3,4,5,6,7,8'::character(15) AS codepheno,
    'TF,RS'::character(5) AS codeobjet
   FROM bib_taxons_fp bt
  WHERE (bt.nomade_ecrins = true)
  ORDER BY bt.latin;

CREATE VIEW v_nomade_zp AS
 SELECT zp.indexzp,
    zp.cd_nom,
    vobs.codeobs,
    zp.dateobs,
    'Polygon'::character(7) AS montype,
    substr(public.st_asgml(zp.the_geom_local), (strpos(public.st_asgml(zp.the_geom_local), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(zp.the_geom_local), '</gml:coordinates>'::text) - (strpos(public.st_asgml(zp.the_geom_local), '<gml:coordinates>'::text) + 17))) AS coordinates,
    vap.indexap,
    zp.id_secteur AS id_secteur_fp
   FROM ((t_zprospection zp
     JOIN ( SELECT cor.indexzp,
            substr((array_agg(cor.codeobs))::text, 2, (strpos((array_agg(cor.codeobs))::text, '}'::text) - 2)) AS codeobs
           FROM ( SELECT aa.indexzp,
                    aa.codeobs
                   FROM cor_zp_obs aa
                  WHERE (aa.codeobs <> 247)
                  ORDER BY aa.indexzp, aa.codeobs) cor
          GROUP BY cor.indexzp) vobs ON ((vobs.indexzp = zp.indexzp)))
     LEFT JOIN ( SELECT ap.indexzp,
            substr((array_agg(ap.indexap))::text, 2, (strpos((array_agg(ap.indexap))::text, '}'::text) - 2)) AS indexap
           FROM ( SELECT aa.indexzp,
                    aa.indexap
                   FROM t_apresence aa
                  WHERE (aa.supprime = false)
                  ORDER BY aa.indexzp, aa.indexap) ap
          GROUP BY ap.indexzp) vap ON ((vap.indexzp = zp.indexzp)))
  WHERE (((((zp.topo_valid = true) AND (zp.supprime = false)) AND (zp.id_secteur < 9)) AND (zp.dateobs > '2010-01-01'::date)) AND (zp.cd_nom IN ( SELECT v_nomade_taxon.cd_nom
           FROM v_nomade_taxon)))
  ORDER BY zp.indexzp;

CREATE VIEW v_nomade_ap AS
 SELECT ap.indexap,
    ap.codepheno,
    letypedegeom(ap.the_geom_local) AS montype,
    substr(public.st_asgml(ap.the_geom_local), (strpos(public.st_asgml(ap.the_geom_local), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(ap.the_geom_local), '</gml:coordinates>'::text) - (strpos(public.st_asgml(ap.the_geom_local), '<gml:coordinates>'::text) + 17))) AS coordinates,
    ap.surfaceap,
    (((ap.id_frequence_methodo_new)::text || ';'::text) || (ap.frequenceap)::integer) AS frequence,
    vper.codeper,
    ((('TF;'::text || ((ap.total_fertiles)::character(1))::text) || ',RS;'::text) || ((ap.total_steriles)::character(1))::text) AS denombrement,
    zp.id_secteur_fp
   FROM ((t_apresence ap
     JOIN v_nomade_zp zp ON ((ap.indexzp = zp.indexzp)))
     LEFT JOIN ( SELECT ab.indexap,
            substr((array_agg(ab.codeper))::text, 2, (strpos((array_agg(ab.codeper))::text, '}'::text) - 2)) AS codeper
           FROM ( SELECT aa.indexap,
                    aa.codeper
                   FROM cor_ap_perturb aa
                  ORDER BY aa.indexap, aa.codeper) ab
          GROUP BY ab.indexap) vper ON ((vper.indexap = ap.indexap)))
  WHERE (ap.supprime = false)
  ORDER BY ap.indexap;

CREATE VIEW v_nomade_classes AS
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM (( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM ((taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON ((cnl.id_liste = l.id_liste)))
             JOIN taxonomie.bib_noms n ON ((n.id_nom = cnl.id_nom)))
          WHERE ((l.id_liste > 300) AND (l.id_liste < 400))
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON ((t.cd_nom = g.cd_ref)))
  WHERE ((t.regne)::text = 'Plantae'::text);

CREATE VIEW v_touteslesap_sridlocal_line AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    --s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.nom_com,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM (((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     --JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN ref_geo.li_municipalities com ON ((com.insee_com = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_local) = 'LINESTRING'::text))
  ORDER BY ap.indexzp;

CREATE VIEW v_touteslesap_sridlocal_point AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    --s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.nom_com,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM (((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     --JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN ref_geo.li_municipalities com ON ((com.insee_com = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_local) = 'POINT'::text))
  ORDER BY ap.indexzp;

CREATE VIEW v_touteslesap_sridlocal_polygon AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    --s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.nom_com,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM (((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     --JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN ref_geo.li_municipalities com ON ((com.insee_com = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_local) = 'POLYGON'::text))
  ORDER BY ap.indexzp;

CREATE VIEW v_toutesleszp_sridlocal AS
 SELECT zp.indexzp AS gid,
    zp.indexzp,
    --s.nom_secteur AS secteur,
    count(ap.indexap) AS nbap,
    zp.dateobs,
    t.latin AS taxon,
    zp.taxon_saisi,
    o.observateurs,
    zp.the_geom_local,
    zp.insee,
    com.nom_com AS commune,
    org.nom_organisme AS organisme_producteur,
    zp.topo_valid AS zp_topo_valid,
    zp.validation AS relue,
    zp.saisie_initiale,
    zp.srid_dessin
   FROM (((((t_zprospection zp
     LEFT JOIN t_apresence ap ON ((ap.indexzp = zp.indexzp)))
     JOIN ref_geo.li_municipalities com ON ((com.insee_com = zp.insee)))
     LEFT JOIN utilisateurs.bib_organismes org ON ((org.id_organisme = zp.id_organisme)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     --JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = zp.indexzp)))
  WHERE zp.supprime = false
  GROUP BY zp.indexzp, zp.dateobs, t.latin, zp.taxon_saisi, o.observateurs, zp.the_geom_local, zp.insee, com.nom_com, org.nom_organisme, zp.topo_valid, zp.validation, zp.saisie_initiale, zp.srid_dessin
  ORDER BY zp.indexzp;


----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_pkey PRIMARY KEY (indexap);

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_pkey PRIMARY KEY (indexzp);

ALTER TABLE ONLY bib_comptages_methodo
    ADD CONSTRAINT bib_comptages_methodo_pkey PRIMARY KEY (id_comptage_methodo);

ALTER TABLE ONLY bib_frequences_methodo_new
    ADD CONSTRAINT bib_frequences_methodo_new_pkey PRIMARY KEY (id_frequence_methodo_new);

ALTER TABLE ONLY bib_pentes
    ADD CONSTRAINT bib_pentes_pkey PRIMARY KEY (id_pente);

ALTER TABLE ONLY bib_physionomies
    ADD CONSTRAINT bib_physionomies_pk PRIMARY KEY (id_physionomie);

ALTER TABLE ONLY bib_rezo_ecrins
    ADD CONSTRAINT bib_rezo_ecrins_pkey PRIMARY KEY (id_rezo_ecrins);

ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_pkey PRIMARY KEY (cd_nom);

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT cor_zp_obs_pkey PRIMARY KEY (indexzp, codeobs);

ALTER TABLE ONLY bib_perturbations
    ADD CONSTRAINT pk_bib_perturbation PRIMARY KEY (codeper);

ALTER TABLE ONLY bib_phenologies
    ADD CONSTRAINT pk_bib_phenologie PRIMARY KEY (codepheno);

ALTER TABLE ONLY bib_statuts
    ADD CONSTRAINT pk_bib_statuts PRIMARY KEY (id_statut);

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT pk_cor_ap_perturb PRIMARY KEY (indexap, codeper);

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT pk_cor_ap_physionomie PRIMARY KEY (indexap, id_physionomie);

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT pk_cor_taxon_statut PRIMARY KEY (id_statut, cd_nom);


---------
--INDEX--
---------
CREATE INDEX fki_cor_zp_obs_t_roles ON cor_zp_obs USING btree (codeobs);
CREATE INDEX fki_t_apresence_t_zprospection ON t_apresence USING btree (indexzp);
CREATE INDEX i_fk_t_apresence_bib_phenologi ON t_apresence USING btree (codepheno);
CREATE INDEX i_fk_t_zprospection_bib_secteu ON t_zprospection USING btree (id_secteur);
CREATE INDEX index_gist_t_apresence_the_geom_local ON t_apresence USING gist (the_geom_local);
CREATE INDEX index_gist_t_apresence_the_geom_3857 ON t_apresence USING gist (the_geom_3857);
CREATE INDEX index_gist_t_zprospection_the_geom_local ON t_zprospection USING gist (the_geom_local);
CREATE INDEX index_gist_t_zprospection_the_geom_3857 ON t_zprospection USING gist (the_geom_3857);
CREATE INDEX index_gist_t_zprospection_geom_point_3857 ON t_zprospection USING gist (geom_point_3857);
CREATE INDEX index_gist_t_zprospection_geom_mixte_3857 ON t_zprospection USING gist (geom_mixte_3857);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT cor_taxon_statut_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_bib_perturbati FOREIGN KEY (codeper) REFERENCES bib_perturbations(codeper) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_bib_physio FOREIGN KEY (id_physionomie) REFERENCES bib_physionomies(id_physionomie) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT fk_cor_taxon_statut_bib_statuts FOREIGN KEY (id_statut) REFERENCES bib_statuts(id_statut) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_roles FOREIGN KEY (codeobs) REFERENCES utilisateurs.t_roles(id_role);

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_bib_phenologie FOREIGN KEY (codepheno) REFERENCES bib_phenologies(codepheno) ON UPDATE CASCADE;

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_datasets FOREIGN KEY (id_lot) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_bib_taxon_fp FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_t_protocoles FOREIGN KEY (id_protocole) REFERENCES gn_meta.sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE;

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_comptage_methodo_fkey FOREIGN KEY (id_comptage_methodo) REFERENCES bib_comptages_methodo(id_comptage_methodo) ON UPDATE CASCADE;

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_frequence_methodo_new_fkey FOREIGN KEY (id_frequence_methodo_new) REFERENCES bib_frequences_methodo_new(id_frequence_methodo_new) ON UPDATE CASCADE;

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_rezo_ecrins_fkey FOREIGN KEY (id_rezo_ecrins) REFERENCES bib_rezo_ecrins(id_rezo_ecrins) ON UPDATE CASCADE;

--ALTER TABLE ONLY t_zprospection
    --ADD CONSTRAINT t_zprospection_id_secteur_fkey FOREIGN KEY (id_secteur) REFERENCES layers.l_secteurs(id_secteur) ON UPDATE CASCADE;


------------
--TRIGGERS--
------------
-- Function insert_ap
CREATE OR REPLACE FUNCTION v1_florepatri.insert_ap()
  RETURNS trigger AS
$BODY$
DECLARE
  moncentroide public.geometry;
  theinsee character varying(25);
  thealtitude integer;
BEGIN
  -- si l'aire de présence est deja dans la BDD alors le trigger retourne null (l'insertion de la ligne est annulée)
  IF new.indexap in (SELECT indexap FROM v1_florepatri.t_apresence) THEN   
    RETURN NULL;    
  ELSE
    -- gestion de la date insert, la date update prend aussi comme valeur cette premiere date insert
    IF new.date_insert ISNULL THEN 
      new.date_insert='now';
    END IF;
    IF new.date_update ISNULL THEN 
      new.date_update='now';
    END IF;
    -- gestion des géometries selon l'outil de saisie :
    -- Attention !!! La saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
    IF new.the_geom_3857 IS NOT NULL THEN -- saisie web avec the_geom_3857
      new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    ELSIF new.the_geom_local IS NOT NULL THEN  -- saisie avec outil nomade android avec the_geom_local
      new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    END IF;
    -- calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
    -- puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93
    IF public.ST_isvalid(new.the_geom_local) AND public.ST_isvalid(new.the_geom_3857) THEN
      new.topo_valid = 'true';
      -- on calcul la commune...
      SELECT INTO theinsee m.insee_com
      FROM ref_geo.l_areas lc
      JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
      WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
      ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
      new.insee = theinsee;-- mise à jour du code insee
      -- on calcul l'altitude
      SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
      new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
      IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
      ELSE
        new.altitude_retenue = new.altitude_saisie;
      END IF;
    ELSE
      new.topo_valid = 'false';
      moncentroide = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
      -- on calcul la commune...
      SELECT INTO theinsee m.insee_com
      FROM ref_geo.l_areas lc
      JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
      WHERE public.st_intersects(lc.geom, moncentroide) AND lc.id_type = 25
      ORDER BY public.ST_area(public.ST_intersection(lc.geom, moncentroide)) DESC LIMIT 1;
      new.insee = theinsee;-- mise à jour du code insee
      -- on calcul l'altitude
      SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(moncentroide) LIMIT 1) a;
      new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
      IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
      ELSE
        new.altitude_retenue = new.altitude_saisie;
      END IF;
    END IF;
    RETURN NEW;
  END IF;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- Function update_ap
CREATE OR REPLACE FUNCTION v1_florepatri.update_ap()
  RETURNS trigger AS
$BODY$
DECLARE
  moncentroide public.geometry;
  theinsee character varying(25);
  thealtitude integer;
BEGIN
-- gestion de la date update en cas de manip sql directement en base ou via l'appli web 
  new.date_update='now';
-----------------------------------------------------------------------------------------------------------------
/*  section en attente : 
on pourrait verifier le changement des 3 geom pour lancer les commandes de geometries
car pour le moment on ne gere pas les 2 cas de changement sur le geom 2154 ou the geom
code ci dessous a revoir car public.st_equals ne marche pas avec les objets invalid

IF 
    (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local IS null AND new.the_geom_local IS NOT NULL))
    OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857)OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL)) 
THEN
    IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL) THEN
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
  ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local IS null AND new.the_geom_local IS NOT NULL) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
  END IF;
puis suite du THEN
fin de section en attente */ 
------------------------------------------------------------------------------------------------------
-- gestion des infos relatives aux géométries
-- ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "inséré" par une commande update !
-- POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857
  IF public.ST_NumGeometries(new.the_geom_3857)=1 THEN -- si le Multi objet renvoyé par le oueb ne contient qu'un objet
    new.the_geom_3857 = public.ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
  END IF;
  new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
  -- calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
  -- puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93
  IF public.ST_isvalid(new.the_geom_local) AND public.ST_isvalid(new.the_geom_3857) THEN
    new.topo_valid = 'true';
    -- on calcul la commune...
    SELECT INTO theinsee m.insee_com
    FROM ref_geo.l_areas lc
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN  -- mise à jour de l'altitude retenue
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE
    new.topo_valid = 'false';
    moncentroide = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
    -- on calcul la commune...
    SELECT INTO theinsee m.insee_com
    FROM ref_geo.l_areas lc
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, moncentroide) AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, moncentroide)) DESC LIMIT 1;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(moncentroide) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Function insert_zp
CREATE OR REPLACE FUNCTION v1_florepatri.insert_zp()
  RETURNS trigger AS
$BODY$
DECLARE
  monsectfp integer;
  macommune character(5);
  moncentroide public.geometry;
BEGIN
  -- si la zone de prospection est deja dans la BDD alors le trigger retourne null
  -- (l'insertion de la ligne est annulée et on passe a la donnée suivante).
  IF new.indexzp in (SELECT indexzp FROM v1_florepatri.t_zprospection) THEN
    RETURN NULL;
  ELSE
  -- gestion de la date insert, la date update prend aussi comme valeur cette premiere date insert
    IF new.date_insert IS NULL THEN 
        new.date_insert='now';
    END IF;
    IF new.date_update IS NULL THEN
        new.date_update='now';
    END IF;
  -- gestion de la source des géometries selon l'outil de saisie :
    IF new.saisie_initiale = 'nomade' THEN
      new.srid_dessin = 2154;
      new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    ELSIF new.saisie_initiale = 'web' THEN
      new.srid_dessin = 3857;
      -- attention : pas de calcul sur les geoemtry car "the_geom_3857" est inseré par le trigger update !!
    ELSIF new.saisie_initiale IS NULL THEN
      new.srid_dessin = 0; -- pas d'info sur le srid utilisé, cas possible des importations de couches SIG, il faudra gérer manuellement !
    END IF;
    -- début de calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
    -- puis calcul du geom_point_3857 (selon validité de the_geom_3857)
    -- puis gestion des croisements SIG avec les layers secteur et communes en projection Lambert93
    IF public.ST_isvalid(new.the_geom_local) AND public.ST_isvalid(new.the_geom_3857) THEN
      new.topo_valid = 'true';
      -- calcul du geom_point_3857 
      new.geom_point_3857 = public.ST_pointonsurface(new.the_geom_3857); -- calcul du point pour le premier niveau de zoom appli web
      -- croisement secteur (celui qui contient le plus de zp en surface)
      SELECT INTO monsectfp ls.area_code::integer 
      FROM ref_geo.l_areas ls 
      WHERE public.st_intersects(ls.geom, new.the_geom_local) AND ls.id_type = 30
      ORDER BY public.ST_area(public.ST_intersection(ls.geom, new.the_geom_local)) DESC LIMIT 1;
      -- croisement commune (celle qui contient le plus de zp en surface)
      SELECT INTO macommune m.insee_com 
      FROM ref_geo.l_areas lc 
      JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
      WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
      ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
    ELSE
      new.topo_valid = 'false';
      -- calcul du geom_point_3857
      new.geom_point_3857 = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
      moncentroide = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
      -- croisement secteur (celui qui contient moncentroide)
      SELECT INTO monsectfp ls.area_code::integer 
      FROM ref_geo.l_areas ls 
      WHERE public.st_intersects(ls.geom, moncentroide)
      AND ls.id_type = 30
      ORDER BY public.ST_area(public.ST_intersection(ls.geom, moncentroide)) DESC LIMIT 1;
      -- croisement commune (celle qui contient moncentroid)
      SELECT INTO macommune m.insee_com 
      FROM ref_geo.l_areas lc 
      JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
      WHERE public.st_intersects(lc.geom, moncentroide)
      AND lc.id_type = 25
      ORDER BY public.ST_area(public.ST_intersection(lc.geom, moncentroide)) DESC LIMIT 1;
    END IF;
    new.insee = macommune;
    IF monsectfp IS NULL THEN -- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
      new.id_secteur = 999; -- alors on met 999 (hors zone) en code secteur fp
    ELSE
      new.id_secteur = monsectfp; --sinon on met le code du secteur.
    END IF;
    -- calcul du geom_mixte_3857
    IF public.ST_area(new.the_geom_3857) <10000 THEN -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
      new.geom_mixte_3857 = new.geom_point_3857;
    ELSE
      new.geom_mixte_3857 = new.the_geom_3857;
    END IF; --fin de calcul
    RETURN NEW; -- return des valeurs :
  END IF;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

--Function update_zp
CREATE OR REPLACE FUNCTION v1_florepatri.update_zp()
  RETURNS trigger AS
$BODY$
DECLARE
  monsectfp integer;
  macommune character(5);
  moncentroide public.geometry;
BEGIN
  -- gestion de la date update en cas de manip sql directement en base
  new.date_update='now';
  -- update en cas de passage du champ supprime = TRUE, alors on passe les aires de présence en supprime = TRUE
  IF new.supprime = 't' THEN
    UPDATE v1_florepatri.t_apresence SET supprime = 't' WHERE indexzp = old.indexzp; 
  END IF;
  -----------------------------------------------------------------------------------------------------------------
  /*  section en attente : 
  on pourrait verifier le changement des 3 geom pour lancer les commandes de geometries
  car pour le moment on ne gere pas les 2 cas de changement sur le geom 2154 ou the geom
  code ci dessous a revoir car public.st_equals ne marche pas avec les objets invalid
  -- on verfie si 1 des 3 geom a changé
  IF((old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT public.st_equals(new.the_geom_3857,old.the_geom_3857))
  OR ((old.the_geom_local is null AND new.the_geom_local is NOT NULL) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local)) THEN

  -- si oui on regarde lequel et on repercute les modif :
    IF (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
      -- verif si on est en multipolygon ou pas : A FAIRE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
      new.srid_dessin = 3857; 
    ELSIF (old.the_geom_local is null AND new.the_geom_local is NOT NULL) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
      new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
      new.srid_dessin = 2154;
    END IF;
  puis suite du THEN...
  fin de section en attente */ 
  ------------------------------------------------------------------------------------------------------
  ------ gestion des infos relatives aux géométries
  ------ ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "faussement inséré" par une commande update !
  ------ POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857
  IF public.ST_NumGeometries(new.the_geom_3857)=1 THEN -- si le Multi objet renvoyé par le oueb ne contient qu'un objet
    new.the_geom_3857 = public.ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
  END IF;
  new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
  new.srid_dessin = 3857;
  -- 2) puis on calcul la validité des geom + on refait les calcul du geom_point_3857 + on refait les croisements SIG secteurs + communes ; c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
  IF public.ST_isvalid(new.the_geom_local) AND public.ST_isvalid(new.the_geom_3857) THEN
    new.topo_valid = 'true';
    -- calcul du geom_point_3857 
    new.geom_point_3857 = public.ST_pointonsurface(new.the_geom_3857); -- calcul du point pour le premier niveau de zoom appli web
    -- croisement secteur (celui qui contient le plus de zp en surface)
    SELECT INTO monsectfp ls.area_code::integer 
    FROM ref_geo.l_areas ls 
    WHERE public.st_intersects(ls.geom, new.the_geom_local) AND ls.id_type = 30
    ORDER BY public.ST_area(public.ST_intersection(ls.geom, new.the_geom_local)) DESC LIMIT 1;
    -- croisement commune (celle qui contient le plus de zp en surface)
    SELECT INTO macommune m.insee_com 
    FROM ref_geo.l_areas lc 
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
  ELSE
    new.topo_valid = 'false';
    -- calcul du geom_point_3857
    new.geom_point_3857 = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
    moncentroide = public.ST_setsrid(public.st_centroid(public.box2d(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
    -- croisement secteur (celui qui contient moncentroide)
    SELECT INTO monsectfp ls.area_code::integer  
    FROM ref_geo.l_areas ls 
    WHERE public.st_intersects(ls.geom, moncentroide)
    AND ls.id_type = 30
    ORDER BY public.ST_area(public.ST_intersection(ls.geom, moncentroide)) DESC LIMIT 1;
    -- croisement commune (celle qui contient moncentroid)
    SELECT INTO macommune m.insee_com 
    FROM ref_geo.l_areas lc 
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, moncentroide)
    AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, moncentroide)) DESC LIMIT 1;
  END IF;
  new.insee = macommune;
  IF monsectfp IS NULL THEN -- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
    new.id_secteur = 999; -- alors on met 999 (hors zone) en code secteur fp
  ELSE
    new.id_secteur = monsectfp; --sinon on met le code du secteur.
  END IF;
  ------ 3) puis calcul du geom_mixte_3857 ;c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
  IF public.ST_area(new.the_geom_3857) <10000 THEN -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
    new.geom_mixte_3857 = new.geom_point_3857;
  ELSE
    new.geom_mixte_3857 = new.the_geom_3857;
  END IF; --  fin du IF pour les traitemenst sur les geometries
  RETURN NEW; --return des valeurs
END; --fin du trigger et 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function delete_synthese_ap
CREATE OR REPLACE FUNCTION v1_florepatri.delete_synthese_ap()
  RETURNS trigger AS
$BODY$
--il n'y a pas de trigger delete sur la table t_zprospection parce qu'il y a un delete cascade dans la fk indexzp de t_apresence
--donc si on supprime la zp, on supprime sa ou ces ap et donc ce trigger sera déclanché et fera le ménage dans la table gn_synthese.synthese
DECLARE 
  mazp RECORD;
BEGIN
  --on fait le delete dans gn_synthese.synthese
  DELETE FROM gn_synthese.synthese 
  WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
  AND entity_source_pk_value = CAST(old.indexap AS VARCHAR);
	RETURN old; 			
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- Function update_synthese_cor_zp_obs
CREATE OR REPLACE FUNCTION v1_florepatri.update_synthese_cor_zp_obs()
  RETURNS trigger AS
$BODY$
DECLARE 
  mesap RECORD;
  theidsynthese INTEGER;
  theobservers VARCHAR;
BEGIN
  --Récupération de la liste des observateurs	
  --ici on va mettre à jour l'enregistrement dans synthese autant de fois qu'on insert dans cette table
  SELECT INTO theobservers array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
  FROM v1_florepatri.cor_zp_obs c
   JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
   JOIN v1_florepatri.t_zprospection zp ON zp.indexzp = c.indexzp
  WHERE c.indexzp = new.indexzp;
  --on boucle sur tous les enregistrements de la zp
  --si la zp est sans ap, la boucle ne se fait pas
  FOR mesap IN SELECT indexap FROM v1_florepatri.t_apresence WHERE supprime = false AND indexzp = new.indexzp  LOOP
    -- on récupére l'id_synthese
    SELECT INTO theidsynthese id_synthese 
    FROM gn_synthese.synthese
    WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
    AND entity_source_pk_value = mesap.indexap::varchar;
    --on fait le update du champ observateurs dans synthese
    UPDATE gn_synthese.synthese
    SET 
      observers = theobservers,
      determiner = theobservers,
      last_action = 'u'
    WHERE id_synthese = theidsynthese;
    DELETE FROM gn_synthese.cor_observer_synthese WHERE id_synthese = theidsynthese AND id_role = new.codeobs;
    INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role) VALUES(theidsynthese, new.codeobs);
  END LOOP;
  RETURN NEW; 			
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- Function insert_synthese_ap
CREATE OR REPLACE FUNCTION v1_florepatri.insert_synthese_ap()
  RETURNS trigger AS
$BODY$
DECLARE
  thezp RECORD;
  theobservers VARCHAR;
  thegeompoint public.geometry;
  thevalidationstatus INTEGER;
  thecomptagemethodo INTEGER;
  thestadevie INTEGER;
  thetaxrefversion VARCHAR;
  --theidprecision INTEGER;
BEGIN
  SELECT INTO thezp * FROM v1_florepatri.t_zprospection WHERE indexzp = new.indexzp;
  --Récupération des données dans la table t_zprospection et de la liste des observateurs 
  SELECT INTO theobservers array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
  FROM v1_florepatri.cor_zp_obs c
  JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
  JOIN v1_florepatri.t_zprospection zp ON zp.indexzp = c.indexzp
  WHERE c.indexzp = new.indexzp;
  -- création du geom_point
  IF public.ST_isvalid(new.the_geom_3857) THEN 
    thegeompoint = public.ST_pointonsurface(new.the_geom_3857);
  ELSE 
    thegeompoint = public.ST_PointFromWKB(public.st_centroid(public.box2d(new.the_geom_3857)),3857);
  END IF;
  --Récupération du statut de validation
    IF (thezp.validation) THEN 
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
    ELSE
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','0') INTO thevalidationstatus;
    END IF;
  --Récupération de la méthode de comptage
    IF (new.id_comptage_methodo=1) THEN 
	    SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Co') INTO thecomptagemethodo;
    ELSIF (new.id_comptage_methodo=2) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Ca') INTO thecomptagemethodo;
    ELSE
      SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP') INTO thecomptagemethodo;
    END IF;
  --Récupération du stade de vie
    IF (new.codepheno=1) THEN 
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','132') INTO thestadevie;
    ELSIF (new.codepheno=2) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','128') INTO thestadevie;
    ELSIF (new.codepheno=3) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','129') INTO thestadevie;
    ELSIF (new.codepheno=4) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','127') INTO thestadevie;
    ELSIF (new.codepheno=5) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','130') INTO thestadevie;
    ELSIF (new.codepheno=6) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','132') INTO thestadevie;
    ELSIF (new.codepheno=7) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','19') INTO thestadevie;
    ELSIF (new.codepheno=8) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','131') INTO thestadevie;
    ELSE
      SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','0') INTO thestadevie;
    END IF;
    --Récupération de la version taxref
    SELECT parameter_value INTO thetaxrefversion FROM gn_commons.t_parameters WHERE parameter_name = 'taxref_version';
  -- récupération de la valeur de précision de la géométrie (absent de la V2 pour le moment)
  -- IF st_geometrytype(new.the_geom_3857) = 'ST_Point' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPoint' THEN theidprecision = 1;
  -- ELSIF st_geometrytype(new.the_geom_3857) = 'ST_LineString' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiLineString' THEN theidprecision = 2;
  -- ELSIF st_geometrytype(new.the_geom_3857) = 'ST_Polygone' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPolygon' THEN theidprecision = 3;
  -- ELSE theidprecision = 12;
  -- END IF;
  -- MAJ de la table cor_unite_taxon, on commence par récupérer les zonnes à statuts à partir du pointage (table t_fiches_cf)
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
      comment_description,
      last_action
    )
    VALUES
    ( 
      new.unique_id_sinp_fp,
      thezp.unique_id_sinp_grp,
      104, -- 104 = PNE
      new.indexap,
      thezp.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      thevalidationstatus,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      thestadevie,
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      thecomptagemethodo,
      ref_nomenclatures.get_id_nomenclature('SENSIBILITE','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      new.total_steriles + new.total_fertiles,--count_min
      new.total_steriles + new.total_fertiles,--count_max
      thezp.cd_nom,
      COALESCE(thezp.taxon_saisi,'non disponible'),
      thetaxrefversion,
      new.altitude_retenue,--altitude_min
      new.altitude_retenue,--altitude_max
      public.st_transform(new.the_geom_3857,4326),
      public.st_transform(thegeompoint,4326),
      new.the_geom_local,
      thezp.dateobs,--date_min
      thezp.dateobs,--date_max
      theobservers,--observers
      theobservers,--determiner
      new.remarques,
      'c'
    );
  RETURN NEW;       
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- Function update_synthese_ap
CREATE OR REPLACE FUNCTION v1_florepatri.update_synthese_ap()
  RETURNS trigger AS
$BODY$
DECLARE
  thegeompoint public.geometry;
  thecomptagemethodo INTEGER;
  thestadevie INTEGER;
  --theidprecision integer;
BEGIN
  --On ne fait qq chose que si l'un des champs de la table t_apresence concerné dans gn_synthese.synthese a changé
  IF (
    new.indexap <> old.indexap 
    OR new.unique_id_sinp_fp <> old.unique_id_sinp_fp 
    OR new.codepheno <> old.codepheno 
    OR new.indexzp <> old.indexzp 
    OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
    OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
    OR new.id_comptage_methodo <> old.id_comptage_methodo 
    OR new.total_steriles <> old.total_steriles 
    OR new.total_fertiles <> old.total_fertiles 
    OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local))
  ) THEN
    -- création du geom_point
    IF public.ST_isvalid(new.the_geom_3857) THEN 
      thegeompoint = public.ST_pointonsurface(new.the_geom_3857);
    ELSE 
      thegeompoint = public.ST_PointFromWKB(public.st_centroid(public.box2d(new.the_geom_3857)),4326);
    END IF;
    --Récupération de la méthode de comptage
    IF (new.id_comptage_methodo=1) THEN 
      SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Co') INTO thecomptagemethodo;
    ELSIF (new.id_comptage_methodo=2) THEN
      SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Ca') INTO thecomptagemethodo;
    ELSE
      SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP') INTO thecomptagemethodo;
    END IF;
    --Récupération du stade de vie
    IF (new.codepheno=1) THEN 
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','132') INTO thestadevie;
    ELSIF (new.codepheno=2) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','128') INTO thestadevie;
    ELSIF (new.codepheno=3) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','129') INTO thestadevie;
    ELSIF (new.codepheno=4) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','127') INTO thestadevie;
    ELSIF (new.codepheno=5) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','130') INTO thestadevie;
    ELSIF (new.codepheno=6) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','132') INTO thestadevie;
    ELSIF (new.codepheno=7) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','19') INTO thestadevie;
    ELSIF (new.codepheno=8) THEN
	    SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','131') INTO thestadevie;
    ELSE
      SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE','0') INTO thestadevie;
    END IF;
    -- récupération de la valeur de précision de la géométrie
    -- IF st_geometrytype(new.the_geom_3857) = 'ST_Point' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPoint' THEN theidprecision = 1;
    -- ELSIF st_geometrytype(new.the_geom_3857) = 'ST_LineString' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiLineString' THEN theidprecision = 2;
    -- ELSIF st_geometrytype(new.the_geom_3857) = 'ST_Polygone' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPolygon' THEN theidprecision = 3;
    -- ELSE theidprecision = 12;
    -- END IF;
    --on fait le update dans synthese
    UPDATE gn_synthese.synthese
    SET 
      --id_precision = monidprecision,
      entity_source_pk_value = new.indexap,
      unique_id_sinp = new.unique_id_sinp_fp,
      id_nomenclature_type_count = thecomptagemethodo,
      id_nomenclature_life_stage = thestadevie,
      altitude_min = new.altitude_retenue,
      altitude_max = new.altitude_retenue,
      count_min = new.total_steriles + new.total_fertiles,
      count_max = new.total_steriles + new.total_fertiles,
      comment_description = new.remarques,
      meta_update_date = now(),
      last_action = 'u',
      the_geom_4326 = public.ST_transform(new.the_geom_3857,4326),
      the_geom_local = new.the_geom_local,
      the_geom_point = public.ST_transform(thegeompoint,4326)
    WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
    AND entity_source_pk_value = CAST(old.indexap AS VARCHAR);
  END IF;
  IF (new.supprime <> old.supprime AND new.supprime) THEN
    DELETE FROM gn_synthese.synthese 
    WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
    AND entity_source_pk_value = CAST(old.indexap AS VARCHAR);
  ELSIF (new.supprime <> old.supprime AND new.supprime = false) THEN
    RAISE EXCEPTION 'Recréer une aire de présence supprimée est impossible dans GeoNature 2. INDEXAP N° %', new.indexap USING HINT = 'Contactez un administrateur de la base de données';
  END IF;
  RETURN NEW;       
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION v1_florepatri.update_synthese_zp()
  RETURNS trigger AS
$BODY$
DECLARE 
  mesap RECORD;
  thevalidationstatus INTEGER;
BEGIN
  FOR mesap IN SELECT indexap FROM v1_florepatri.t_apresence WHERE supprime = true AND indexzp = new.indexzp  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_zprospection concerné dans synthese a changé
    IF (
            new.indexzp <> old.indexzp 
            OR new.validation <> old.validation 
            OR ((new.cd_nom <> old.cd_nom) OR (new.cd_nom is null and old.cd_nom is NOT NULL) OR (new.cd_nom is NOT NULL and old.cd_nom is null))
            OR ((new.taxon_saisi <> old.taxon_saisi) OR (new.taxon_saisi is null and old.taxon_saisi is NOT NULL) OR (new.taxon_saisi is NOT NULL and old.taxon_saisi is null))
            OR ((new.id_organisme <> old.id_organisme) OR (new.id_organisme is null and old.id_organisme is NOT NULL) OR (new.id_organisme is NOT NULL and old.id_organisme is null))
            OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
            OR new.supprime <> old.supprime 
        ) THEN
        --Récupération du statut de validation
        IF (new.validation) THEN 
          SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
        ELSE
          SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','0') INTO thevalidationstatus;
        END IF;
        --on fait le update dans synthese
        UPDATE gn_synthese.synthese 
        SET 
          unique_id_sinp_grp = new.unique_id_sinp_grp,
          cd_nom = new.cd_nom,
          nom_cite = new.taxon_saisi,
          id_nomenclature_valid_status = thevalidationstatus,
          date_min = new.dateobs,
          date_max = new.dateobs,
          meta_update_date = now(),
          last_action = 'u'
        WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
        AND entity_source_pk_value = CAST(mesap.indexap AS VARCHAR);
        IF(new.supprime <> old.supprime AND new.supprime) THEN
          DELETE FROM gn_synthese.synthese 
          WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ILIKE 'Flore prioritaire') 
          AND entity_source_pk_value = CAST(mesap.indexap AS VARCHAR);
        ELSIF (new.supprime <> old.supprime AND new.supprime = false) THEN
          RAISE EXCEPTION 'Recréer une aire de présence supprimée est impossible dans GeoNature 2. INDEXAP N° %', mesap.indexap USING HINT = 'Contactez un administrateur de la base de données';
        END IF;
    END IF;
  END LOOP;
	RETURN NEW; 			
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

--Création des triggers
CREATE TRIGGER tri_insert_synthese_cor_zp_obs AFTER INSERT ON v1_florepatri.cor_zp_obs FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.update_synthese_cor_zp_obs();
CREATE TRIGGER tri_delete_synthese_ap AFTER DELETE ON v1_florepatri.t_apresence FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.delete_synthese_ap();
CREATE TRIGGER tri_insert_ap BEFORE INSERT ON v1_florepatri.t_apresence FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.insert_ap();
CREATE TRIGGER tri_insert_synthese_ap AFTER INSERT ON v1_florepatri.t_apresence FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.insert_synthese_ap();
CREATE TRIGGER tri_update_ap BEFORE UPDATE ON v1_florepatri.t_apresence FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.update_ap();
CREATE TRIGGER tri_update_synthese_ap AFTER UPDATE ON v1_florepatri.t_apresence FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.update_synthese_ap();
CREATE TRIGGER tri_insert_zp BEFORE INSERT ON v1_florepatri.t_zprospection FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.insert_zp();
CREATE TRIGGER tri_update_synthese_zp AFTER UPDATE ON v1_florepatri.t_zprospection FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.update_synthese_zp();
CREATE TRIGGER tri_update_zp BEFORE UPDATE ON v1_florepatri.t_zprospection FOR EACH ROW EXECUTE PROCEDURE v1_florepatri.update_zp();

-------------
--LIENS GN2--
-------------
--Mise à jour des nomenclatures en prévision des évolutions SINP à venir
INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_fr, label_default, definition_fr, definition_default,  source, statut, id_broader, hierarchy, meta_create_date, meta_update_date, active) VALUES
(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '127', 'Pleine floraison', 'Pleine floraison', 'Pleine floraison', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.127', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
,(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '128', 'Stade boutons floraux', 'Stade boutons floraux', 'Stade boutons floraux', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.128', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
,(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '129', 'Début de floraison', 'Début de floraison', 'Début de floraison', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.129', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
,(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '130', 'Fin de floraison, avec éventuellement maturation des fruits', 'Fin de floraison, avec éventuellement maturation des fruits', 'Fin de floraison, avec éventuellement maturation des fruits', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.130', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
,(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '131', 'Stade végétatif', 'Stade végétatif', 'Stade végétatif', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.131', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
,(ref_nomenclatures.get_id_nomenclature_type('STADE_VIE'), '132', 'Dissémination', 'Dissémination', 'Dissémination', 'TODO.', 'TODO.', 'SINP', 'Non validé', 0, '010.132', '2019-07-04 16:00:0', '2019-07-04 16:00:0', true)
;
UPDATE ref_nomenclatures.t_nomenclatures 
SET 
  mnemonique = 'Décrépitude', 
  label_fr = 'Décrépitude', 
  label_default = 'Décrépitude' 
WHERE cd_nomenclature = '19' AND id_type = ref_nomenclatures.get_id_nomenclature_type('STADE_VIE');
UPDATE ref_nomenclatures.t_nomenclatures 
SET 
  definition_fr = 'La graine déjà disséminée est la structure qui contient et protège l''embryon végétal.',
  definition_default = 'La graine déjà disséminée est la structure qui contient et protège l''embryon végétal.'
WHERE cd_nomenclature = '20' AND id_type = ref_nomenclatures.get_id_nomenclature_type('STADE_VIE');

--suppression du terme PDA dans la liste des observateurs
UPDATE utilisateurs.t_listes SET nom_liste = 'Observateurs flore prioritaire' WHERE nom_liste ILIKE 'PDA_observateurs';
--Création du module
DELETE FROM gn_commons.t_modules WHERE module_code = 'FP';
INSERT INTO gn_commons.t_modules (module_code, module_label, module_picto, module_path, module_external_url, module_target, active_backend, active_frontend) 
VALUES ('FP','Flore Prioritaire','fa-leaf-heart',NULL,'https://mondomaine.fr/pda','_blank', false, false);
--gestion des permissions (TODO car cette requête ne fait rien)
INSERT INTO gn_permissions.cor_object_module (id_object, id_module)
SELECT o.id_object, t.id_module
FROM gn_permissions.t_objects o, gn_commons.t_modules t
WHERE o.code_object = 'TDatasets' AND t.module_code = 'FP';


-------------------------------------
--RECUPERATION DES DONNEES DE LA V1--
-------------------------------------
-- ALTER TABLE v1_florepatri.t_apresence ADD COLUMN diffusable boolean;
-- ALTER TABLE v1_florepatri.t_apresence ALTER COLUMN diffusable SET DEFAULT true;

ALTER TABLE v1_florepatri.t_zprospection DISABLE TRIGGER tri_insert_zp;
ALTER TABLE v1_florepatri.t_zprospection DISABLE TRIGGER tri_update_synthese_zp;
ALTER TABLE v1_florepatri.t_zprospection DISABLE TRIGGER tri_update_zp;
ALTER TABLE v1_florepatri.t_apresence DISABLE TRIGGER tri_delete_synthese_ap;
ALTER TABLE v1_florepatri.t_apresence DISABLE TRIGGER tri_insert_ap;
ALTER TABLE v1_florepatri.t_apresence DISABLE TRIGGER tri_insert_synthese_ap;
ALTER TABLE v1_florepatri.t_apresence DISABLE TRIGGER tri_update_ap;
ALTER TABLE v1_florepatri.t_apresence DISABLE TRIGGER tri_update_synthese_ap;
ALTER TABLE v1_florepatri.cor_zp_obs DISABLE TRIGGER tri_insert_synthese_cor_zp_obs;

INSERT INTO v1_florepatri.bib_comptages_methodo SELECT * FROM v1_compat.bib_comptages_methodo;
INSERT INTO v1_florepatri.bib_frequences_methodo_new SELECT * FROM v1_compat.bib_frequences_methodo_new;
INSERT INTO v1_florepatri.bib_pentes SELECT * FROM v1_compat.bib_pentes;
INSERT INTO v1_florepatri.bib_perturbations SELECT * FROM v1_compat.bib_perturbations;
INSERT INTO v1_florepatri.bib_phenologies SELECT * FROM v1_compat.bib_phenologies;
INSERT INTO v1_florepatri.bib_physionomies SELECT * FROM v1_compat.bib_physionomies;
INSERT INTO v1_florepatri.bib_rezo_ecrins SELECT * FROM v1_compat.bib_rezo_ecrins;
INSERT INTO v1_florepatri.bib_statuts SELECT * FROM v1_compat.bib_statuts;
INSERT INTO v1_florepatri.bib_taxons_fp SELECT * FROM v1_compat.bib_taxons_fp;
INSERT INTO v1_florepatri.t_zprospection (
  indexzp,
  id_secteur,
  id_protocole,
  id_lot,
  id_organisme,
  dateobs,
  date_insert,
  date_update,
  validation,
  topo_valid,
  erreur_signalee,
  supprime,
  cd_nom,
  saisie_initiale,
  insee,
  taxon_saisi,
  the_geom_local,
  geom_point_3857,
  geom_mixte_3857,
  srid_dessin,
  the_geom_3857,
  id_rezo_ecrins
) 
SELECT 
  indexzp,
  id_secteur,
  id_protocole,
  id_lot,
  id_organisme,
  dateobs,
  date_insert,
  date_update,
  validation,
  topo_valid,
  erreur_signalee,
  supprime,
  cd_nom,
  saisie_initiale,
  insee,
  taxon_saisi,
  the_geom_local,
  geom_point_3857,
  geom_mixte_3857,
  srid_dessin,
  the_geom_3857,
  id_rezo_ecrins 
FROM v1_compat.t_zprospection;

INSERT INTO v1_florepatri.t_apresence (
  indexap,
  codepheno,
  indexzp,
  altitude_saisie,
  surfaceap,
  frequenceap,
  date_insert,
  date_update,
  topo_valid,
  supprime,
  erreur_signalee,
  diffusable,
  altitude_sig,
  altitude_retenue,
  insee,
  id_frequence_methodo_new ,
  nb_transects_frequence,
  nb_points_frequence,
  nb_contacts_frequence ,
  id_comptage_methodo,
  nb_placettes_comptage,
  surface_placette_comptage,
  remarques,
  the_geom_local,
  the_geom_3857,
  longueur_pas,
  effectif_placettes_steriles,
  effectif_placettes_fertiles,
  total_steriles,
  total_fertiles
)
SELECT 
  indexap,
  codepheno,
  indexzp,
  altitude_saisie,
  surfaceap,
  frequenceap,
  date_insert,
  date_update,
  topo_valid,
  supprime,
  erreur_signalee,
  diffusable,
  altitude_sig,
  altitude_retenue,
  insee,
  id_frequence_methodo_new ,
  nb_transects_frequence,
  nb_points_frequence,
  nb_contacts_frequence ,
  id_comptage_methodo,
  nb_placettes_comptage,
  surface_placette_comptage,
  remarques,
  the_geom_local,
  the_geom_3857,
  longueur_pas,
  effectif_placettes_steriles,
  effectif_placettes_fertiles,
  total_steriles,
  total_fertiles
FROM v1_compat.t_apresence;
INSERT INTO v1_florepatri.cor_zp_obs SELECT * FROM v1_compat.cor_zp_obs;
INSERT INTO v1_florepatri.cor_taxon_statut SELECT * FROM v1_compat.cor_taxon_statut;
INSERT INTO v1_florepatri.cor_ap_physionomie SELECT * FROM v1_compat.cor_ap_physionomie;
INSERT INTO v1_florepatri.cor_ap_perturb SELECT * FROM v1_compat.cor_ap_perturb;

--SET UUID FOR SYNTHESE
ALTER TABLE v1_florepatri.t_zprospection ADD COLUMN unique_id_sinp_grp uuid;
UPDATE v1_florepatri.t_zprospection SET unique_id_sinp_grp = public.uuid_generate_v4();
ALTER TABLE v1_florepatri.t_zprospection ALTER COLUMN unique_id_sinp_grp SET NOT NULL;
ALTER TABLE v1_florepatri.t_zprospection ALTER COLUMN unique_id_sinp_grp SET DEFAULT public.uuid_generate_v4();

ALTER TABLE v1_florepatri.t_apresence ADD COLUMN unique_id_sinp_fp uuid;
UPDATE v1_florepatri.t_apresence SET unique_id_sinp_fp = public.uuid_generate_v4();
ALTER TABLE v1_florepatri.t_apresence ALTER COLUMN unique_id_sinp_fp SET NOT NULL;
ALTER TABLE v1_florepatri.t_apresence ALTER COLUMN unique_id_sinp_fp SET DEFAULT public.uuid_generate_v4();

-- Convertion d'un multipoint en point
-- Erreur dans le script mais pas d'erreur si exécuté hors du script !
UPDATE v1_florepatri.t_apresence SET 
  the_geom_local = (SELECT (public.st_dump(the_geom_local)).geom FROM v1_florepatri.t_apresence WHERE indexap = 406197584),
  the_geom_3857 = (SELECT (public.st_dump(the_geom_3857)).geom FROM v1_florepatri.t_apresence WHERE indexap = 406197584)
WHERE indexap = 406197584;

ALTER TABLE v1_florepatri.t_zprospection ENABLE TRIGGER tri_insert_zp;
ALTER TABLE v1_florepatri.t_zprospection ENABLE TRIGGER tri_update_synthese_zp;
ALTER TABLE v1_florepatri.t_zprospection ENABLE TRIGGER tri_update_zp;
ALTER TABLE v1_florepatri.t_apresence ENABLE TRIGGER tri_delete_synthese_ap;
ALTER TABLE v1_florepatri.t_apresence ENABLE TRIGGER tri_insert_ap;
ALTER TABLE v1_florepatri.t_apresence ENABLE TRIGGER tri_insert_synthese_ap;
ALTER TABLE v1_florepatri.t_apresence ENABLE TRIGGER tri_update_ap;
ALTER TABLE v1_florepatri.t_apresence ENABLE TRIGGER tri_update_synthese_ap;
ALTER TABLE v1_florepatri.cor_zp_obs ENABLE TRIGGER tri_insert_synthese_cor_zp_obs;

--INSERT Polygons dans la synthese
INSERT INTO gn_synthese.synthese
    (
      unique_id_sinp,
      unique_id_sinp_grp,
      id_source,
      id_module,
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
      validator,
      observers,
      determiner,
      comment_context,
      comment_description,
      meta_create_date,
      meta_update_date,
      last_action
    )
 SELECT
      ap.unique_id_sinp_fp,
      zp.unique_id_sinp_grp,
      104, -- 104 = PNE
      (SELECT id_module FROM gn_commons.t_modules WHERE module_code = '4' LIMIT 1),
      ap.indexap,
      zp.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      CASE 
        WHEN zp.validation=true THEN ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1')
        WHEN zp.validation=false THEN ref_nomenclatures.get_id_nomenclature('STATUT_VALID','0')
      END,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      CASE 
        WHEN ap.codepheno=1 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','132')
        WHEN ap.codepheno=2 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','128')
        WHEN ap.codepheno=3 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','129')
        WHEN ap.codepheno=4 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','127')
        WHEN ap.codepheno=5 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','130')
        WHEN ap.codepheno=6 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','132')
        WHEN ap.codepheno=7 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','19')
        WHEN ap.codepheno=8 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','131')
        ELSE ref_nomenclatures.get_id_nomenclature('STADE_VIE','0')
      END,
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      CASE 
        WHEN ap.id_comptage_methodo=1 THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Co')
        WHEN ap.id_comptage_methodo=2 THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Ca')
        ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP')
      END,
      ref_nomenclatures.get_id_nomenclature('SENSIBILITE','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      ap.total_steriles + ap.total_fertiles,--count_min
      ap.total_steriles + ap.total_fertiles,--count_max
      zp.cd_nom,
      COALESCE(zp.taxon_saisi,'non disponible'),
      'Taxref V11.0',
      ap.altitude_retenue,--altitude_min
      ap.altitude_retenue,--altitude_max
      public.st_transform(public.st_buffer(ap.the_geom_3857,0),4326),
      public.st_transform(public.st_pointonsurface(public.st_buffer(ap.the_geom_3857,0)),4326),
      public.st_buffer(ap.the_geom_local, 0),
      zp.dateobs,--date_min
      zp.dateobs,--date_max
      'Cédric Dentant',
      array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', '),--observers
      array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', '),--determiner
      zp.saisie_initiale,
      ap.remarques,
      ap.date_insert,
      ap.date_update,
      CASE 
        WHEN ap.date_insert = ap.date_update THEN 'c'
        ELSE 'u'
      END
  FROM v1_florepatri.t_apresence ap
  JOIN v1_florepatri.t_zprospection zp ON zp.indexzp = ap.indexzp 
  LEFT JOIN v1_florepatri.cor_zp_obs c  ON c.indexzp = zp.indexzp
  LEFT JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
  WHERE ap.supprime = false
  AND public.st_geometrytype(ap.the_geom_local) = 'ST_Polygon'
  GROUP BY
      ap.unique_id_sinp_fp,
      zp.unique_id_sinp_grp,
      ap.indexap,
      zp.id_lot,
      zp.validation,
      ap.codepheno,
      ap.id_comptage_methodo,
      ap.total_fertiles,
      ap.total_steriles,
      zp.cd_nom,
      zp.taxon_saisi,
      zp.saisie_initiale,
      ap.altitude_retenue,
      ap.the_geom_3857,
      ap.the_geom_local,
      zp.dateobs,
      ap.remarques,
      zp.saisie_initiale,
      ap.date_insert,
      ap.date_update;

INSERT INTO gn_synthese.synthese
    (
      unique_id_sinp,
      unique_id_sinp_grp,
      id_source,
      id_module,
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
      validator,
      observers,
      determiner,
      comment_context,
      comment_description,
      meta_create_date,
      meta_update_date,
      last_action
    )
 SELECT
      ap.unique_id_sinp_fp,
      zp.unique_id_sinp_grp,
      104, -- 104 = PNE
      (SELECT id_module FROM gn_commons.t_modules WHERE module_code = '4' LIMIT 1),
      ap.indexap,
      zp.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      CASE 
        WHEN zp.validation=true THEN ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1')
        WHEN zp.validation=false THEN ref_nomenclatures.get_id_nomenclature('STATUT_VALID','0')
      END,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      CASE 
        WHEN ap.codepheno=1 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','132')
        WHEN ap.codepheno=2 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','128')
        WHEN ap.codepheno=3 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','129')
        WHEN ap.codepheno=4 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','127')
        WHEN ap.codepheno=5 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','130')
        WHEN ap.codepheno=6 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','132')
        WHEN ap.codepheno=7 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','19')
        WHEN ap.codepheno=8 THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE','131')
        ELSE ref_nomenclatures.get_id_nomenclature('STADE_VIE','0')
      END,
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      CASE 
        WHEN ap.id_comptage_methodo=1 THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Co')
        WHEN ap.id_comptage_methodo=2 THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Ca')
        ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP')
      END,
      ref_nomenclatures.get_id_nomenclature('SENSIBILITE','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      ap.total_steriles + ap.total_fertiles,--count_min
      ap.total_steriles + ap.total_fertiles,--count_max
      zp.cd_nom,
      COALESCE(zp.taxon_saisi,'non disponible'),
      'Taxref V11.0',
      ap.altitude_retenue,--altitude_min
      ap.altitude_retenue,--altitude_max
      public.st_transform(ap.the_geom_3857,4326),
      public.st_transform(public.st_pointonsurface(ap.the_geom_3857),4326),
      ap.the_geom_local,
      zp.dateobs,--date_min
      zp.dateobs,--date_max
      'Cédric Dentant',
      array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', '),--observers
      array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', '),--determiner
      zp.saisie_initiale,
      ap.remarques,
      ap.date_insert,
      ap.date_update,
      CASE 
        WHEN ap.date_insert = ap.date_update THEN 'c'
        ELSE 'u'
      END
  FROM v1_florepatri.t_apresence ap
  JOIN v1_florepatri.t_zprospection zp ON zp.indexzp = ap.indexzp 
  LEFT JOIN v1_florepatri.cor_zp_obs c  ON c.indexzp = zp.indexzp
  LEFT JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
  WHERE ap.supprime = false
  AND public.st_geometrytype(ap.the_geom_local) IN('ST_LineString','ST_Point')
  GROUP BY
      ap.unique_id_sinp_fp,
      zp.unique_id_sinp_grp,
      ap.indexap,
      zp.id_lot,
      zp.validation,
      ap.codepheno,
      ap.id_comptage_methodo,
      ap.total_fertiles,
      ap.total_steriles,
      zp.cd_nom,
      zp.taxon_saisi,
      zp.saisie_initiale,
      ap.altitude_retenue,
      ap.the_geom_3857,
      ap.the_geom_local,
      zp.dateobs,
      ap.remarques,
      zp.saisie_initiale,
      ap.date_insert,
      ap.date_update;
-- insertion des observateurs dans cor_observer_synthese
INSERT INTO gn_synthese.cor_observer_synthese
  SELECT s.id_synthese, c.codeobs
  FROM v1_florepatri.t_apresence ap
  JOIN v1_florepatri.cor_zp_obs c ON c.indexzp = ap.indexzp
  JOIN gn_synthese.synthese s ON s.entity_source_pk_value::bigint = ap.indexap AND id_source = 104;
