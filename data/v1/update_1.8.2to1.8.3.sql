------------------------------------------------------------------------------------
--Mise à jour d'une vue pouvent provoquer un blocage de l'ouverture de la synthèse--
------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS (
         SELECT n.id_nom,
            t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
                CASE
                    WHEN n.nom_francais IS NULL THEN t_1.lb_nom
                    WHEN n.nom_francais::text = ''::text THEN t_1.lb_nom
                    ELSE n.nom_francais
                END AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
             LEFT JOIN taxonomie.bib_noms n ON n.cd_nom = t_1.cd_nom
          WHERE (t_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
                   FROM synthese.syntheseff))
        ), cd_regne AS (
         SELECT DISTINCT t_1.cd_nom,
            t_1.regne
           FROM taxonomie.taxref t_1
          WHERE t_1.id_rang = 'KD'::bpchar AND t_1.cd_nom = t_1.cd_ref
        )
 SELECT t.id_nom,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref'::character varying) AS nom_famille
   FROM ( SELECT DISTINCT t_1.id_nom,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE r.regne::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre,
            f.cd_nom AS id_famille,
            t_1.famille AS nom_famille
           FROM taxon t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang = 'PH'::bpchar AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang = 'CL'::bpchar AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang = 'OR'::bpchar AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
             LEFT JOIN taxonomie.taxref f ON f.id_rang = 'FM'::bpchar AND f.cd_nom = f.cd_ref AND f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL) t;


-------------
--Nettoyage--
-------------

DROP TABLE IF EXISTS utilisateurs.bib_observateurs;


-----------------------------------------------------------------
--Index spatiaux gist manquants (amélioration des performances)--
-----------------------------------------------------------------

CREATE INDEX index_gist_l_communes_the_geom
  ON layers.l_communes
  USING gist
  (the_geom);

CREATE INDEX index_gist_l_unites_geo_the_geom
  ON layers.l_unites_geo
  USING gist
  (the_geom);

CREATE INDEX index_gist_l_secteurs_the_geom
  ON layers.l_secteurs
  USING gist
  (the_geom);

CREATE INDEX index_gist_l_zonesstatut_the_geom
  ON layers.l_zonesstatut
  USING gist
  (the_geom);

CREATE INDEX index_gist_l_aireadhesion_the_geom
  ON layers.l_aireadhesion
  USING gist
  (the_geom);

CREATE INDEX index_gist_l_isolines20_the_geom
  ON layers.l_isolines20
  USING gist
  (the_geom);

CREATE INDEX index_gist_synthese_the_geom_2154
  ON synthese.syntheseff
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_synthese_the_geom_3857
  ON synthese.syntheseff
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_stations_bryo_the_geom_2154
  ON bryophytes.t_stations_bryo
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_stations_bryo_the_geom_3857
  ON bryophytes.t_stations_bryo
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_fiches_cf_the_geom_2154
  ON contactfaune.t_fiches_cf
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_fiches_cf_the_geom_3857
  ON contactfaune.t_fiches_cf
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_fiches_cflore_the_geom_2154
  ON contactflore.t_fiches_cflore
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_fiches_cflore_the_geom_3857
  ON contactflore.t_fiches_cflore
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_fiches_inv_the_geom_2154
  ON contactinv.t_fiches_inv
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_fiches_inv_the_geom_3857
  ON contactinv.t_fiches_inv
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_stations_fs_the_geom_2154
  ON florestation.t_stations_fs
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_stations_fs_the_geom_3857
  ON florestation.t_stations_fs
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_apresence_the_geom_2154
  ON florepatri.t_apresence
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_apresence_the_geom_3857
  ON florepatri.t_apresence
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_zprospection_the_geom_2154
  ON florepatri.t_zprospection
  USING gist
  (the_geom_2154);

CREATE INDEX index_gist_t_zprospection_the_geom_3857
  ON florepatri.t_zprospection
  USING gist
  (the_geom_3857);

CREATE INDEX index_gist_t_zprospection_geom_point_3857
  ON florepatri.t_zprospection
  USING gist
  (geom_point_3857);

CREATE INDEX index_gist_t_zprospection_geom_mixte_3857
  ON florepatri.t_zprospection
  USING gist
  (geom_mixte_3857);

-------------------------------------------------------------------
--Modification de la gestion des noms dont la saisie est possible--
--Gestion dans cor_nom_liste au lieu de cor_taxon_attribut---------
-------------------------------------------------------------------

--Création d'une nouvelle liste pour la saisie possible
INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, picto)
VALUES(500,'Saisie possible','Liste des noms dont la saisie est autorisée','images/pictos/nopicto.gif');

--Ajout de la liste gymnospermes oubliés
--A vous de mettre dans cette liste (cor_nom_liste) les taxons correspondant
INSERT INTO taxonomie.bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) 
VALUES (308, 'Gymnospermes',null, 'images/pictos/nopicto.gif','Plantae','Gymnospermes');

--correction
UPDATE taxonomie.bib_listes SET group2_inpn = 'Fougères' WHERE id_liste = 305;

--récupération des taxons avec l'attribut saisie possible = 'oui'
--comme les attributs sont liés aux cd_ref, tous les synonymes d'un taxons ont le même attribut
--donc on ne pouvait pas rendre un synonyme saisissable et l'autre non.
INSERT INTO taxonomie.cor_nom_liste 
SELECT 500 as id_liste, id_nom FROM taxonomie.bib_noms WHERE cd_ref IN(SELECT cd_ref FROM taxonomie.cor_taxon_attribut WHERE id_attribut = 3 AND valeur_attribut = 'oui');

--mise à jour des vues permettant de construire les listes déroulantes des taxons dans les formulaires de saisie
CREATE OR REPLACE VIEW contactflore.v_nomade_taxons_flore AS 
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
    f2.bool AS patrimonial,
    m.texte_message_cflore AS message
   FROM taxonomie.bib_noms n
     LEFT JOIN contactflore.cor_message_taxon_cflore cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN contactflore.bib_messages_cflore m ON m.id_message_cflore = cmt.id_message_cflore
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom 
     JOIN contactflore.v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
   WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
   ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cflore;

CREATE OR REPLACE VIEW contactfaune.v_nomade_taxons_faune AS 
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[61098, 61119, 61000]) THEN 6
            ELSE 5
        END AS denombrement,
    f2.bool AS patrimonial,
    m.texte_message_cf AS message,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[60577, 60612]) THEN false
            ELSE true
        END AS contactfaune,
    true AS mortalite
  FROM taxonomie.bib_noms n
     LEFT JOIN contactfaune.cor_message_taxon cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN contactfaune.bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN contactfaune.v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cf;

CREATE OR REPLACE VIEW contactinv.v_nomade_taxons_inv AS 
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
    f2.bool AS patrimonial,
    m.texte_message_inv AS message
  FROM taxonomie.bib_noms n
     LEFT JOIN contactinv.cor_message_taxon cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN contactinv.bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN contactinv.v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_inv;

CREATE OR REPLACE VIEW florestation.v_taxons_fs AS 
  SELECT tx.cd_nom,
    tx.nom_complet
  FROM taxonomie.bib_noms n
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  AND cnl.id_liste = ANY (ARRAY[305, 306, 307, 308]);

--suppression de l'attribut saisie possible
ALTER TABLE taxonomie.bib_attributs DISABLE TRIGGER USER;
DELETE FROM taxonomie.cor_taxon_attribut WHERE id_attribut = 3;
DELETE FROM taxonomie.bib_attributs WHERE id_attribut = 3;
ALTER TABLE taxonomie.bib_attributs ENABLE TRIGGER USER;
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Animalia');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Fungi');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Plantae');