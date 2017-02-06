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

--Nettoyage
DROP TABLE IF EXISTS utilisateurs.bib_observateurs;

--Index spatiaux gist manquants (amélioration des performances)
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