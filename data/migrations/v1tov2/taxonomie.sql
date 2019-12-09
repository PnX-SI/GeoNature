--------------------
--SCHEMA TAXONOMIE--
--------------------
IMPORT FOREIGN SCHEMA taxonomie FROM SERVER geonature1server INTO v1_compat;

--ATTENTION : avant de lancer les TRUNCATE CASCADE sur les tables du schéma taxonomie, vous devez vérifier que cela ne va provoquer de perte de données.
--En effet, ce script est prévu pour importer le schéma taxonomie de GeoNature1 vers une base GeoNauture2 vierge.
--Les tables impactées par cette action sont notées en commentaires
--d'une manière générale, toute les tables utilisant bib_noms avec une clé étrangère sur bib_noms seront impactées (vidées)
TRUNCATE taxonomie.bib_themes CASCADE;
--NOTICE:  truncate cascades to table "bib_attributs"
--NOTICE:  truncate cascades to table "cor_taxon_attribut"

TRUNCATE taxonomie.bib_listes CASCADE;
--NOTICE:  truncate cascades to table "cor_nom_liste"
--NOTICE:  truncate cascades to table "cor_critere_liste"

TRUNCATE taxonomie.bib_noms CASCADE;
--NOTICE:  truncate cascades to table "cor_nom_liste"
--NOTICE:  truncate cascades to table "t_medias"
--NOTICE:  truncate cascades to table "cor_message_taxon"
--NOTICE:  truncate cascades to table "cor_unite_taxon"
--NOTICE:  truncate cascades to table "t_releves_cf"

INSERT INTO taxonomie.bib_themes (id_theme, nom_theme, desc_theme, ordre, id_droit)
SELECT * FROM  v1_compat.bib_themes;

INSERT INTO taxonomie.bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre)
SELECT * FROM  v1_compat.bib_attributs;

INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, picto, regne, group2_inpn)
SELECT * FROM  v1_compat.bib_listes;

DO $$ 
    BEGIN
        BEGIN
            ALTER TABLE taxonomie.bib_noms ADD COLUMN comments character varying(1000);
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column comments already exists in taxonomie.bib_noms.';
        END;
    END;
$$;

--on récupère les cd_nom exotiques qui ne seraient pas dans le référentiel officiel
INSERT INTO taxonomie.taxref (
    cd_nom,
    id_statut,
    id_habitat,
    id_rang,
    regne,
    phylum,
    classe,
    ordre,
    famille,
    cd_taxsup,
    cd_ref,
    lb_nom,
    lb_auteur,
    nom_complet,
    nom_valide,
    nom_vern,
    nom_vern_eng,
    group1_inpn,
    group2_inpn,
    nom_complet_html,
    cd_sup,
    sous_famille,
    tribu,
    url
)
SELECT cd_nom,
    id_statut,
    id_habitat,
    id_rang,
    regne,
    phylum,
    classe,
    ordre,
    famille,
    cd_taxsup,
    cd_ref,
    lb_nom,
    lb_auteur,
    nom_complet,
    nom_valide,
    nom_vern,
    nom_vern_eng,
    group1_inpn,
    group2_inpn,
    nom_complet_html,
    cd_sup,
    sous_famille,
    tribu,
    url 
FROM v1_compat.taxref 
WHERE cd_nom < 0 OR cd_nom IN(887246,905267, 1000000);
--FROM v1_compat.taxref WHERE cd_nom NOT IN(SELECT cd_nom FROM taxonomie.taxref);

INSERT INTO taxonomie.bib_noms (id_nom, cd_nom, cd_ref, nom_francais, comments)
SELECT * FROM  v1_compat.bib_noms;

INSERT INTO taxonomie.cor_nom_liste (id_liste, id_nom)
SELECT * FROM  v1_compat.cor_nom_liste; 
--normalement le trigger sur ce table gère la table taxonomie.vm_taxref_list_forautocomplete

TRUNCATE taxonomie.cor_taxon_attribut;
INSERT INTO taxonomie.cor_taxon_attribut (id_attribut, valeur_attribut, cd_ref)
SELECT * FROM  v1_compat.cor_taxon_attribut;

INSERT INTO taxonomie.t_medias (id_media, cd_ref, titre, url, chemin, auteur, desc_media, date_media, is_public, supprime, id_type, source, licence)
SELECT * FROM  v1_compat.t_medias;

TRUNCATE  taxonomie.taxhub_admin_log;
INSERT INTO taxonomie.taxhub_admin_log (id, action_time, id_role, object_type, object_id, object_repr, change_type, change_message)
SELECT * FROM  v1_compat.taxhub_admin_log;


SELECT taxonomie.fct_build_bibtaxon_attributs_view('Animalia');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Plantae');
SELECT taxonomie.fct_build_bibtaxon_attributs_view('Fungi');

SELECT setval('taxonomie.taxhub_admin_log_id_seq', (SELECT max(id)+1 FROM taxonomie.taxhub_admin_log), true);
SELECT setval('taxonomie.bib_noms_id_nom_seq', (SELECT max(id_nom)+1 FROM taxonomie.bib_noms), true);
SELECT setval('taxonomie.t_medias_id_media_seq', (SELECT max(id_media)+1 FROM taxonomie.t_medias), true);
