
CREATE TABLE gn_synthese.t_reports (
    id_report integer NOT NULL,
    id_synthese integer NOT NULL,
    id_role integer NOT NULL,
    id_type integer,
    content character varying NOT NULL,
    creation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted boolean DEFAULT false
);

CREATE SEQUENCE gn_synthese.t_reports_id_report_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_synthese.t_reports_id_report_seq OWNED BY gn_synthese.t_reports.id_report;

ALTER TABLE ONLY gn_synthese.t_reports
    ADD CONSTRAINT t_reports_pkey PRIMARY KEY (id_report);

ALTER TABLE ONLY gn_synthese.t_reports
    ADD CONSTRAINT fk_report_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_synthese.t_reports
    ADD CONSTRAINT fk_report_synthese FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_synthese.t_reports
    ADD CONSTRAINT fk_report_type FOREIGN KEY (id_type) REFERENCES gn_synthese.bib_reports_types(id_type) ON UPDATE CASCADE ON DELETE CASCADE;

