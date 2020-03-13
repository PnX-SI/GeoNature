UPDATE ref_geo.l_areas
SET enable = false where id_area IN (
  SELECT a.id_area
  FROM ref_geo.l_areas a
  JOIN ref_geo.li_municipalities m ON m.id_area = a.id_area
  WHERE m.insee_reg != :CODE_INSEE_REG::character varying
);