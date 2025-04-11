
CREATE TABLE ref_geo.cor_linear_group (
    id_group integer NOT NULL,
    id_linear integer NOT NULL
);

ALTER TABLE ONLY ref_geo.cor_linear_group
    ADD CONSTRAINT pk_ref_geo_cor_linear_group PRIMARY KEY (id_group, id_linear);

ALTER TABLE ONLY ref_geo.cor_linear_group
    ADD CONSTRAINT fk_ref_geo_cor_linear_group_id_group FOREIGN KEY (id_group) REFERENCES ref_geo.t_linear_groups(id_group) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ref_geo.cor_linear_group
    ADD CONSTRAINT fk_ref_geo_cor_linear_group_id_linear FOREIGN KEY (id_linear) REFERENCES ref_geo.l_linears(id_linear) ON UPDATE CASCADE ON DELETE CASCADE;

