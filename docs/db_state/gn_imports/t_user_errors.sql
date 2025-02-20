
CREATE TABLE gn_imports.t_user_errors (
    id_user_error integer NOT NULL,
    id_import integer NOT NULL,
    id_error integer NOT NULL,
    column_error character varying(100) NOT NULL,
    id_rows integer[],
    comment text,
    id_entity integer
);

CREATE SEQUENCE gn_imports.t_user_error_list_id_user_error_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_user_error_list_id_user_error_seq OWNED BY gn_imports.t_user_errors.id_user_error;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT pk_t_user_error_list PRIMARY KEY (id_user_error);

CREATE UNIQUE INDEX t_user_errors_entity_un ON gn_imports.t_user_errors USING btree (id_import, id_entity, id_error, column_error) WHERE (id_entity IS NOT NULL);

CREATE UNIQUE INDEX t_user_errors_un ON gn_imports.t_user_errors USING btree (id_import, id_error, column_error) WHERE (id_entity IS NULL);

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT fk_t_user_error_list_id_error FOREIGN KEY (id_error) REFERENCES gn_imports.bib_errors_types(id_error) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT fk_t_user_error_list_id_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT t_user_errors_id_entity_fkey FOREIGN KEY (id_entity) REFERENCES gn_imports.bib_entities(id_entity) ON UPDATE CASCADE ON DELETE CASCADE;

