--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.5.7

-- Started on 2017-06-22 20:01:18 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 11 (class 2615 OID 135936)
-- Name: meta; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA meta;


SET search_path = meta, pg_catalog;

--
-- TOC entry 300 (class 1255 OID 135937)
-- Name: check_type_nomenclature(integer, integer); Type: FUNCTION; Schema: meta; Owner: -
--

CREATE FUNCTION check_type_nomenclature(id integer, id_type integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--fonction permettant de vérifier si un id_nomenclature correspond au type de nomenclature souhaité
  BEGIN
    IF id IN(SELECT id_nomenclature FROM meta.t_nomenclatures WHERE id_type_nomenclature = id_type ) THEN
      return true;
    ELSE
      RETURN false;
    END IF;
  END;
$$;


--
-- TOC entry 301 (class 1255 OID 135938)
-- Name: get_filtered_nomenclature(integer, character varying, character varying); Type: FUNCTION; Schema: meta; Owner: -
--

CREATE FUNCTION get_filtered_nomenclature(idtype integer, myregne character varying, mygroup character varying) RETURNS SETOF integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--fonction permettant de retourner une liste d'id_nomenclature selon le regne et/ou le group2_inpn transmis en paramètre.
  DECLARE
    thegroup character varying(255);
    theregne character varying(255);
    r integer;

BEGIN
  thegroup = NULL;
  theregne = NULL;

  IF mygroup IS NOT NULL THEN
      SELECT INTO thegroup DISTINCT group2_inpn 
      FROM taxonomie.cor_taxref_nomenclature ctn
      JOIN meta.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type_nomenclature = idtype
      AND group2_inpn = mygroup;
  END IF;

  IF myregne IS NOT NULL THEN
    SELECT INTO theregne DISTINCT regne 
    FROM taxonomie.cor_taxref_nomenclature ctn
    JOIN meta.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
    WHERE n.id_type_nomenclature = idtype
    AND regne = myregne;
  END IF;

  IF theregne IS NOT NULL THEN 
    IF thegroup IS NOT NULL THEN
      FOR r IN 
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN meta.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type_nomenclature = idtype
        AND regne = theregne
        AND group2_inpn = mygroup
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    ELSE
      FOR r IN 
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN meta.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type_nomenclature = idtype
        AND regne = theregne
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    END IF;
  ELSE
    FOR r IN 
      SELECT DISTINCT ctn.id_nomenclature
      FROM taxonomie.cor_taxref_nomenclature ctn
      JOIN meta.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type_nomenclature = idtype
    LOOP
      RETURN NEXT r;
    END LOOP;
    RETURN;
  END IF;
END;
$$;


SET default_with_oids = false;

--
-- TOC entry 234 (class 1259 OID 135939)
-- Name: t_nomenclatures; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE t_nomenclatures (
    id_nomenclature integer NOT NULL,
    id_type_nomenclature integer,
    cd_nomenclature character varying(255) NOT NULL,
    mnemonique character varying(255) NOT NULL,
    libelle_nomenclature character varying(255),
    definition_nomenclature text,
    source character varying(255),
    statut_nomenclature character varying(20),
    id_parent integer,
    hierarchie character varying(255),
    date_create timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone,
    actif boolean NOT NULL DEFAULT true
);


--
-- TOC entry 235 (class 1259 OID 135946)
-- Name: bib_nomenclatures_relations; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE bib_nomenclatures_relations (
    id_nomenclature_l integer NOT NULL,
    id_nomenclature_r integer NOT NULL,
    type_relation character varying(250) NOT NULL
);


--
-- TOC entry 237 (class 1259 OID 135951)
-- Name: bib_types_nomenclatures; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE bib_types_nomenclatures (
    id_type_nomenclature integer NOT NULL,
    mnemonique character varying(255) NOT NULL,
    libelle_type_nomenclature character varying(255),
    definition_type_nomenclature text,
    statut_type_nomenclature character varying(20),
    date_create timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone DEFAULT now()
);


--
-- TOC entry 3713 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE bib_types_nomenclatures; Type: COMMENT; Schema: meta; Owner: -
--

COMMENT ON TABLE bib_types_nomenclatures IS 'Description de la liste des nomenclatures du SINP.';


--
-- TOC entry 238 (class 1259 OID 135959)
-- Name: cor_role_droit_entite; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE cor_role_droit_entite (
    id_role integer NOT NULL,
    id_droit integer NOT NULL,
    nom_entite character varying(255) NOT NULL
);


--
-- TOC entry 3714 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE cor_role_droit_entite; Type: COMMENT; Schema: meta; Owner: -
--

COMMENT ON TABLE cor_role_droit_entite IS 'Permet de gérer les droits d''un groupe ou d''un utilisateur sur les différentes entités (tables) gérées par le backoffice (CRUD selon droits).';


--
-- TOC entry 239 (class 1259 OID 135962)
-- Name: cor_role_lot_application; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE cor_role_lot_application (
    id_role integer NOT NULL,
    id_lot integer NOT NULL,
    id_application integer NOT NULL
);


--
-- TOC entry 3715 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE cor_role_lot_application; Type: COMMENT; Schema: meta; Owner: -
--

COMMENT ON TABLE cor_role_lot_application IS 'Permet d''identifier pour chaque module GeoNature (un module = 1 application dans UsersHub) parmi quels lots l''utilisateur logué peut rattacher ses observations. Rappel : un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Un backoffice de geonature V2 permet une gestion des lots.';


--
-- TOC entry 240 (class 1259 OID 135965)
-- Name: t_lots; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE t_lots (
    id_lot integer NOT NULL,
    nom_lot character varying(255),
    desc_lot text,
    id_programme integer NOT NULL,
    id_organisme_proprietaire integer NOT NULL,
    id_organisme_producteur integer NOT NULL,
    id_organisme_gestionnaire integer NOT NULL,
    id_organisme_financeur integer NOT NULL,
    donnees_publiques boolean DEFAULT true NOT NULL,
    validite_par_defaut boolean,
    date_create timestamp without time zone,
    date_update timestamp without time zone
);


--
-- TOC entry 3716 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE t_lots; Type: COMMENT; Schema: meta; Owner: -
--

COMMENT ON TABLE t_lots IS 'Un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Le lot permet de qualifier les données auxquelles il se rapporte (producteur, propriétaire, gestionnaire, financeur, donnée publique oui/non). Un lot peut être rattaché à un programme. Un backoffice de geonature V2 permet une gestion des lots.';


--
-- TOC entry 241 (class 1259 OID 135972)
-- Name: t_nomenclatures_id_nomenclature_seq; Type: SEQUENCE; Schema: meta; Owner: -
--

CREATE SEQUENCE t_nomenclatures_id_nomenclature_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3717 (class 0 OID 0)
-- Dependencies: 241
-- Name: t_nomenclatures_id_nomenclature_seq; Type: SEQUENCE OWNED BY; Schema: meta; Owner: -
--

ALTER SEQUENCE t_nomenclatures_id_nomenclature_seq OWNED BY t_nomenclatures.id_nomenclature;


--
-- TOC entry 242 (class 1259 OID 135974)
-- Name: t_programmes; Type: TABLE; Schema: meta; Owner: -
--

CREATE TABLE t_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    actif boolean
);


--
-- TOC entry 3718 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE t_programmes; Type: COMMENT; Schema: meta; Owner: -
--

COMMENT ON TABLE t_programmes IS 'Les programmes sont des objets généraux pouvant englober des lots de données et/ou des protocoles (à discuter pour les protocoles). Exemple : ATBI, rapaces, plan national d''action, etc... Un backoffice de geonature V2 permet une gestion des programmes.';


--
-- TOC entry 3550 (class 2604 OID 135980)
-- Name: id_nomenclature; Type: DEFAULT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_nomenclatures ALTER COLUMN id_nomenclature SET DEFAULT nextval('t_nomenclatures_id_nomenclature_seq'::regclass);


--
-- TOC entry 3558 (class 2606 OID 135982)
-- Name: bib_nomenclatures_relations_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_pkey PRIMARY KEY (id_nomenclature_l, id_nomenclature_r, type_relation);


--
-- TOC entry 3560 (class 2606 OID 135984)
-- Name: bib_types_nomenclatures_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_types_nomenclatures
    ADD CONSTRAINT bib_types_nomenclatures_pkey PRIMARY KEY (id_type_nomenclature);


--
-- TOC entry 3562 (class 2606 OID 135986)
-- Name: cor_role_droit_entite_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_pkey PRIMARY KEY (id_role, id_droit, nom_entite);


--
-- TOC entry 3564 (class 2606 OID 135988)
-- Name: cor_role_lot_application_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_pkey PRIMARY KEY (id_role, id_lot, id_application);


--
-- TOC entry 3566 (class 2606 OID 135990)
-- Name: t_lots_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT t_lots_pkey PRIMARY KEY (id_lot);


--
-- TOC entry 3556 (class 2606 OID 135992)
-- Name: t_nomenclatures_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_pkey PRIMARY KEY (id_nomenclature);


--
-- TOC entry 3568 (class 2606 OID 135994)
-- Name: t_programmes_pkey; Type: CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_programmes
    ADD CONSTRAINT t_programmes_pkey PRIMARY KEY (id_programme);


--
-- TOC entry 3554 (class 1259 OID 135995)
-- Name: fki_t_nomenclatures_bib_types_nomenclatures_fkey; Type: INDEX; Schema: meta; Owner: -
--

CREATE INDEX fki_t_nomenclatures_bib_types_nomenclatures_fkey ON t_nomenclatures USING btree (id_type_nomenclature);


--
-- TOC entry 3571 (class 2606 OID 135996)
-- Name: bib_nomenclatures_relations_id_nomenclature_l_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_id_nomenclature_l_fkey FOREIGN KEY (id_nomenclature_l) REFERENCES t_nomenclatures(id_nomenclature);


--
-- TOC entry 3572 (class 2606 OID 136001)
-- Name: bib_nomenclatures_relations_id_nomenclature_r_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_id_nomenclature_r_fkey FOREIGN KEY (id_nomenclature_r) REFERENCES t_nomenclatures(id_nomenclature);


--
-- TOC entry 3573 (class 2606 OID 136006)
-- Name: cor_role_droit_application_id_droit_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_application_id_droit_fkey FOREIGN KEY (id_droit) REFERENCES utilisateurs.bib_droits(id_droit) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3575 (class 2606 OID 136011)
-- Name: cor_role_droit_application_id_role_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_droit_application_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3574 (class 2606 OID 136016)
-- Name: cor_role_droit_entite_t_roles_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_t_roles_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3576 (class 2606 OID 136021)
-- Name: cor_role_lot_application_id_application_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_application_fkey FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3577 (class 2606 OID 136026)
-- Name: cor_role_lot_application_id_droit_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_droit_fkey FOREIGN KEY (id_lot) REFERENCES t_lots(id_lot) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3578 (class 2606 OID 136031)
-- Name: fk_bib_lots_financeur; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_financeur FOREIGN KEY (id_organisme_financeur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3579 (class 2606 OID 136036)
-- Name: fk_bib_lots_gestionnaire; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_gestionnaire FOREIGN KEY (id_organisme_gestionnaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3580 (class 2606 OID 136041)
-- Name: fk_bib_lots_producteur; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_producteur FOREIGN KEY (id_organisme_producteur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3581 (class 2606 OID 136046)
-- Name: fk_bib_lots_proprietaire; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_proprietaire FOREIGN KEY (id_organisme_proprietaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3582 (class 2606 OID 136051)
-- Name: fk_bib_lots_t_programmes; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_t_programmes FOREIGN KEY (id_programme) REFERENCES t_programmes(id_programme) ON UPDATE CASCADE;


--
-- TOC entry 3569 (class 2606 OID 136056)
-- Name: t_nomenclatures_id_parent_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES t_nomenclatures(id_nomenclature);


--
-- TOC entry 3570 (class 2606 OID 136061)
-- Name: t_nomenclatures_id_type_nomenclature_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_id_type_nomenclature_fkey FOREIGN KEY (id_type_nomenclature) REFERENCES bib_types_nomenclatures(id_type_nomenclature) ON UPDATE CASCADE;


-- Completed on 2017-06-22 20:01:18 CEST

--
-- PostgreSQL database dump complete
--

