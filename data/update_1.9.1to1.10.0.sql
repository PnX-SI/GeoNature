--SET search_path = taxonomie, pg_catalog;

----------------------------------------------------------------------------------
--- MODIF lié à au passage du champ bib_nom.nom_francais en char(1000) -------
----------------------------------------------------------------------------------

-- suppression des vues qui sont liés à bib_noms
DO
$$
DECLARE
   sregne text;
   mysql text;
BEGIN
	FOR sregne IN
		SELECT DISTINCT lower(regne)
		FROM taxonomie.taxref t
		JOIN taxonomie.bib_noms n
		ON t.cd_nom = n.cd_nom
		WHERE t.regne IS NOT NULL
	LOOP
		mysql = 'DROP VIEW IF exists taxonomie.v_bibtaxon_attributs_' || sregne;
		PERFORM mysql;
	END LOOP;
END
$$;

DROP VIEW IF EXISTS taxonomie.v_taxref_all_listes;
DROP VIEW IF EXISTS contactinv.v_nomade_taxons_inv;
DROP VIEW IF EXISTS contactflore.v_nomade_taxons_flore;
DROP VIEW IF EXISTS contactfaune.v_nomade_taxons_faune;
DROP VIEW IF EXISTS synthese.v_taxons_synthese;
DROP VIEW IF EXISTS synthese.v_tree_taxons_synthese;


-- drop related trigger
DROP TRIGGER trg_refresh_nomfrancais_mv_taxref_list_forautocomplete ON taxonomie.bib_noms;

-- alter bib_noms
ALTER TABLE taxonomie.bib_noms ALTER COLUMN nom_francais TYPE character varying(1000);

-- relancer la fonction qui cree les vues

DO
$$
DECLARE
   sregne text;
BEGIN
	FOR sregne IN
		SELECT DISTINCT regne
		FROM taxonomie.taxref t
		JOIN taxonomie.bib_noms n
		ON t.cd_nom = n.cd_nom
		WHERE t.regne IS NOT NULL
	LOOP
			PERFORM taxonomie.fct_build_bibtaxon_attributs_view(sregne);
	END LOOP;
END
$$;

-- recree la vue v_taxref_all_lites

CREATE OR REPLACE VIEW taxonomie.v_taxref_all_listes AS
 WITH bib_nom_lst AS (
         SELECT c.id_nom,
            n.cd_nom,
            n.nom_francais,
            c.id_liste
           FROM taxonomie.cor_nom_liste c
             JOIN taxonomie.bib_noms n USING (id_nom)
        )
 SELECT t.regne,
    t.phylum,
    t.classe,
    t.ordre,
    t.famille,
    t.group1_inpn,
    t.group2_inpn,
    t.cd_nom,
    t.cd_ref,
    t.nom_complet,
    t.nom_valide,
    d.nom_francais AS nom_vern,
    t.lb_nom,
    d.id_liste
   FROM taxonomie.taxref t
     JOIN bib_nom_lst d ON t.cd_nom = d.cd_nom;

--recréer les vues des contacts et de la synthese
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
     JOIN public.cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
  WHERE (n.id_nom IN ( SELECT cnl.id_nom
           FROM taxonomie.cor_nom_liste cnl
          WHERE cnl.id_liste = 500))
  ORDER BY n.id_nom, (taxonomie.find_cdref(tx.cd_nom)), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_inv;

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
  WHERE (n.id_nom IN ( SELECT cnl.id_nom
           FROM taxonomie.cor_nom_liste cnl
          WHERE cnl.id_liste = 500))
  ORDER BY n.id_nom, (taxonomie.find_cdref(tx.cd_nom)), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cflore;

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
  WHERE (n.id_nom IN ( SELECT cnl.id_nom
           FROM taxonomie.cor_nom_liste cnl
          WHERE cnl.id_liste = 500))
  ORDER BY n.id_nom, (taxonomie.find_cdref(tx.cd_nom)), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cf;

CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
 SELECT DISTINCT n.nom_francais,
    txr.lb_nom AS nom_latin,
        CASE pat.valeur_attribut
            WHEN 'oui'::text THEN true
            WHEN 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
        CASE pr.valeur_attribut
            WHEN 'oui'::text THEN true
            WHEN 'non'::text THEN false
            ELSE NULL::boolean
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
          WHERE t_1.id_rang::bpchar = 'KD'::bpchar AND t_1.cd_nom = t_1.cd_ref
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
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang::bpchar = 'PH'::bpchar AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang::bpchar = 'CL'::bpchar AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang::bpchar = 'OR'::bpchar AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
             LEFT JOIN taxonomie.taxref f ON f.id_rang::bpchar = 'FM'::bpchar AND f.cd_nom = f.cd_ref AND f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL) t;

-- recree le trigger supprimé

CREATE TRIGGER trg_refresh_nomfrancais_mv_taxref_list_forautocomplete AFTER UPDATE OF nom_francais
ON taxonomie.bib_noms FOR EACH ROW
EXECUTE PROCEDURE taxonomie.trg_fct_refresh_nomfrancais_mv_taxref_list_forautocomplete();


----------------------------------------------------------------------------------
--- MODIF lié à l'ajout du champ cd_ref dans vm_taxref_list_forautocomplete-------
----------------------------------------------------------------------------------

DROP TABLE taxonomie.vm_taxref_list_forautocomplete;
DROP FUNCTION taxonomie.trg_fct_refresh_mv_taxref_list_forautocomplete() CASCADE;
--DROP TRIGGER trg_refresh_mv_taxref_list_forautocomplete ON taxonomie.cor_nom_liste;

-- recrée la table vm_taxref_list_forautocomplete avec le cd_ref
CREATE TABLE taxonomie.vm_taxref_list_forautocomplete AS
SELECT t.cd_nom,
  t.cd_ref,
  t.search_name,
  t.nom_valide,
  t.lb_nom,
  t.regne,
  t.group2_inpn,
  l.id_liste
FROM (
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  UNION
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(n.nom_francais, ' =  <i> ', t_1.nom_valide, '</i>' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  JOIN taxonomie.bib_noms n
  ON t_1.cd_nom = n.cd_nom
  WHERE n.nom_francais IS NOT NULL AND t_1.cd_nom = t_1.cd_ref
) t
JOIN taxonomie.v_taxref_all_listes l ON t.cd_nom = l.cd_nom;
COMMENT ON TABLE taxonomie.vm_taxref_list_forautocomplete
     IS 'Table construite à partir d''une requete sur la base et mise à jour via le trigger trg_refresh_mv_taxref_list_forautocomplete de la table cor_nom_liste';

CREATE INDEX i_vm_taxref_list_forautocomplete_cd_nom
  ON taxonomie.vm_taxref_list_forautocomplete (cd_nom ASC NULLS LAST);
CREATE INDEX i_vm_taxref_list_forautocomplete_search_name
  ON taxonomie.vm_taxref_list_forautocomplete (search_name ASC NULLS LAST);


-- recree le trigger modifié

CREATE OR REPLACE FUNCTION taxonomie.trg_fct_refresh_mv_taxref_list_forautocomplete()
  RETURNS trigger AS
$BODY$
DECLARE
	new_cd_nom int;
	new_nom_vern varchar(1000);
BEGIN
	IF TG_OP in ('DELETE', 'TRUNCATE', 'UPDATE') THEN
	    DELETE FROM taxonomie.vm_taxref_list_forautocomplete WHERE cd_nom IN (
		SELECT cd_nom FROM taxonomie.bib_noms WHERE id_nom =  OLD.id_nom
	    );
	END IF;
	IF TG_OP in ('INSERT', 'UPDATE') THEN
		SELECT cd_nom, nom_francais INTO new_cd_nom, new_nom_vern FROM taxonomie.bib_noms WHERE id_nom = NEW.id_nom;

		INSERT INTO taxonomie.vm_taxref_list_forautocomplete
		SELECT t.cd_nom,
            t.cd_ref,
		    concat(t.lb_nom, ' = ', t.nom_valide) AS search_name,
		    t.nom_valide,
		    t.lb_nom,
		    t.regne,
		    t.group2_inpn,
		    NEW.id_liste
		FROM taxonomie.taxref t  WHERE cd_nom = new_cd_nom;


		IF NOT new_nom_vern IS NULL THEN
			INSERT INTO taxonomie.vm_taxref_list_forautocomplete
			SELECT t.cd_nom,
                t.cd_ref,
			    concat(new_nom_vern, ' = ', t.nom_valide) AS search_name,
			    t.nom_valide,
			    t.lb_nom,
			    t.regne,
			    t.group2_inpn,
          NEW.id_liste
			FROM taxonomie.taxref t
			WHERE cd_nom = new_cd_nom AND t.cd_nom = t.cd_ref;
		END IF;
	END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER trg_refresh_mv_taxref_list_forautocomplete
  AFTER INSERT OR UPDATE OR DELETE
  ON taxonomie.cor_nom_liste
  FOR EACH ROW
  EXECUTE PROCEDURE taxonomie.trg_fct_refresh_mv_taxref_list_forautocomplete();
