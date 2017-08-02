SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA meta;

SET search_path = meta, pg_catalog;


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


CREATE TABLE bib_nomenclatures_relations (
    id_nomenclature_l integer NOT NULL,
    id_nomenclature_r integer NOT NULL,
    type_relation character varying(250) NOT NULL
);


CREATE TABLE bib_types_nomenclatures (
    id_type_nomenclature integer NOT NULL,
    mnemonique character varying(255) NOT NULL,
    libelle_type_nomenclature character varying(255),
    definition_type_nomenclature text,
    statut_type_nomenclature character varying(20),
    date_create timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone DEFAULT now()
);
COMMENT ON TABLE bib_types_nomenclatures IS 'Description de la liste des nomenclatures du SINP.';


CREATE TABLE cor_role_droit_entite (
    id_role integer NOT NULL,
    id_droit integer NOT NULL,
    nom_entite character varying(255) NOT NULL
);
COMMENT ON TABLE cor_role_droit_entite IS 'Permet de gérer les droits d''un groupe ou d''un utilisateur sur les différentes entités (tables) gérées par le backoffice (CRUD selon droits).';


CREATE TABLE cor_role_lot_application (
    id_role integer NOT NULL,
    id_lot integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_role_lot_application IS 'Permet d''identifier pour chaque module GeoNature (un module = 1 application dans UsersHub) parmi quels lots l''utilisateur logué peut rattacher ses observations. Rappel : un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Un backoffice de geonature V2 permet une gestion des lots.';


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
COMMENT ON TABLE t_lots IS 'Un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Le lot permet de qualifier les données auxquelles il se rapporte (producteur, propriétaire, gestionnaire, financeur, donnée publique oui/non). Un lot peut être rattaché à un programme. Un backoffice de geonature V2 permet une gestion des lots.';

CREATE SEQUENCE t_nomenclatures_id_nomenclature_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_nomenclatures_id_nomenclature_seq OWNED BY t_nomenclatures.id_nomenclature;


CREATE TABLE t_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    actif boolean
);
COMMENT ON TABLE t_programmes IS 'Les programmes sont des objets généraux pouvant englober des lots de données et/ou des protocoles (à discuter pour les protocoles). Exemple : ATBI, rapaces, plan national d''action, etc... Un backoffice de geonature V2 permet une gestion des programmes.';
ALTER TABLE ONLY t_nomenclatures ALTER COLUMN id_nomenclature SET DEFAULT nextval('t_nomenclatures_id_nomenclature_seq'::regclass);

---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_pkey PRIMARY KEY (id_nomenclature_l, id_nomenclature_r, type_relation);

ALTER TABLE ONLY bib_types_nomenclatures
    ADD CONSTRAINT bib_types_nomenclatures_pkey PRIMARY KEY (id_type_nomenclature);

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_pkey PRIMARY KEY (id_role, id_droit, nom_entite);

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_pkey PRIMARY KEY (id_role, id_lot, id_application);

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT t_lots_pkey PRIMARY KEY (id_lot);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_pkey PRIMARY KEY (id_nomenclature);

ALTER TABLE ONLY t_programmes
    ADD CONSTRAINT t_programmes_pkey PRIMARY KEY (id_programme);


---------
--INDEX--
---------
CREATE INDEX fki_t_nomenclatures_bib_types_nomenclatures_fkey ON t_nomenclatures USING btree (id_type_nomenclature);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_id_nomenclature_l_fkey FOREIGN KEY (id_nomenclature_l) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY bib_nomenclatures_relations
    ADD CONSTRAINT bib_nomenclatures_relations_id_nomenclature_r_fkey FOREIGN KEY (id_nomenclature_r) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_application_id_droit_fkey FOREIGN KEY (id_droit) REFERENCES utilisateurs.bib_droits(id_droit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_droit_application_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_t_roles_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_application_fkey FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_droit_fkey FOREIGN KEY (id_lot) REFERENCES t_lots(id_lot) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_financeur FOREIGN KEY (id_organisme_financeur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_gestionnaire FOREIGN KEY (id_organisme_gestionnaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_producteur FOREIGN KEY (id_organisme_producteur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_proprietaire FOREIGN KEY (id_organisme_proprietaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_t_programmes FOREIGN KEY (id_programme) REFERENCES t_programmes(id_programme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_id_type_nomenclature_fkey FOREIGN KEY (id_type_nomenclature) REFERENCES bib_types_nomenclatures(id_type_nomenclature) ON UPDATE CASCADE;


---------
--DATAS--
---------
INSERT INTO t_programmes VALUES (1, 'faune', 'programme faune', true);
INSERT INTO t_programmes VALUES (2, 'flore', 'programme flore', true);