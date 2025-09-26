
\restrict JB4HtZB7qkFjV0j1EruhmgqJD9wWb8r6q1jPAdNycamGFYdy2rDLNIbIK5YJfz9

CREATE TABLE ref_habitats.typoref_fields (
    cd_hab_field integer NOT NULL,
    cd_typo integer NOT NULL,
    lb_hab_field character varying(30) NOT NULL,
    format_hab_field character varying(200),
    descript_hab_field character varying(3000),
    ordre_hab_field integer,
    length_hab_field integer,
    lb_label character varying(200),
    date_crea text,
    date_modif text
);

ALTER TABLE ONLY ref_habitats.typoref_fields
    ADD CONSTRAINT pk_typoref_fields PRIMARY KEY (cd_hab_field);

\unrestrict JB4HtZB7qkFjV0j1EruhmgqJD9wWb8r6q1jPAdNycamGFYdy2rDLNIbIK5YJfz9

