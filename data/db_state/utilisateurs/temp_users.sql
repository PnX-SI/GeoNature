
CREATE TABLE utilisateurs.temp_users (
    id_temp_user integer NOT NULL,
    token_role text,
    organisme character varying(250),
    id_application integer NOT NULL,
    confirmation_url character varying(250),
    groupe boolean DEFAULT false NOT NULL,
    identifiant character varying(100),
    nom_role character varying(50),
    prenom_role character varying(50),
    desc_role text,
    pass_md5 text,
    password text,
    email character varying(250),
    id_organisme integer,
    remarques text,
    champs_addi jsonb,
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);

CREATE SEQUENCE utilisateurs.temp_users_id_temp_user_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.temp_users_id_temp_user_seq OWNED BY utilisateurs.temp_users.id_temp_user;

ALTER TABLE ONLY utilisateurs.temp_users
    ADD CONSTRAINT pk_temp_users PRIMARY KEY (id_temp_user);

CREATE TRIGGER tri_modify_date_insert_temp_roles BEFORE INSERT ON utilisateurs.temp_users FOR EACH ROW EXECUTE FUNCTION utilisateurs.modify_date_insert();

ALTER TABLE ONLY utilisateurs.temp_users
    ADD CONSTRAINT temp_user_id_application_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY utilisateurs.temp_users
    ADD CONSTRAINT temp_user_id_organisme_fkey FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;

