  DELETE FROM taxonomie.cor_nom_liste;
  DELETE FROM taxonomie.bib_noms;
  ALTER TABLE taxonomie.cor_nom_liste DISABLE TRIGGER trg_refresh_mv_taxref_list_forautocomplete;

  INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
  SELECT cd_nom, cd_ref, nom_vern
  FROM taxonomie.taxref
  WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
     'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR');

  INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
  SELECT 100,n.id_nom FROM taxonomie.bib_noms n;

  INSERT INTO taxonomie.vm_taxref_list_forautocomplete
SELECT t.cd_nom,
  t.cd_ref,
  t.search_name,
  t.nom_valide,
  t.lb_nom,
  t.regne,
  t.group2_inpn,
  cnl.id_liste
FROM (

  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_nom , ']') AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  UNION
 
  SELECT DISTINCT 
        t_1.cd_nom,
        t_1.cd_ref,
        concat(n.nom_francais, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_ref , ']' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  JOIN taxonomie.bib_noms n ON t_1.cd_nom = n.cd_ref AND n.nom_francais IS NOT null
) t

JOIN taxonomie.bib_noms n ON n.cd_nom = t.cd_nom OR n.cd_ref = t.cd_ref
JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom;


  ALTER TABLE taxonomie.cor_nom_liste ENABLE TRIGGER tri_maj_cor_area_taxon;
