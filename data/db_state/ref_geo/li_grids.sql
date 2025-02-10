
CREATE TABLE ref_geo.li_grids (
    id_grid character varying(50) NOT NULL,
    id_area integer NOT NULL,
    cxmin integer,
    cxmax integer,
    cymin integer,
    cymax integer
);

ALTER TABLE ONLY ref_geo.li_grids
    ADD CONSTRAINT pk_li_grids PRIMARY KEY (id_grid);

CREATE INDEX index_li_grids_id_area ON ref_geo.li_grids USING btree (id_area);

ALTER TABLE ONLY ref_geo.li_grids
    ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ON DELETE CASCADE;

