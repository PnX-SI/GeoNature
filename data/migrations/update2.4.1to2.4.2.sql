
--MET 22/07/2020 Table t_places pour la fonctionnalité mes-lieux
CREATE TABLE gn_commons.t_places
(
    id_role integer NOT NULL,
    place_name character varying(100),
	  place_geom geometry,
      CONSTRAINT pk_t_places PRIMARY KEY (id_role,place_name),
      CONSTRAINT t_places_id_role_fkey FOREIGN KEY (id_role)
          REFERENCES utilisateurs.t_roles (id_role) MATCH SIMPLE
          ON UPDATE CASCADE
          ON DELETE CASCADE
);
