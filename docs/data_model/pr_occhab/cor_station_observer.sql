
CREATE TABLE pr_occhab.cor_station_observer (
    id_cor_station_observer integer NOT NULL,
    id_station integer NOT NULL,
    id_role integer NOT NULL
);

CREATE SEQUENCE pr_occhab.cor_station_observer_id_cor_station_observer_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.cor_station_observer_id_cor_station_observer_seq OWNED BY pr_occhab.cor_station_observer.id_cor_station_observer;

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT pk_cor_station_observer PRIMARY KEY (id_cor_station_observer);

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT unique_cor_station_observer UNIQUE (id_station, id_role);

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT fk_cor_station_observer_id_station FOREIGN KEY (id_station) REFERENCES pr_occhab.t_stations(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT fk_cor_station_observer_t_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

