-- DELETE CASCADE ON DS AND AF
-- cor module dataset
alter table gn_commons.cor_module_dataset 
drop  constraint fk_cor_module_dataset_id_module;
alter table gn_commons.cor_module_dataset 
drop  constraint fk_cor_module_dataset_id_dataset;

alter table gn_commons.cor_module_dataset 
add constraint fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE cascade on delete cascade,
add constraint fk_cor_module_dataset_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE cascade on delete cascade;

-- cor dataset actor
ALTER TABLE ONLY gn_meta.cor_dataset_actor
drop  constraint fk_cor_dataset_actor_id_dataset;
ALTER TABLE ONLY gn_meta.cor_dataset_actor
drop  constraint fk_dataset_actor_id_role;

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT fk_cor_dataset_actor_id_dataset FOREIGN KEY (id_dataset)
     REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_dataset_actor_id_role FOREIGN KEY (id_role) 
     REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE
;

-- territory
ALTER TABLE ONLY gn_meta.cor_dataset_territory
drop  constraint fk_cor_dataset_territory_id_dataset;
ALTER TABLE ONLY gn_meta.cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset) 
    REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;


-- protocol
ALTER TABLE ONLY gn_meta.cor_dataset_protocol
drop  constraint fk_cor_dataset_protocol_id_dataset;
ALTER TABLE ONLY gn_meta.cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset) 
    REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;


-- AF
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
drop  constraint fk_cor_acquisition_framework_objectif_id_acquisition_framework;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) 
    REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
drop  constraint fk_cor_acquisition_framework_actor_id_acquisition_framework;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) 
    REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
drop  constraint fk_cor_acquisition_framework_actor_id_role;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_role FOREIGN KEY (id_role) 
    REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
drop  constraint fk_cor_acquisition_framework_actor_id_organism;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_organism FOREIGN KEY (id_organism) 
    REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
drop  constraint fk_cor_acquisition_framework_voletsinp_id_acquisition_framework;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) 
    REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
drop  constraint fk_cor_acquisition_framework_publication_id_publication;
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_publication FOREIGN KEY (id_acquisition_framework) 
    REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;
