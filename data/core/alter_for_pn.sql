--Table centralisant les customisations propre aux structures de type parc nationaux

ALTER TABLE ref_geo.li_municipalities ADD COLUMN zc boolean;
ALTER TABLE ref_geo.li_municipalities ADD COLUMN aa boolean;
ALTER TABLE ref_geo.li_municipalities ADD COLUMN pec boolean;
ALTER TABLE ref_geo.li_municipalities ADD COLUMN apa boolean;
ALTER TABLE ref_geo.li_municipalities ADD COLUMN massif character varying(50);
ALTER TABLE ref_geo.li_municipalities ADD COLUMN arrondisst character varying(50);



ALTER TABLE ref_geo.li_grids ADD zc boolean;
ALTER TABLE ref_geo.li_grids ADD code_maille_10k character varying(20);
