
/*MET 14/09/2020 Table t_places pour la fonctionnalité mes-lieux*/
CREATE TABLE gn_commons.t_places
(
    id_place serial,
    id_role integer NOT NULL,
    place_name character varying(100),
	place_geom geometry
);

COMMENT ON COLUMN gn_commons.t_places.id_place IS 'Clé primaire autoincrémente de la table t_places';
COMMENT ON COLUMN gn_commons.t_places.id_role IS 'Clé étrangère vers la table utilisateurs.t_roles, chaque lieu est associé à un utilisateur';
COMMENT ON COLUMN gn_commons.t_places.place_name IS 'Nom du lieu';
COMMENT ON COLUMN gn_commons.t_places.place_geom IS 'Géométrie du lieu';

ALTER TABLE ONLY gn_commons.t_places
    ADD CONSTRAINT pk_t_places PRIMARY KEY (id_place);
	
ALTER TABLE ONLY gn_commons.t_places
  ADD CONSTRAINT fk_t_places_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;