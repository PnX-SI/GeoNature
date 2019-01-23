-- Depuis la version 2.0.0-rc.4, on ne stocke plus les modules de GeoNature dans utilisateurs.t_applications, 
-- utilisé par les modules de suivi (Flore, habitat, chiro)
-- On ne peut donc plus associer les sites de suivi de gn_monitoring à des applications
-- Le mécanisme est remplacé par une association des sites de suivi aux modules

CREATE TABLE gn_monitoring.cor_site_module (
  id_base_site integer NOT NULL,
  id_module integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_site_module
    ADD CONSTRAINT pk_cor_site_module PRIMARY KEY (id_base_site, id_module);

ALTER TABLE ONLY gn_monitoring.cor_site_module
  ADD CONSTRAINT fk_cor_site_module_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_site_module
  ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module);

-- Récupération des données à gérer au cas par cas
-- Si vous aviez des données dans la table gn_monitoring.cor_site_application, 
-- il est nécessaire de les migrer manuellement dans gn_monitoring.cor_site_module

-- TODO : Supprimer l'ancienne table gn_monitoring.cor_site_application dans la prochaine release
