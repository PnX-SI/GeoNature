--Permet la suppression d'enregistrements en synthese sans bloquage
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_synthese;
ALTER TABLE gn_synthese.cor_area_synthese
  ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese)
      REFERENCES gn_synthese.synthese (id_synthese) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;
