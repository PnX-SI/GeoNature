
CREATE TABLE utilisateurs.t_roles (
    groupe boolean DEFAULT false NOT NULL,
    id_role integer NOT NULL,
    uuid_role uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    identifiant character varying(100),
    nom_role character varying(50),
    prenom_role character varying(50),
    desc_role text,
    pass character varying(100),
    pass_plus text,
    email character varying(250),
    id_organisme integer,
    remarques text,
    active boolean DEFAULT true,
    champs_addi jsonb,
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);

CREATE SEQUENCE utilisateurs.t_roles_id_role_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.t_roles_id_role_seq OWNED BY utilisateurs.t_roles.id_role;

ALTER TABLE ONLY utilisateurs.t_roles
    ADD CONSTRAINT pk_t_roles PRIMARY KEY (id_role);

ALTER TABLE ONLY utilisateurs.t_roles
    ADD CONSTRAINT t_roles_uuid_un UNIQUE (uuid_role);

CREATE INDEX i_utilisateurs_active ON utilisateurs.t_roles USING btree (active);

CREATE INDEX i_utilisateurs_groupe ON utilisateurs.t_roles USING btree (groupe);

CREATE INDEX i_utilisateurs_nom_prenom ON utilisateurs.t_roles USING btree (nom_role, prenom_role);

CREATE TRIGGER tri_modify_date_insert_t_roles BEFORE INSERT ON utilisateurs.t_roles FOR EACH ROW EXECUTE FUNCTION utilisateurs.modify_date_insert();

CREATE TRIGGER tri_modify_date_update_t_roles BEFORE UPDATE ON utilisateurs.t_roles FOR EACH ROW EXECUTE FUNCTION utilisateurs.modify_date_update();

ALTER TABLE ONLY utilisateurs.t_roles
    ADD CONSTRAINT t_roles_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

