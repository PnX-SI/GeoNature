
CREATE TABLE gn_permissions.bib_actions (
    id_action integer NOT NULL,
    code_action character varying(50) NOT NULL,
    description_action text
);

CREATE SEQUENCE gn_permissions.t_actions_id_action_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_permissions.t_actions_id_action_seq OWNED BY gn_permissions.bib_actions.id_action;

ALTER TABLE ONLY gn_permissions.bib_actions
    ADD CONSTRAINT pk_t_actions PRIMARY KEY (id_action);

