-- bib_noms remplace bib_taxons pour des raisons de cohérence taxonomique avec le référenciel taxref. Cette table liste les noms des taxons de votre territoire. Taxref liste aussi des noms (cd_nom) et des taxons (cd_ref). 
-- Unicité du cd_nom dans bib_noms afin d'éviter les doublons. 
-- Si vous avez des doublons sur cd_nom, la table bib_taxons ainsi qu'éventuellement vos données doivent être nettoyées.
CREATE TABLE taxonomie.bib_noms
(
  id_nom serial PRIMARY KEY,
  cd_nom integer UNIQUE,
  cd_ref integer ,
  nom_francais character varying(255),
  CONSTRAINT fk_bib_nom_taxref FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT check_is_valid_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref))
);

-- Les attributs sont attachés à un taxon (cd_ref) afin d'éviter une éventuelle incohérence : attributs renseignés de manière différente pour 2 synonymes.
ALTER TABLE taxonomie.cor_taxon_attribut ADD cd_ref integer;
ALTER TABLE taxonomie.cor_taxon_attribut ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref)); -- Le cd_ref fourni doit être un taxon de référence dans taxref.
-- en prévision de l'atals, la valeur des attribut peut-être très longue
DROP VIEW synthese.v_taxons_synthese;
DROP VIEW contactfaune.v_nomade_taxons_faune;
DROP VIEW contactflore.v_nomade_taxons_flore;
DROP VIEW contactinv.v_nomade_taxons_inv;
DROP VIEW taxonomie.v_nomade_classes;
DROP VIEW contactfaune.v_nomade_classes;
DROP VIEW contactflore.v_nomade_classes;
DROP VIEW contactinv.v_nomade_classes;
DROP VIEW florepatri.v_nomade_classes;
ALTER TABLE taxonomie.cor_taxon_attribut ALTER COLUMN valeur_attribut TYPE text;

CREATE TABLE taxonomie.cor_nom_liste
(
  id_liste integer NOT NULL,
  id_nom integer NOT NULL,
  CONSTRAINT cor_nom_liste_pkey PRIMARY KEY (id_nom, id_liste),
  CONSTRAINT cor_nom_listes_bib_listes_fkey FOREIGN KEY (id_liste)
      REFERENCES taxonomie.bib_listes (id_liste) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT cor_nom_listes_bib_noms_fkey FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- Afin de regrouper les attributs par théme (par exemple les attributs de l'atlas)
CREATE TABLE taxonomie.bib_themes (
  id_theme integer primary key,
  nom_theme varchar(20),
  desc_theme varchar(255),
  ordre int
);

--modifications liées  au fonctionnement de TaxHub
ALTER TABLE taxonomie.bib_attributs ADD type_widget character varying(50);
ALTER TABLE taxonomie.bib_attributs ADD regne character varying(20);
ALTER TABLE taxonomie.bib_attributs ADD group2_inpn character varying(255);
ALTER TABLE taxonomie.bib_attributs ADD id_theme INTEGER  REFERENCES taxonomie.bib_themes (id_theme);
ALTER TABLE taxonomie.bib_attributs ADD ordre INTEGER;
ALTER TABLE taxonomie.bib_listes ADD COLUMN regne character varying(20);
ALTER TABLE taxonomie.bib_listes ADD COLUMN group2_inpn character varying(255);
UPDATE taxonomie.bib_listes SET regne = 'Animalia' WHERE id_liste IN(1,2,3,4,5,7,8,9,10,11,12,13,14,15,16,20,21,101,1001,1002);
UPDATE taxonomie.bib_listes SET regne = 'Plantae' WHERE id_liste IN(300,301,302,303,305,306,307,1003);
UPDATE taxonomie.bib_listes SET regne = 'Fungi' WHERE id_liste IN(1004);
UPDATE taxonomie.bib_listes SET group2_inpn = 'Amphibiens' WHERE id_liste =1;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Annélides' WHERE id_liste =2;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Entognathes' WHERE id_liste =3;
UPDATE taxonomie.bib_listes SET group2_inpn = '<Autres>' WHERE id_liste =4;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Crustacés' WHERE id_liste =5;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Pycnogonides' WHERE id_liste =7;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Gastéropodes' WHERE id_liste =8;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Insectes' WHERE id_liste =9;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Bivalves' WHERE id_liste =10;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Mammifères' WHERE id_liste =11;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Oiseaux' WHERE id_liste =12;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Poissons' WHERE id_liste =13;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Reptiles' WHERE id_liste =14;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Myriapodes' WHERE id_liste =15;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Arachnides' WHERE id_liste =16;
UPDATE taxonomie.bib_listes SET group2_inpn = '<Autres>' WHERE id_liste =20;
UPDATE taxonomie.bib_listes SET group2_inpn = '<Autres>' WHERE id_liste =21;
UPDATE taxonomie.bib_listes SET group2_inpn = '<Autres>' WHERE id_liste =101;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Mousses' WHERE id_liste =301;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Lichens' WHERE id_liste =302;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Algues' WHERE id_liste =303;
UPDATE taxonomie.bib_listes SET group2_inpn = 'Angiospermes' WHERE id_liste IN (305,306,307);

-------------Transfert des données--------------------------
--Bib_noms
INSERT INTO taxonomie.bib_noms(id_nom, cd_nom, cd_ref, nom_francais)
SELECT DISTINCT id_taxon, cd_nom, taxonomie.find_cdref(cd_nom), nom_francais FROM taxonomie.bib_taxons;

--Attributs
UPDATE taxonomie.cor_taxon_attribut c SET cd_ref = taxonomie.find_cdref(cd_nom)
FROM taxonomie.bib_taxons t
WHERE c.id_taxon = t.id_taxon;
ALTER TABLE taxonomie.cor_taxon_attribut DROP CONSTRAINT cor_taxon_attribut_pkey;
ALTER TABLE taxonomie.cor_taxon_attribut ADD PRIMARY KEY (id_attribut, cd_ref);

--Theme
INSERT INTO taxonomie.bib_themes(id_theme,nom_theme, desc_theme, ordre)
VALUES (1,'Général', 'Informations générales concernant les taxons', 1);
VALUES (2,'Atlas', 'Informations relatives à l''atlas', 2);
UPDATE taxonomie.bib_attributs SET id_theme = 1;
--Attributs update with thèmes
UPDATE taxonomie.bib_attributs
SET 
  liste_valeur_attribut = '{"values":["oui", "non"]}',
  obligatoire = true,
  type_attribut = 'text',
  id_theme = 1,
  ordre= 1,
  type_widget = 'radio'
WHERE id_attribut = 1;
UPDATE taxonomie.bib_attributs
SET 
  liste_valeur_attribut = '{"values":["oui", "non"]}',
  obligatoire = true,
  type_attribut = 'text',
  id_theme = 1,
  ordre= 2,
  type_widget = 'radio'
WHERE id_attribut = 2;
INSERT INTO bib_attributs (id_attribut ,nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, id_theme, ordre, regne, group2_inpn) VALUES (2, 'saisie', 'Saisie possible', '{"values":["oui", "non"]}',true,'Permet d''exclure des taxons des menus déroulants de saisie', 'text', 'radio', 1, 3, null, null);


--Listes
INSERT INTO taxonomie.cor_nom_liste
SELECT DISTINCT id_liste, id_nom 
FROM  taxonomie.cor_taxon_liste ctl
JOIN taxonomie.bib_taxons t
ON ctl.id_taxon = t.id_taxon
JOIN taxonomie.bib_noms n
ON n.cd_nom = t.cd_nom;

-----------------Grant---------------------

GRANT ALL ON TABLE taxonomie.bib_noms TO geonatuser;
GRANT ALL ON TABLE taxonomie.cor_nom_liste TO geonatuser;
GRANT ALL ON TABLE taxonomie.bib_themes TO geonatuser;

-------------renommer les colonnes id_taxon vers id_nom---------------
ALTER TABLE contactfaune.cor_message_taxon RENAME id_taxon  TO id_nom;
ALTER TABLE contactfaune.cor_unite_taxon RENAME id_taxon  TO id_nom;
ALTER TABLE contactfaune.t_releves_cf RENAME id_taxon  TO id_nom;
ALTER TABLE contactflore.cor_message_taxon_cflore RENAME id_taxon  TO id_nom;
ALTER TABLE contactflore.cor_unite_taxon_cflore RENAME id_taxon  TO id_nom;
ALTER TABLE contactflore.t_releves_cflore RENAME id_taxon  TO id_nom;
ALTER TABLE contactinv.cor_message_taxon RENAME id_taxon  TO id_nom;
ALTER TABLE contactinv.cor_unite_taxon_inv RENAME id_taxon  TO id_nom;
ALTER TABLE contactinv.t_releves_inv RENAME id_taxon  TO id_nom;


----------------VIEWS------------------

CREATE OR REPLACE FUNCTION taxonomie.fct_build_bibtaxon_attributs_view(sregne character varying)
  RETURNS void AS
$BODY$
DECLARE
    r taxonomie.bib_attributs%rowtype;
    sql_select text;
    sql_join text;
    sql_where text;
BEGIN
	sql_join :=' FROM taxonomie.bib_noms b JOIN taxonomie.taxref taxref USING(cd_nom) ';
	sql_select := 'SELECT b.* ';
	sql_where := ' WHERE regne=''' ||$1 || '''';
	FOR r IN
		SELECT id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, 
		       obligatoire, desc_attribut, type_attribut, type_widget, regne, 
		       group2_inpn
		FROM taxonomie.bib_attributs
		WHERE regne IS NULL OR regne=sregne
	LOOP
		sql_select := sql_select || ', ' || r.nom_attribut || '.valeur_attribut::' || r.type_attribut || ' as ' || r.nom_attribut;
		sql_join := sql_join || ' LEFT OUTER JOIN (SELECT valeur_attribut, cd_ref FROM taxonomie.cor_taxon_attribut WHERE id_attribut= '
			|| r.id_attribut || ') as  ' || r.nom_attribut || '  ON b.cd_ref= ' || r.nom_attribut || '.cd_ref ';
	--RETURN NEXT r; -- return current row of SELECT
	END LOOP;
	EXECUTE 'DROP VIEW IF EXISTS taxonomie.v_bibtaxon_attributs_' || sregne ;
	EXECUTE 'CREATE OR REPLACE VIEW taxonomie.v_bibtaxon_attributs_' || sregne ||  ' AS ' || sql_select || sql_join || sql_where ;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Animalia');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Plantae');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Fungi');

-- View: synthese.v_tree_taxons_synthese
DROP VIEW synthese.v_tree_taxons_synthese;
CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS (
            SELECT tx.id_nom,
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
            FROM ( SELECT tx_1.id_nom,
                    taxref_1.cd_nom,
                    taxref_1.cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
                    FROM taxonomie.taxref taxref_1
                    LEFT JOIN taxonomie.bib_noms tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
                    WHERE (taxref_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom FROM synthese.syntheseff))) tx
            JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
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

ALTER TABLE synthese.v_tree_taxons_synthese OWNER TO geonatuser;

-- View: taxonomie.v_taxref_hierarchie_bibtaxons
CREATE OR REPLACE VIEW taxonomie.v_taxref_hierarchie_bibtaxons AS 
 WITH mestaxons AS (
         SELECT tx_1.cd_nom,
            tx_1.id_statut,
            tx_1.id_habitat,
            tx_1.id_rang,
            tx_1.regne,
            tx_1.phylum,
            tx_1.classe,
            tx_1.ordre,
            tx_1.famille,
            tx_1.cd_taxsup,
            tx_1.cd_sup,
            tx_1.cd_ref,
            tx_1.lb_nom,
            tx_1.lb_auteur,
            tx_1.nom_complet,
            tx_1.nom_complet_html,
            tx_1.nom_valide,
            tx_1.nom_vern,
            tx_1.nom_vern_eng,
            tx_1.group1_inpn,
            tx_1.group2_inpn
           FROM taxonomie.taxref tx_1
             JOIN taxonomie.bib_noms t ON t.cd_nom = tx_1.cd_nom
        )
 SELECT DISTINCT tx.regne,
    tx.phylum,
    tx.classe,
    tx.ordre,
    tx.famille,
    tx.cd_nom,
    tx.cd_ref,
    tx.lb_nom,
    btrim(tx.id_rang::text) AS id_rang,
    f.nb_tx_fm,
    o.nb_tx_or,
    c.nb_tx_cl,
    p.nb_tx_ph,
    r.nb_tx_kd
   FROM taxonomie.taxref tx
     JOIN ( SELECT DISTINCT tx_1.regne,
            tx_1.phylum,
            tx_1.classe,
            tx_1.ordre,
            tx_1.famille
           FROM mestaxons tx_1) a ON a.regne::text = tx.regne::text AND tx.id_rang::text = 'KD'::text OR a.phylum::text = tx.phylum::text AND tx.id_rang::text = 'PH'::text OR a.classe::text = tx.classe::text AND tx.id_rang::text = 'CL'::text OR a.ordre::text = tx.ordre::text AND tx.id_rang::text = 'OR'::text OR a.famille::text = tx.famille::text AND tx.id_rang::text = 'FM'::text
     LEFT JOIN ( SELECT mestaxons.famille,
            count(*) AS nb_tx_fm
           FROM mestaxons
          WHERE mestaxons.id_rang::text <> 'FM'::text
          GROUP BY mestaxons.famille) f ON f.famille::text = tx.famille::text
     LEFT JOIN ( SELECT mestaxons.ordre,
            count(*) AS nb_tx_or
           FROM mestaxons
          WHERE mestaxons.id_rang::text <> 'OR'::text
          GROUP BY mestaxons.ordre) o ON o.ordre::text = tx.ordre::text
     LEFT JOIN ( SELECT mestaxons.classe,
            count(*) AS nb_tx_cl
           FROM mestaxons
          WHERE mestaxons.id_rang::text <> 'CL'::text
          GROUP BY mestaxons.classe) c ON c.classe::text = tx.classe::text
     LEFT JOIN ( SELECT mestaxons.phylum,
            count(*) AS nb_tx_ph
           FROM mestaxons
          WHERE mestaxons.id_rang::text <> 'PH'::text
          GROUP BY mestaxons.phylum) p ON p.phylum::text = tx.phylum::text
     LEFT JOIN ( SELECT mestaxons.regne,
            count(*) AS nb_tx_kd
           FROM mestaxons
          WHERE mestaxons.id_rang::text <> 'KD'::text
          GROUP BY mestaxons.regne) r ON r.regne::text = tx.regne::text
  WHERE (tx.id_rang::text = ANY (ARRAY['KD'::character varying, 'PH'::character varying, 'CL'::character varying, 'OR'::character varying, 'FM'::character varying]::text[])) AND tx.cd_nom = tx.cd_ref;
  GRANT ALL ON TABLE taxonomie.v_taxref_hierarchie_bibtaxons TO geonatuser;
  
--View: contactfaune.vm_taxref_hierarchie
CREATE TABLE taxonomie.vm_taxref_hierarchie AS
SELECT tx.regne,tx.phylum,tx.classe,tx.ordre,tx.famille, tx.cd_nom, tx.cd_ref, lb_nom, trim(id_rang) AS id_rang, f.nb_tx_fm, o.nb_tx_or, c.nb_tx_cl, p.nb_tx_ph, r.nb_tx_kd FROM taxonomie.taxref tx
  LEFT JOIN (SELECT famille ,count(*) AS nb_tx_fm  FROM taxonomie.taxref where id_rang NOT IN ('FM') GROUP BY  famille) f ON f.famille = tx.famille
  LEFT JOIN (SELECT ordre ,count(*) AS nb_tx_or FROM taxonomie.taxref where id_rang NOT IN ('OR') GROUP BY  ordre) o ON o.ordre = tx.ordre
  LEFT JOIN (SELECT classe ,count(*) AS nb_tx_cl  FROM taxonomie.taxref where id_rang NOT IN ('CL') GROUP BY  classe) c ON c.classe = tx.classe
  LEFT JOIN (SELECT phylum ,count(*) AS nb_tx_ph  FROM taxonomie.taxref where id_rang NOT IN ('PH') GROUP BY  phylum) p ON p.phylum = tx.phylum
  LEFT JOIN (SELECT regne ,count(*) AS nb_tx_kd  FROM taxonomie.taxref where id_rang NOT IN ('KD') GROUP BY  regne) r ON r.regne = tx.regne
WHERE id_rang IN ('KD','PH','CL','OR','FM') AND tx.cd_nom = tx.cd_ref;
ALTER TABLE ONLY taxonomie.vm_taxref_hierarchie ADD CONSTRAINT vm_taxref_hierarchie_pkey PRIMARY KEY (cd_nom);
ALTER TABLE taxonomie.vm_taxref_hierarchie OWNER TO geonatuser;

-- View: contactfaune.v_nomade_classes
CREATE OR REPLACE VIEW contactfaune.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON cnl.id_liste = l.id_liste
             JOIN taxonomie.bib_noms n ON n.id_nom = cnl.id_nom
          WHERE l.id_liste = ANY (ARRAY[1, 11, 12, 13, 14])
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;
ALTER TABLE contactfaune.v_nomade_classes OWNER TO geonatuser;
GRANT ALL ON TABLE contactfaune.v_nomade_classes TO geonatuser;

-- View: contactfaune.v_nomade_taxons_faune
DROP VIEW contactfaune.v_nomade_taxons_faune;
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
    JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
    JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
    JOIN contactfaune.v_nomade_classes g ON g.id_classe = cnl.id_liste
    JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
    JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut::text AND cta.id_attribut = 1
   WHERE n.cd_ref IN (SELECT cd_ref FROM taxonomie.cor_taxon_attribut WHERE valeur_attribut = 'oui' AND id_attribut = 3)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cf;
ALTER TABLE contactfaune.v_nomade_taxons_faune OWNER TO geonatuser;

-- View: contactinv.v_nomade_classes
CREATE OR REPLACE VIEW contactinv.v_nomade_classes AS 
    SELECT g.id_liste AS id_classe,
        g.nom_liste AS nom_classe_fr,
        g.desc_liste AS desc_classe
    FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
            FROM taxonomie.bib_listes l
            JOIN taxonomie.cor_nom_liste cnl ON cnl.id_liste = l.id_liste
            JOIN taxonomie.bib_noms n ON n.id_nom = cnl.id_nom
            WHERE l.id_liste = ANY (ARRAY[2, 5, 8, 9, 10, 15, 16])
            GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
    JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
    WHERE t.phylum::text <> 'Chordata'::text AND t.regne::text = 'Animalia'::text;
ALTER TABLE contactinv.v_nomade_classes OWNER TO geonatuser;

-- View: contactinv.v_nomade_taxons_inv
DROP VIEW contactinv.v_nomade_taxons_inv;
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
     JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut::text AND cta.id_attribut = 1
   WHERE n.cd_ref IN (SELECT cd_ref FROM taxonomie.cor_taxon_attribut WHERE valeur_attribut = 'oui' AND id_attribut = 3)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_inv;
ALTER TABLE contactinv.v_nomade_taxons_inv OWNER TO geonatuser;

-- View: contactflore.v_nomade_classes
CREATE OR REPLACE VIEW contactflore.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON cnl.id_liste = l.id_liste
             JOIN taxonomie.bib_noms n ON n.id_nom = cnl.id_nom
          WHERE l.id_liste > 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;
ALTER TABLE contactflore.v_nomade_classes OWNER TO geonatuser;

-- View: contactflore.v_nomade_taxons_flore
--DROP VIEW contactflore.v_nomade_taxons_flore;
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
     JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN contactflore.v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = cta.valeur_attribut::text AND cta.id_attribut = 1
    WHERE n.cd_ref IN (SELECT cd_ref FROM taxonomie.cor_taxon_attribut WHERE valeur_attribut = 'oui' AND id_attribut = 3)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cflore;
ALTER TABLE contactflore.v_nomade_taxons_flore OWNER TO geonatuser;

-- View: florepatri.v_nomade_classes
CREATE OR REPLACE VIEW florepatri.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON cnl.id_liste = l.id_liste
             JOIN taxonomie.bib_noms n ON n.id_nom = cnl.id_nom
          WHERE l.id_liste > 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;
ALTER TABLE florepatri.v_nomade_classes OWNER TO geonatuser;

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
   FROM florepatri.v_nomade_classes
UNION
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM contactflore.v_nomade_classes;

ALTER TABLE taxonomie.v_nomade_classes
  OWNER TO cartopne;
GRANT ALL ON TABLE taxonomie.v_nomade_classes TO cartopne;
GRANT SELECT ON TABLE taxonomie.v_nomade_classes TO pnv;

-- View: synthese.v_taxons_synthese
DROP VIEW synthese.v_taxons_synthese;
CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
 SELECT DISTINCT n.nom_francais,
    txr.lb_nom AS nom_latin,
    CASE pat.valeur_attribut 
        WHEN 'oui' THEN TRUE
        WHEN 'non' THEN FALSE
        ELSE NULL
    END AS patrimonial,
    CASE pr.valeur_attribut 
        WHEN 'oui' THEN TRUE
        WHEN 'non' THEN FALSE
        ELSE NULL
    END AS protection_stricte,
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
     JOIN taxonomie.bib_noms n ON txr.cd_nom = n.cd_nom
     LEFT JOIN taxonomie.cor_taxon_attribut pat ON pat.cd_ref = n.cd_ref AND pat.id_attribut = 1
     LEFT JOIN taxonomie.cor_taxon_attribut pr ON pr.cd_ref = n.cd_ref AND pr.id_attribut = 2
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN taxonomie.bib_listes l ON l.id_liste = cnl.id_liste AND (l.id_liste = ANY (ARRAY[1001, 1002, 1003, 1004]))
     LEFT JOIN ( SELECT tpe.cd_nom,
            string_agg((((tpa.arrete || ' '::text) || tpa.article::text) || '__'::text) || tpa.url::text, '#'::text) AS protections
           FROM taxonomie.taxref_protection_especes tpe
             JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
          GROUP BY tpe.cd_nom) prot ON prot.cd_nom = n.cd_nom
     JOIN ( SELECT DISTINCT syntheseff.cd_nom
           FROM synthese.syntheseff) s ON s.cd_nom = n.cd_nom
  ORDER BY n.nom_francais;
ALTER TABLE synthese.v_taxons_synthese OWNER TO geonatuser;

-- View: synthese.v_export_sinp
CREATE OR REPLACE VIEW synthese.v_export_sinp AS 
 SELECT s.id_synthese,
    o.nom_organisme,
    s.dateobs,
    s.observateurs,
    n.cd_nom,
    tx.lb_nom AS nom_latin,
    c.nom_critere_synthese AS critere,
    s.effectif_total,
    s.remarques,
    p.nom_programme,
    s.insee,
    s.altitude_retenue AS altitude,
    st_x(st_transform(s.the_geom_point, 2154))::integer AS x,
    st_y(st_transform(s.the_geom_point, 2154))::integer AS y,
    s.derniere_action,
    s.date_insert,
    s.date_update
   FROM synthese.syntheseff s
     JOIN taxonomie.taxref tx ON tx.cd_nom = s.cd_nom
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = s.id_organisme
     JOIN taxonomie.bib_noms n ON n.cd_nom = s.cd_nom
     LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = s.id_critere_synthese
     LEFT JOIN meta.bib_lots l ON l.id_lot = s.id_lot
     LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
  WHERE s.supprime = false;
ALTER TABLE synthese.v_export_sinp OWNER TO geonatuser;

-- View: utilisateurs.v_userslist_forall_applications
CREATE OR REPLACE VIEW utilisateurs.v_userslist_forall_applications AS 
 SELECT a.groupe,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    a.desc_role,
    a.pass,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.pn,
    a.session_appli,
    a.date_insert,
    a.date_update,
    max(a.id_droit) AS id_droit_max,
    a.id_application
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = u.id_role
          WHERE u.groupe = false
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = g.id_role_groupe
          WHERE u.groupe = false) a
  GROUP BY a.groupe, a.id_role, a.identifiant, a.nom_role, a.prenom_role, a.desc_role, a.pass, a.email, a.id_organisme, a.organisme, a.id_unite, a.remarques, a.pn, a.session_appli, a.date_insert, a.date_update, a.id_application;
ALTER TABLE utilisateurs.v_userslist_forall_applications OWNER TO geonatuser;
GRANT ALL ON TABLE utilisateurs.v_userslist_forall_applications TO geonatuser;


---------------FUNCTIONS----------------

CREATE OR REPLACE FUNCTION contactflore.couleur_taxon(id integer, maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_nom AND cta.id_attribut = 1
    WHERE n.id_nom = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactflore.couleur_taxon(integer, date) OWNER TO geonatuser;
  

CREATE OR REPLACE FUNCTION contactfaune.couleur_taxon(id integer, maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_nom AND cta.id_attribut = 1
    WHERE n.id_nom = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.couleur_taxon(integer, date) OWNER TO geonatuser;
   
CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(id integer, maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_nom AND cta.id_attribut = 1
    WHERE n.id_nom = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.couleur_taxon(integer, date) OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION synthese.calcul_cor_unite_taxon_cf(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
  DECLARE
  cdnom integer;
  BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
	DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactfaune.cor_unite_taxon (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactfaune.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION synthese.calcul_cor_unite_taxon_cf(integer, integer) OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION synthese.calcul_cor_unite_taxon_inv(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
DECLARE
    cdnom integer;
BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
    DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactinv.cor_unite_taxon_inv (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactinv.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION synthese.calcul_cor_unite_taxon_inv(integer, integer) OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION synthese.calcul_cor_unite_taxon_cflore(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
  DECLARE
  cdnom integer;
  BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
	DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactflore.cor_unite_taxon_cflore (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactflore.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION synthese.calcul_cor_unite_taxon_cflore(integer, integer) OWNER TO geonatuser;


-------------TRIGGERS-------------------

CREATE OR REPLACE FUNCTION contactfaune.insert_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
cdnom integer;
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
    --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon, on commence par récupérer l'unité à partir du pointage (table t_fiches_cf)
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		--si la ligne existe dans cor_unite_taxon on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactfaune.cor_unite_taxon VALUES(unite,new.id_nom,fiche.dateobs,contactfaune.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.insert_releve_cf() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactfaune.synthese_insert_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
	fiche RECORD;
	mesobservateurs character varying(255);
	criteresynthese integer;
	idsource integer;
	idsourcem integer;
	idsourcecf integer;
	unite integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcem id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Mortalité';
	SELECT INTO idsourcecf id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Contact faune';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
    --Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
	-- Récupération du id_source selon le critère d'observation, Si critère = 2 alors on est dans une source mortalité (=2) sinon cf (=1)
	IF criteresynthese = 2 THEN idsource = idsourcem;
	ELSE
	    idsource = idsourcecf;
	END IF;
	SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
	JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
	LEFT JOIN (
                SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactfaune.cor_role_fiche_cf c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cf
            ) o ON o.id_cf = f.id_cf
	WHERE r.id_releve_cf = new.id_releve_cf;
	
	INSERT INTO synthese.syntheseff (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		id_precision,
		cd_nom,
		insee,
		dateobs,
		observateurs,
		determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_cf,
	'f'||new.id_cf||'-r'||new.id_releve_cf,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
    new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
	);
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;  
ALTER FUNCTION contactfaune.synthese_insert_releve_cf() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactfaune.synthese_update_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
    test integer;
    criteresynthese integer;
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
    cdnom integer;
BEGIN
    
	--on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
        FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	    IF sources.url = 'cf' THEN
	        idsourcecf = sources.id_source;
	    ELSIF sources.url = 'mortalite' THEN
	        idsourcem = sources.id_source;
	    END IF;
        END LOOP;
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
		WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem); -- Ici on utilise le OLD id_releve_cf pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cf
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cf
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_update_releve_cf() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactfaune.update_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
	re integer;
BEGIN
   -- Si changement de taxon, 
	IF new.id_nom<>old.id_nom THEN
	   -- Correction du cd_ref_origine
		SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
		new.cd_ref_origine = re;
	END IF;
RETURN NEW;			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.update_releve_cf() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactinv.insert_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
cdnom integer;
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
    --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon_inv, on commence par récupérer l'unité à partir du pointage (table t_fiches_inv)
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_inv, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		--si la ligne existe dans cor_unite_taxon_inv on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactinv.cor_unite_taxon_inv VALUES(unite,new.id_nom,fiche.dateobs,contactinv.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.insert_releve_inv() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactinv.synthese_insert_releve_inv()
  RETURNS trigger AS
$$
DECLARE
	fiche RECORD;
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
	unite integer;
	idsource integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;
	SELECT INTO mesobservateurs o.observateurs FROM contactinv.t_releves_inv r
	JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
	LEFT JOIN (
                SELECT id_inv, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactinv.cor_role_fiche_inv c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_inv
            ) o ON o.id_inv = f.id_inv
	WHERE r.id_releve_inv = new.id_releve_inv;
    
	--On fait le INSERT dans syntheseff
	INSERT INTO synthese.syntheseff (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		id_precision,
		cd_nom,
		insee,
		dateobs,
		observateurs,
        determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_inv,
	'f'||new.id_inv||'-r'||new.id_releve_inv,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
    new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na
	);
	RETURN NEW; 			
END;
$$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.synthese_insert_releve_inv() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactinv.synthese_update_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
    idsource integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = cdnom,
			remarques = new.commentaire,
            determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na
		WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; -- Ici on utilise le OLD id_releve_inv pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_inv
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_inv
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.synthese_update_releve_inv() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactinv.update_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
	re integer;
BEGIN
   -- Si changement de taxon, 
	IF new.id_nom<>old.id_nom THEN
	   -- Correction du cd_ref_origine
		SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
		new.cd_ref_origine = re;
	END IF;
RETURN NEW;			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.update_releve_inv() OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION synthese.maj_cor_unite_taxon()
  RETURNS trigger AS
$BODY$
DECLARE
monembranchement varchar;
monregne varchar;
monidtaxon integer;
BEGIN

IF (TG_OP = 'DELETE') THEN
	--retrouver le id_nom
	SELECT INTO monidtaxon id_nom FROM taxonomie.bib_noms WHERE cd_nom = old.cd_nom LIMIT 1; 
	--calcul du règne du taxon supprimé
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon supprimé
			SELECT  INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
		-- puis recalul des couleurs avec old.id_unite_geo et old.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
			IF monembranchement = 'Chordata' THEN
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactfaune.cor_unite_taxon WHERE id_nom = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_cf(monidtaxon, old.id_unite_geo);
				END IF;
			ELSE
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_nom = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_inv(monidtaxon, old.id_unite_geo);
				END IF;
			END IF;
		END IF;
		RETURN OLD;		
ELSIF (TG_OP = 'INSERT') THEN
	--retrouver le id_nom
	SELECT INTO monidtaxon id_nom FROM taxonomie.bib_noms WHERE cd_nom = new.cd_nom LIMIT 1;
	--calcul du règne du taxon inséré
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon inséré
		SELECT INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
		-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
		IF monembranchement = 'Chordata' THEN
		    PERFORM synthese.calcul_cor_unite_taxon_cf(monidtaxon, new.id_unite_geo);
		ELSE
		    PERFORM synthese.calcul_cor_unite_taxon_inv(monidtaxon, new.id_unite_geo);
		END IF;
        END IF;
	RETURN NEW;
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION synthese.maj_cor_unite_taxon() OWNER TO geonatuser;



----------------------------
ALTER TABLE contactfaune.cor_message_taxon DROP CONSTRAINT fk_cor_message_taxon_bib_taxons_fa;
ALTER TABLE contactfaune.cor_message_taxon
  ADD CONSTRAINT fk_cor_message_taxon_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactfaune.cor_unite_taxon DROP CONSTRAINT fk_cor_unite_taxon_bib_taxons_fa;
ALTER TABLE contactfaune.cor_unite_taxon
  ADD CONSTRAINT fk_cor_unite_taxon_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactfaune.t_releves_cf DROP CONSTRAINT fk_t_releves_cf_bib_taxons;
ALTER TABLE contactfaune.t_releves_cf
  ADD CONSTRAINT fk_t_releves_cf_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactflore.t_releves_cflore DROP CONSTRAINT fk_t_releves_cflore_bib_taxons;
ALTER TABLE contactflore.t_releves_cflore
  ADD CONSTRAINT fk_t_releves_cflore_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactflore.cor_unite_taxon_cflore DROP CONSTRAINT fk_cor_unite_taxon_cflore_bib_taxons;
ALTER TABLE contactflore.cor_unite_taxon_cflore
  ADD CONSTRAINT fk_cor_unite_taxon_cflore_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactflore.cor_message_taxon_cflore DROP CONSTRAINT fk_cor_message_taxon_cflore_bib_taxons;
ALTER TABLE contactflore.cor_message_taxon_cflore
  ADD CONSTRAINT fk_cor_message_taxon_cflore_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
      
ALTER TABLE contactinv.t_releves_inv DROP CONSTRAINT fk_t_releves_inv_bib_taxons;
ALTER TABLE contactinv.t_releves_inv
  ADD CONSTRAINT fk_t_releves_inv_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactinv.cor_unite_taxon_inv DROP CONSTRAINT fk_cor_unite_taxon_inv_bib_taxons;
ALTER TABLE contactinv.cor_unite_taxon_inv
  ADD CONSTRAINT fk_cor_unite_taxon_inv_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE contactinv.cor_message_taxon DROP CONSTRAINT fk_cor_message_taxon_inv_bib_taxons;
ALTER TABLE contactinv.cor_message_taxon
  ADD CONSTRAINT fk_cor_message_taxon_inv_bib_noms FOREIGN KEY (id_nom)
      REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

      

CREATE OR REPLACE FUNCTION taxonomie.fct_build_bibtaxon_attributs_view(sregne character varying)
  RETURNS void AS
$BODY$
DECLARE
    r taxonomie.bib_attributs%rowtype;
    sql_select text;
    sql_join text;
    sql_where text;
BEGIN
	sql_join :=' FROM taxonomie.bib_noms b JOIN taxonomie.taxref taxref USING(cd_nom) ';
	sql_select := 'SELECT b.* ';
	sql_where := ' WHERE regne=''' ||$1 || '''';
	FOR r IN
		SELECT id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, 
		       obligatoire, desc_attribut, type_attribut, type_widget, regne, 
		       group2_inpn
		FROM taxonomie.bib_attributs
		WHERE regne IS NULL OR regne=sregne
	LOOP
		sql_select := sql_select || ', ' || r.nom_attribut || '.valeur_attribut::' || r.type_attribut || ' as ' || r.nom_attribut;
		sql_join := sql_join || ' LEFT OUTER JOIN (SELECT valeur_attribut, cd_ref FROM taxonomie.cor_taxon_attribut WHERE id_attribut= '
			|| r.id_attribut || ') as  ' || r.nom_attribut || '  ON b.cd_ref= ' || r.nom_attribut || '.cd_ref ';
	--RETURN NEXT r; -- return current row of SELECT
	END LOOP;
	EXECUTE 'DROP VIEW IF EXISTS taxonomie.v_bibtaxon_attributs_' || sregne ;
	EXECUTE 'CREATE OR REPLACE VIEW taxonomie.v_bibtaxon_attributs_' || sregne ||  ' AS ' || sql_select || sql_join || sql_where ;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Animalia');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Plantae');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Fungi');


--Mise à jour de la relation taxons attributs à partir de la valeur des filtres dans bib_taxons
INSERT INTO taxonomie.cor_taxon_attribut
SELECT id_taxon, 1 as id_attribut, 'oui' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM taxonomie.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre2 = 'oui'
AND tx.cd_nom = tx.cd_ref;

INSERT INTO taxonomie.cor_taxon_attribut
SELECT id_taxon, 1 as id_attribut, 'non' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM taxonomie.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre2 = 'non'
AND tx.cd_nom = tx.cd_ref;

SELECT id_taxon, 2 as id_attribut, 'oui' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM taxonomie.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre3 = 'oui'
AND tx.cd_nom = tx.cd_ref;

INSERT INTO taxonomie.cor_taxon_attribut
SELECT id_taxon, 2 as id_attribut, 'non' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM taxonomie.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre3 = 'non'
AND tx.cd_nom = tx.cd_ref;

---- Nettoyage
-- Petite sauvegarde au cas où avant de tout péter 
--CREATE SCHEMA save;
CREATE TABLE save.bib_taxons AS
SELECT * FROM taxonomie.bib_taxons;
CREATE TABLE save.cor_taxon_liste AS
SELECT * FROM taxonomie.cor_taxon_liste;
CREATE TABLE save.cor_taxon_attribut AS
SELECT * FROM taxonomie.cor_taxon_attribut;
CREATE TABLE save.bib_filtres AS
SELECT * FROM taxonomie.bib_filtres;
--suppression de l'ancien MCD
DROP TABLE taxonomie.bib_filtres;
DROP TABLE taxonomie.cor_taxon_liste;
ALTER TABLE taxonomie.cor_taxon_attribut DROP CONSTRAINT cor_taxon_attrib_bib_taxons_fkey;
ALTER TABLE taxonomie.cor_taxon_attribut DROP id_taxon;
DROP TABLE taxonomie.bib_taxons;