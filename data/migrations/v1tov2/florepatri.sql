
CREATE SCHEMA v1_florepatri;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = v1_florepatri, pg_catalog;

CREATE OR REPLACE FUNCTION letypedegeom(mongeom public.geometry)
  RETURNS character varying AS
$BODY$
DECLARE
thetype varchar(18);
montype varchar(15);
BEGIN
select st_geometrytype(mongeom) into thetype;
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

SET default_with_oids = false;

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

-------------------------------------
--RECUPERATION DES DONNEES DE LA V1--
-------------------------------------
ALTER TABLE v1_florepatri.t_apresence ADD COLUMN diffusable boolean;
ALTER TABLE v1_florepatri.t_apresence ALTER COLUMN diffusable SET DEFAULT true;

INSERT INTO v1_florepatri.bib_comptages_methodo
SELECT * FROM v1_compat.bib_comptages_methodo;

INSERT INTO v1_florepatri.bib_frequences_methodo_new
SELECT * FROM v1_compat.bib_frequences_methodo_new;

INSERT INTO v1_florepatri.bib_pentes
SELECT * FROM v1_compat.bib_pentes;

INSERT INTO v1_florepatri.bib_perturbations
SELECT * FROM v1_compat.bib_perturbations;

INSERT INTO v1_florepatri.bib_phenologies
SELECT * FROM v1_compat.bib_phenologies;

INSERT INTO v1_florepatri.bib_physionomies
SELECT * FROM v1_compat.bib_physionomies;

INSERT INTO v1_florepatri.bib_rezo_ecrins
SELECT * FROM v1_compat.bib_rezo_ecrins;

INSERT INTO v1_florepatri.bib_statuts
SELECT * FROM v1_compat.bib_statuts;

INSERT INTO v1_florepatri.bib_taxons_fp
SELECT * FROM v1_compat.bib_taxons_fp;

INSERT INTO v1_florepatri.t_zprospection
SELECT * FROM v1_compat.t_zprospection;

INSERT INTO v1_florepatri.t_apresence
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

INSERT INTO v1_florepatri.cor_zp_obs
SELECT * FROM v1_compat.cor_zp_obs;

INSERT INTO v1_florepatri.cor_taxon_statut
SELECT * FROM v1_compat.cor_taxon_statut;

INSERT INTO v1_florepatri.cor_ap_physionomie
SELECT * FROM v1_compat.cor_ap_physionomie;

INSERT INTO v1_florepatri.cor_ap_perturb
SELECT * FROM v1_compat.cor_ap_perturb;
