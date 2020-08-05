UPDATE ref_geo.l_areas 
SET enable = false 
WHERE NOT geom && (select st_extent(l.geom)
from ref_geo.l_areas l 
join ref_geo.li_municipalities li ON l.id_area = li.id_area
where insee_reg = :CODE_INSEE_REG::character varying);