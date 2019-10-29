DELETE FROM ref_habitat.bib_list_habitat WHERE liste_name = 'Liste test occhab'
INSERT INTO ref_habitat.bib_list_habitat(list_name) VALUES ('Liste test occhab');

DELETE FROM ref_habitat.cor_list_habitat 
WHERE id_list IN (
  select id_list FROM ref_habitat.bib_list_habitat WHERE list_name = 'Liste test occhab'
  );

INSERT INTO ref_habitat.cor_list_habitat(id_list, cd_hab) 
SELECT b.id_list, cd_hab
FROM ref_habitat.habref h, ref_habitat.bib_list_habitat b
WHERE h.cd_typo IN (1,2,3,4,5,6,7) and b.list_name = 'Liste test occhab'
order by cd_hab;

SELECT pg_catalog.setval('ref_habitat.bib_list_habitat_id_list_seq', (SELECT max(id_list)+1 FROM ref_habitat.bib_list_habitat), true);

