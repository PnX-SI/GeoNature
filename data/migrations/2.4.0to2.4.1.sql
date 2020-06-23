ALTER TABLE gn_synthese.synthese ADD COLUMN id_area_attachment integer;
ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_area_attachment FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas (id_area) ON UPDATE CASCADE;

COMMENT ON COLUMN gn_synthese.synthese.id_area_attachment
  IS 'Id area du rattachement géographique - cas des observation sans géométrie précise';

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment CHECK (NOT (ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type) = '2'  AND id_area_attachment IS NULL )) NOT VALID;


-- ajout d'une colonne 4326 dans le ref_geo
ALTER TABLE ref_geo.l_areas 
ADD COLUMN geojson character varying;

UPDATE ref_geo.l_areas
SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326));