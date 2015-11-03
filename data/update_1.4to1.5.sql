--Optimisation des vues permettant le chargement de la liste des taxons
CREATE TABLE cor_boolean
(
  expression character varying(25) NOT NULL,
  bool boolean,
  CONSTRAINT cor_boolean_pkey PRIMARY KEY (expression)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE cor_boolean OWNER TO geonatuser;
INSERT INTO cor_boolean VALUES('oui',true);
INSERT INTO cor_boolean VALUES('non',false);

DROP VIEW synthese.v_taxons_synthese;
CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
SELECT DISTINCT
    t.nom_francais,
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
JOIN taxonomie.bib_listes l ON l.id_liste = ctl.id_liste AND (l.id_liste = ANY (ARRAY[3, 101, 105, 106, 107, 108, 109, 110, 111, 112, 113]))
LEFT JOIN 
	( 
	SELECT cd_nom, STRING_AGG(((((arrete || ' '::text) || article::text) || '__'::text) || url::text), '#'::text) AS protections
        FROM taxonomie.taxref_protection_especes tpe
        JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
        GROUP BY cd_nom
        ) prot ON prot.cd_nom = t.cd_nom
JOIN cor_boolean f2 ON f2.expression = t.filtre2
JOIN cor_boolean f3 ON f3.expression = t.filtre3
JOIN (SELECT DISTINCT cd_nom FROM synthese.syntheseff) s ON s.cd_nom = t.cd_nom
ORDER BY t.nom_francais;

ALTER TABLE synthese.v_taxons_synthese
  OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_taxons_synthese TO geonatuser;
GRANT ALL ON TABLE synthese.v_taxons_synthese TO postgres;


 WITH taxon AS (
         SELECT 
	    tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
	FROM 
	( 
		SELECT tx_1.id_taxon,
                    taxref_1.cd_nom,
                    taxref_1.cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
		FROM taxonomie.taxref taxref_1
		LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
		WHERE (taxref_1.cd_nom IN (SELECT DISTINCT cd_nom FROM synthese.syntheseff))
	) tx
        JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
)
SELECT t.id_taxon,
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
FROM 
	( 
	SELECT DISTINCT t_1.id_taxon,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT taxref.cd_nom FROM taxonomie.taxref WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text) AS id_regne,
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
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'PH'::bpchar AND taxref.cd_nom = taxref.cd_ref) ph ON ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'CL'::bpchar AND taxref.cd_nom = taxref.cd_ref) cl ON cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'OR'::bpchar AND taxref.cd_nom = taxref.cd_ref) ord ON ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.id_rang,
                    taxref.lb_nom,
                    taxref.phylum,
                    taxref.famille
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'FM'::bpchar AND taxref.cd_nom = taxref.cd_ref) f ON f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL
	) t;
    

DROP VIEW synthese.v_tree_taxons_synthese;

CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS (
         SELECT tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
           FROM ( SELECT tx_1.id_taxon,
                    taxref_1.cd_nom,
                    taxref_1.cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
                   FROM taxonomie.taxref taxref_1
                     LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
                  WHERE (taxref_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
                           FROM synthese.syntheseff))) tx
             JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
        )
 SELECT t.id_taxon,
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
   FROM ( SELECT DISTINCT t_1.id_taxon,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT taxref.cd_nom
                   FROM taxonomie.taxref
                  WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text) AS id_regne,
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

ALTER TABLE synthese.v_tree_taxons_synthese
  OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_tree_taxons_synthese TO geonatuser;

ALTER TABLE meta.bib_programmes RENAME sitpn TO programme_public;
ALTER TABLE meta.bib_programmes RENAME desc_programme_sitpn TO desc_programme_public;
ALTER TABLE meta.bib_programmes ADD COLUMN actif boolean;
UPDATE meta.bib_programmes SET actif = true;