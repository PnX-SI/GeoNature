
CREATE TABLE utilisateurs.cor_profil_for_app (
    id_profil integer NOT NULL,
    id_application integer NOT NULL
);

COMMENT ON TABLE utilisateurs.cor_profil_for_app IS 'Permet d''attribuer et limiter les profils disponibles pour chacune des applications';

ALTER TABLE ONLY utilisateurs.cor_profil_for_app
    ADD CONSTRAINT pk_cor_profil_for_app PRIMARY KEY (id_application, id_profil);

ALTER TABLE ONLY utilisateurs.cor_profil_for_app
    ADD CONSTRAINT fk_cor_profil_for_app_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY utilisateurs.cor_profil_for_app
    ADD CONSTRAINT fk_cor_profil_for_app_id_profil FOREIGN KEY (id_profil) REFERENCES utilisateurs.t_profils(id_profil) ON UPDATE CASCADE;

