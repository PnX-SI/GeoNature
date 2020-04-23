
------------------------------------------------
------------------------------------------------
--Alter existing constraints
------------------------------------------------
------------------------------------------------

ALTER TABLE taxonomie.bib_noms DROP CONSTRAINT fk_bib_nom_taxref;
ALTER TABLE taxonomie.taxref_protection_especes DROP CONSTRAINT taxref_protection_especes_cd_nom_fkey;

ALTER TABLE taxonomie.t_medias DROP CONSTRAINT check_cd_ref_is_ref;
ALTER TABLE taxonomie.bib_noms DROP CONSTRAINT check_is_valid_cd_ref;
ALTER TABLE taxonomie.cor_taxon_attribut DROP CONSTRAINT check_is_cd_ref;


UPDATE taxonomie.taxref t
   SET id_statut = fr, id_habitat = it.habitat::int, id_rang = it.rang, regne = it.regne, phylum = it.phylum, 
       classe = it.classe, ordre = it.ordre, famille = it.famille, cd_taxsup = it.cd_taxsup,
       cd_sup = it.cd_sup, cd_ref = it.cd_ref, 
       lb_nom = it.lb_nom, lb_auteur = it.lb_auteur, nom_complet = it.nom_complet,
       nom_complet_html = it.nom_complet_html, nom_valide = it.nom_valide, 
       nom_vern = it.nom_vern, nom_vern_eng = it.nom_vern_eng, group1_inpn = it.group1_inpn,
       group2_inpn = it.group2_inpn, sous_famille = it.sous_famille, 
       tribu = it.tribu, url = it.url
FROM taxonomie.import_taxref it
WHERE it.cd_nom  = t.cd_nom;

INSERT INTO taxonomie.taxref(
            cd_nom, id_statut, id_habitat, id_rang, regne, phylum, classe, 
            ordre, famille, cd_taxsup, cd_sup, cd_ref, lb_nom, lb_auteur, 
            nom_complet, nom_complet_html, nom_valide, nom_vern, nom_vern_eng, 
            group1_inpn, group2_inpn, sous_famille, tribu, url)
SELECT it.cd_nom, it.fr, it.habitat::int, it.rang, it.regne, it.phylum, it.classe,
    it.ordre, it.famille, it.cd_taxsup, it.cd_sup, it.cd_ref, it.lb_nom, it.lb_auteur,
    it.nom_complet, it.nom_complet_html, it.nom_valide, it.nom_vern, it.nom_vern_eng,
    it.group1_inpn, it.group2_inpn, it.sous_famille, it.tribu, it.url
FROM taxonomie.import_taxref it
LEFT OUTER JOIN taxonomie.taxref t
ON it.cd_nom = t.cd_nom
WHERE t.cd_nom IS NULL;

-- DELETE MISSING CD_NOM
DELETE FROM taxonomie.taxref 
WHERE cd_nom IN (
	SELECT t.cd_nom
	FROM taxonomie.taxref t
	LEFT OUTER JOIN taxonomie.import_taxref it
	ON it.cd_nom = t.cd_nom
	WHERE it.cd_nom IS NULL
);


------------------------------------------------
------------------------------------------------
-- REBUILD CONSTAINTS
------------------------------------------------
------------------------------------------------

ALTER TABLE taxonomie.bib_noms
  ADD CONSTRAINT fk_bib_nom_taxref FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE taxonomie.t_medias
  ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref));
  
ALTER TABLE taxonomie.bib_noms
  ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref));

ALTER TABLE taxonomie.cor_taxon_attribut
  ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref));
