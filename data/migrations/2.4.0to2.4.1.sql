-- Ajout d'une colonne "id_area_attachment" dans la table "gn_synthese.synthese" pour les occurrences sans géométrie précise
ALTER TABLE gn_synthese.synthese ADD COLUMN id_area_attachment integer;
ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_area_attachment FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas (id_area) ON UPDATE CASCADE;

COMMENT ON COLUMN gn_synthese.synthese.id_area_attachment
  IS 'Id area du rattachement géographique - cas des observation sans géométrie précise';

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment CHECK (NOT (ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type) = '2'  AND id_area_attachment IS NULL )) NOT VALID;

-- Ajout d'une colonne "geojson_4326" dans le ref_geo
ALTER TABLE ref_geo.l_areas 
ADD COLUMN geojson_4326 character varying;

-- Calcul du champs "geojson_4326" à partir de la géométrie des zonages
UPDATE ref_geo.l_areas
SET geojson_4326 = public.ST_asgeojson(public.st_transform(geom, 4326));

-- Création d'une fonction et d'un trigger calulant automatiquement le champs "geojson_4326" à partir de la géométrie des zonages
CREATE OR REPLACE FUNCTION ref_geo.fct_tri_calculate_geojson() 
   RETURNS trigger AS
  $BODY$
    BEGIN
      NEW.geojson_4326 = public.ST_asgeojson(public.st_transform(NEW.geom, 4326));
      RETURN NEW;
    END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS tri_calculate_geojson ON ref_geo.l_areas;
CREATE TRIGGER tri_calculate_geojson
    BEFORE INSERT OR UPDATE OF geom ON ref_geo.l_areas
    FOR EACH ROW
    EXECUTE PROCEDURE ref_geo.fct_tri_calculate_geojson();
