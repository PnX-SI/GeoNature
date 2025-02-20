
CREATE TABLE utilisateurs.cor_role_app_profil (
    id_role integer NOT NULL,
    id_application integer NOT NULL,
    id_profil integer NOT NULL,
    is_default_group_for_app boolean DEFAULT false NOT NULL
);

COMMENT ON TABLE utilisateurs.cor_role_app_profil IS 'Cette table centrale, permet d''associer des roles à des profils par application';

ALTER TABLE utilisateurs.cor_role_app_profil
    ADD CONSTRAINT check_is_default_group_for_app_is_grp_and_unique CHECK (utilisateurs.check_is_default_group_for_app_is_grp_and_unique(id_application, id_role, is_default_group_for_app)) NOT VALID;

ALTER TABLE ONLY utilisateurs.cor_role_app_profil
    ADD CONSTRAINT pk_cor_role_app_profil PRIMARY KEY (id_role, id_application, id_profil);

ALTER TABLE ONLY utilisateurs.cor_role_app_profil
    ADD CONSTRAINT fk_cor_role_app_profil_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY utilisateurs.cor_role_app_profil
    ADD CONSTRAINT fk_cor_role_app_profil_id_profil FOREIGN KEY (id_profil) REFERENCES utilisateurs.t_profils(id_profil) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY utilisateurs.cor_role_app_profil
    ADD CONSTRAINT fk_cor_role_app_profil_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

