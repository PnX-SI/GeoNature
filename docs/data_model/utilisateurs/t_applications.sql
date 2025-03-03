
CREATE TABLE utilisateurs.t_applications (
    id_application integer NOT NULL,
    code_application character varying(20) NOT NULL,
    nom_application character varying(50) NOT NULL,
    desc_application text,
    id_parent integer
);

CREATE SEQUENCE utilisateurs.t_applications_id_application_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.t_applications_id_application_seq OWNED BY utilisateurs.t_applications.id_application;

ALTER TABLE ONLY utilisateurs.t_applications
    ADD CONSTRAINT pk_t_applications PRIMARY KEY (id_application);

ALTER TABLE ONLY utilisateurs.t_applications
    ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

