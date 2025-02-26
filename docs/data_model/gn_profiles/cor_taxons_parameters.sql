
CREATE TABLE gn_profiles.cor_taxons_parameters (
    cd_nom integer NOT NULL,
    spatial_precision integer,
    temporal_precision_days integer,
    active_life_stage boolean DEFAULT false
);

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters
    ADD CONSTRAINT pk_taxons_parameters PRIMARY KEY (cd_nom);

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters
    ADD CONSTRAINT fk_cor_taxons_parameters_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

