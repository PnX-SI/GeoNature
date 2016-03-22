-- IMPORTANT ! LIRE AVANT D'EXECUTER CE CODE --
--Modification des identifiants des listes pour compatibilité avec les applications GeoNature Mobile
--Dans GeoNature Mobile, les taxons sont filtrables par classe sur la base d'un id_classe. Ces id sont inscrits en dur dans le code des applications mobiles. 
--Dans la base GeoNature les classes taxonomiques sont configurables grace au vues v_nomade_classes qui utilisent les listes (taxonomie.bib_listes)
--Les id_liste ont donc été mis à jour pour être compatibles avec les id_classe des applications mobiles
--ATTENTION, le script ci-dessous permet de rentre compatible votre base avec geonature mobile sur la base des id_liste livrées avec la base.
--Si vous avez modifié les id_liste dans votre base GeoNature après son installation, vous ne devez pas exécuter ce script. 
--Vous pouvez vous en inspirer mais soyez vigilant.
--Si vous n'utilisez pas les applications GeoNature Mobile, vous pouvez laisser id_liste d'origine.
--ATENTION à ne lancer ce script d'update qu'une seule fois.
--Il est conseillé de lancer les instructions sql d'update ligne par ligne et de vérifier que les id_liste à mettre à jour correspondent bien à ceux de votre base.
--Les liens d'intégrité doivent mettre à jour les tables contactfaune.cor_critere_liste, taxonomie.cor_taxon_liste

UPDATE taxonomie.bib_liste set id_liste = id_liste + 10000; --gestion des conflits sur la clé primaire
DELETE FROM taxonomie.bib_liste WHERE id_liste = 11000; --Plantes vasculaires
DELETE FROM taxonomie.bib_liste WHERE id_liste = 10400; --Champignons
UPDATE taxonomie.bib_liste set id_liste = 1001 WHERE id_liste = 10001; --faune vertébré
UPDATE taxonomie.bib_liste set id_liste = 1002 WHERE id_liste = 10002; --faune invertébré
UPDATE taxonomie.bib_liste set id_liste = 1003 WHERE id_liste = 10003; --flore
UPDATE taxonomie.bib_liste set id_liste = 1004 WHERE id_liste = 11004; --fonge
UPDATE taxonomie.bib_liste set id_liste = 301 WHERE id_liste = 11001; --Bryophytes
UPDATE taxonomie.bib_liste set id_liste = 302 WHERE id_liste = 11002; --Lichens
UPDATE taxonomie.bib_liste set id_liste = 303 WHERE id_liste = 11003; --Algues
UPDATE taxonomie.bib_liste set id_liste = 1 WHERE id_liste = 10101; --Amphibiens
UPDATE taxonomie.bib_liste set id_liste = 7 WHERE id_liste = 10102; --Pycnogonides
UPDATE taxonomie.bib_liste set id_liste = 3 WHERE id_liste = 10103; --Entognathes
UPDATE taxonomie.bib_liste set id_liste = 4 WHERE id_liste = 10104; --Echinodermes
UPDATE taxonomie.bib_liste set id_liste = 5 WHERE id_liste = 10105; --Ecrevisses
UPDATE taxonomie.bib_liste set id_liste = 9 WHERE id_liste = 10106; --Insectes
UPDATE taxonomie.bib_liste set id_liste = 11 WHERE id_liste = 10107; --Mammifères
UPDATE taxonomie.bib_liste set id_liste = 12 WHERE id_liste = 10108; --Oiseaux
UPDATE taxonomie.bib_liste set id_liste = 13 WHERE id_liste = 10109; --Poissons
UPDATE taxonomie.bib_liste set id_liste = 14 WHERE id_liste = 10110; --Reptiles
UPDATE taxonomie.bib_liste set id_liste = 15 WHERE id_liste = 10111; --Myriapodes
UPDATE taxonomie.bib_liste set id_liste = 16 WHERE id_liste = 10112; --Arachnides
UPDATE taxonomie.bib_liste set id_liste = 101 WHERE id_liste = 10113; --Mollusques
UPDATE taxonomie.bib_liste set id_liste = 2 WHERE id_liste = 10114; --Vers
UPDATE taxonomie.bib_liste set id_liste = 20 WHERE id_liste = 10115; --Rotifères
UPDATE taxonomie.bib_liste set id_liste = 21 WHERE id_liste = 10116; --Tardigrades
UPDATE taxonomie.bib_liste set id_liste = 10 WHERE id_liste = 10201; --Bivalves
UPDATE taxonomie.bib_liste set id_liste = 8 WHERE id_liste = 10202; --Gastéropodes
UPDATE taxonomie.bib_liste set nom_liste = 'Crustacés' WHERE id_liste = 10105; --Ecrevisses

CREATE OR REPLACE VIEW contactfaune.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste = ANY (ARRAY[1, 11, 12, 13, 14])
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;

CREATE OR REPLACE VIEW contactinv.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste = ANY (ARRAY[2, 5, 8, 9, 10, 15, 16])
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text <> 'Chordata'::text AND t.regne::text = 'Animalia'::text;
  
CREATE OR REPLACE VIEW florepatri.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste > 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;

CREATE OR REPLACE VIEW taxonomie.v_nomade_classes AS 
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM contactfaune.v_nomade_classes
UNION
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM contactinv.v_nomade_classes
UNION
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM florepatri.v_nomade_classes;
   
CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
 SELECT DISTINCT t.nom_francais,
    txr.lb_nom AS nom_latin,
    f2.bool AS patrimonial,
    f3.bool AS protection_stricte,
    txr.cd_ref,
    txr.cd_nom,
    txr.nom_valide,
    txr.famille,
    txr.ordre,
    txr.classe,
    txr.regne,
    prot.protections,
    l.id_liste,
    l.picto
   FROM taxonomie.taxref txr
     JOIN taxonomie.bib_taxons t ON txr.cd_nom = t.cd_nom
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN taxonomie.bib_listes l ON l.id_liste = ctl.id_liste AND (l.id_liste = ANY (ARRAY[1001, 1002, 1003, 1004]))
     LEFT JOIN ( SELECT tpe.cd_nom,
            string_agg((((tpa.arrete || ' '::text) || tpa.article::text) || '__'::text) || tpa.url::text, '#'::text) AS protections
           FROM taxonomie.taxref_protection_especes tpe
             JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
          GROUP BY tpe.cd_nom) prot ON prot.cd_nom = t.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = t.filtre2::text
     JOIN cor_boolean f3 ON f3.expression::text = t.filtre3::text
     JOIN ( SELECT DISTINCT syntheseff.cd_nom
           FROM synthese.syntheseff
          WHERE syntheseff.supprime = false) s ON s.cd_nom = t.cd_nom
  ORDER BY t.nom_francais;