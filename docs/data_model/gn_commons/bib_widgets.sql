
\restrict eFBRmvfr4RSIorDYMcM1g7olp0mMUuS0vxfo9fSEtg36aNRyeHqf4vgREhtN1ep

CREATE TABLE gn_commons.bib_widgets (
    id_widget integer NOT NULL,
    widget_name character varying(50) NOT NULL
);

CREATE SEQUENCE gn_commons.bib_widgets_id_widget_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.bib_widgets_id_widget_seq OWNED BY gn_commons.bib_widgets.id_widget;

ALTER TABLE ONLY gn_commons.bib_widgets
    ADD CONSTRAINT pk_bib_widgets PRIMARY KEY (id_widget);

\unrestrict eFBRmvfr4RSIorDYMcM1g7olp0mMUuS0vxfo9fSEtg36aNRyeHqf4vgREhtN1ep

