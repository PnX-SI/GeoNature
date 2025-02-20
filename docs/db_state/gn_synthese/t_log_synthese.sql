
CREATE TABLE gn_synthese.t_log_synthese (
    id_synthese integer NOT NULL,
    last_action character(1) NOT NULL,
    meta_last_action_date timestamp without time zone DEFAULT now()
);

CREATE SEQUENCE gn_synthese.t_log_synthese_id_synthese_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_synthese.t_log_synthese_id_synthese_seq OWNED BY gn_synthese.t_log_synthese.id_synthese;

ALTER TABLE ONLY gn_synthese.t_log_synthese
    ADD CONSTRAINT t_log_synthese_pkey PRIMARY KEY (id_synthese);

