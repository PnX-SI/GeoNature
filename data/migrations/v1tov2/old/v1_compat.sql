DROP SCHEMA IF EXISTS v1_contactfaune CASCADE  ;
DROP SCHEMA IF EXISTS v1_florestation CASCADE  ;
DROP SCHEMA IF EXISTS v1_compat CASCADE ;
DROP SCHEMA IF EXISTS synchronomade CASCADE ;

CREATE SCHEMA v1_florestation;
COMMENT ON SCHEMA v1_florestation IS 'schéma contenant les données de l''application florestation de la V1';

CREATE SCHEMA synchronomade;
COMMENT ON SCHEMA synchronomade IS 'schéma contenant les erreurs de synchronisation et permettant une compatibilité temporaire avec les outils mobiles de la V1';

CREATE SCHEMA v1_compat;
COMMENT ON SCHEMA v1_compat IS 'schéma contenant des objets permettant une compatibilité temporaire avec les outils mobiles de la V1';

SET search_path = v1_compat, public, pg_catalog;

CREATE TABLE cor_boolean
(
  expression character varying(25) NOT NULL,
  bool boolean NOT NULL
);

INSERT INTO cor_boolean VALUES('oui',true);
INSERT INTO cor_boolean VALUES('non',false);

DROP TABLE IF EXISTS v1_compat.cor_synthese_v1_to_v2;
CREATE TABLE v1_compat.cor_synthese_v1_to_v2 (
	pk_source integer,
	entity_source character varying(100),
	field_source character varying(50),
	entity_target character varying(100),
	field_target character varying(50),
	id_type_nomenclature_cible integer,
	id_nomenclature_cible integer,
	commentaire text,
	CONSTRAINT pk_cor_synthese_v1_to_v2 PRIMARY KEY (pk_source, entity_source, entity_target, field_target)
);
COMMENT ON TABLE v1_compat.cor_synthese_v1_to_v2 IS 'Permet de définir des correspondances entre le MCD de la V1 et celui de la V2';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.pk_source IS 'Valeur de la PK du champ de la table source pour laquelle une correspondance doit être établie';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.entity_source IS 'Table source (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.entity_target IS 'Table cible (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.field_source IS 'Nom du champ de la table source (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.field_target IS 'Nom du champ de la table cible (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.id_type_nomenclature_cible IS 'Id_type de la nomenclature sur laquelle la correspondance en V2 est établie';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.id_nomenclature_cible IS 'id de la nomenclature sur laquelle la correspondance en V2 est établie';
ALTER TABLE ONLY v1_compat.cor_synthese_v1_to_v2
    ADD CONSTRAINT fk_cor_synthese_v1_to_v2_id_type_nomenclature FOREIGN KEY (id_type_nomenclature_cible) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type) ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE ONLY v1_compat.cor_synthese_v1_to_v2
    ADD CONSTRAINT fk_cor_synthese_v1_to_v2_t_nomenclatures FOREIGN KEY (id_nomenclature_cible) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE ON DELETE NO ACTION;

CREATE INDEX i_cor_synthese_v1_to_v2_pk_source
  ON v1_compat.cor_synthese_v1_to_v2
  USING btree
  (pk_source);
 
CREATE INDEX i_cor_synthese_v1_to_v2_id_nomenclature_cible
  ON v1_compat.cor_synthese_v1_to_v2
  USING btree
  (id_nomenclature_cible);

--Import en FDW les schémas de la base GeoNature 1
IMPORT FOREIGN SCHEMA utilisateurs FROM SERVER geonature1server INTO v1_compat;
IMPORT FOREIGN SCHEMA taxonomie FROM SERVER geonature1server INTO v1_compat;
IMPORT FOREIGN SCHEMA synthese FROM SERVER geonature1server INTO v1_compat;
IMPORT FOREIGN SCHEMA meta FROM SERVER geonature1server INTO v1_compat;
-- DROP FOREIGN TABLE v1_compat.v_nomade_classes;
-- IMPORT FOREIGN SCHEMA contactfaune FROM SERVER geonature1server INTO v1_compat;
-- DROP foreign table v1_compat.cor_message_taxon;
-- DROP foreign table v1_compat.log_colors;
-- DROP foreign table v1_compat.log_colors_day;
-- DROP foreign table v1_compat.v_nomade_classes;
-- IMPORT FOREIGN SCHEMA contactinv FROM SERVER geonature1server INTO v1_compat;
-- DROP foreign table v1_compat.v_nomade_classes;
-- IMPORT FOREIGN SCHEMA contactflore FROM SERVER geonature1server INTO v1_compat;


-----------------------
--SCHEMA UTILISATEURS--
-----------------------
--ATTENTION : avant de lancer les TRUNCATE CASCADE sur les tables du schéma utilisateurs, vous devez vérifier que cela ne va provoquer de perte de données.
--En effet, ce script est prévu pour importer le schéma utilisateurs de GeoNature1 vers une base GeoNauture2 vierge.
--Les tables impactées par cette action sont notées en commentaires

TRUNCATE utilisateurs.t_roles CASCADE;
--NOTICE:  truncate cascades to table "cor_role_menu"
--NOTICE:  truncate cascades to table "cor_roles"
--NOTICE:  truncate cascades to table "cor_role_droit_application"
--NOTICE:  truncate cascades to table "cor_role_tag"
--NOTICE:  truncate cascades to table "cor_app_privileges"
--NOTICE:  truncate cascades to table "cor_acquisition_framework_actor"
--NOTICE:  truncate cascades to table "cor_dataset_actor"
--NOTICE:  truncate cascades to table "t_validations"
--NOTICE:  truncate cascades to table "synthese"
--NOTICE:  truncate cascades to table "t_base_sites"
--NOTICE:  truncate cascades to table "t_base_visits"
--NOTICE:  truncate cascades to table "cor_visit_observer"
--NOTICE:  truncate cascades to table "t_releves_occtax"
--NOTICE:  truncate cascades to table "cor_role_releves_occtax"
--NOTICE:  truncate cascades to table "cor_role_fiche_cf"
--NOTICE:  truncate cascades to table "cor_area_synthese"
--NOTICE:  truncate cascades to table "cor_site_application"
--NOTICE:  truncate cascades to table "cor_site_area"
--NOTICE:  truncate cascades to table "t_occurrences_occtax"
--NOTICE:  truncate cascades to table "cor_counting_occtax"

TRUNCATE utilisateurs.bib_unites CASCADE;
--NOTICE:  truncate cascades to table "t_roles"
--NOTICE:  truncate cascades to table "cor_role_menu"
--NOTICE:  truncate cascades to table "cor_roles"
--NOTICE:  truncate cascades to table "cor_role_droit_application"
--NOTICE:  truncate cascades to table "cor_role_tag"
--NOTICE:  truncate cascades to table "cor_app_privileges"
--NOTICE:  truncate cascades to table "cor_acquisition_framework_actor"
--NOTICE:  truncate cascades to table "cor_dataset_actor"
--NOTICE:  truncate cascades to table "t_validations"
--NOTICE:  truncate cascades to table "synthese"
--NOTICE:  truncate cascades to table "t_base_sites"
--NOTICE:  truncate cascades to table "t_base_visits"
--NOTICE:  truncate cascades to table "cor_visit_observer"
--NOTICE:  truncate cascades to table "t_releves_occtax"
--NOTICE:  truncate cascades to table "cor_role_releves_occtax"
--NOTICE:  truncate cascades to table "cor_role_fiche_cf"
--NOTICE:  truncate cascades to table "cor_area_synthese"
--NOTICE:  truncate cascades to table "cor_site_application"
--NOTICE:  truncate cascades to table "cor_site_area"
--NOTICE:  truncate cascades to table "t_occurrences_occtax"
--NOTICE:  truncate cascades to table "cor_counting_occtax"

TRUNCATE utilisateurs.t_menus CASCADE;
--NOTICE:  truncate cascades to table "cor_role_menu"

TRUNCATE utilisateurs.t_applications CASCADE;
--NOTICE:  truncate cascades to table "cor_role_droit_application"
--NOTICE:  truncate cascades to table "t_menus"
--NOTICE:  truncate cascades to table "cor_application_tag"
--NOTICE:  truncate cascades to table "cor_app_privileges"
--NOTICE:  truncate cascades to table "t_modules"
--NOTICE:  truncate cascades to table "cor_site_application"
--NOTICE:  truncate cascades to table "cor_role_menu"

DELETE FROM utilisateurs.bib_organismes WHERE id_organisme > 0;

INSERT INTO utilisateurs.bib_organismes(
  nom_organisme,
  adresse_organisme,
  cp_organisme,
  ville_organisme,
  tel_organisme,
  fax_organisme,
  email_organisme,
  id_organisme,
  uuid_organisme,
  id_parent
)
SELECT * FROM v1_compat.bib_organismes WHERE id_organisme NOT IN (SELECT id_organisme FROM utilisateurs.bib_organismes);


INSERT INTO utilisateurs.bib_unites(
  nom_unite,
  adresse_unite,
  cp_unite,
  ville_unite,
  tel_unite,
  fax_unite,
  email_unite,
  id_unite
)
SELECT * FROM v1_compat.bib_unites WHERE id_unite NOT IN (SELECT id_unite FROM utilisateurs.bib_unites);

INSERT INTO utilisateurs.t_roles (
    groupe,
    id_role,
    identifiant,
    nom_role,
    prenom_role,
    desc_role,
    pass,
    email,
    id_organisme,
    organisme,
    id_unite,
    remarques,
    pn,
    session_appli,
    date_insert,
    date_update,
    uuid_role,
    pass_plus
)
SELECT * FROM v1_compat.t_roles WHERE id_role NOT IN(SELECT id_role FROM utilisateurs.t_roles);

INSERT INTO utilisateurs.cor_roles (id_role_groupe, id_role_utilisateur)
SELECT * FROM v1_compat.cor_roles;

INSERT INTO utilisateurs.t_applications (id_application, nom_application, desc_application, id_parent)
SELECT * FROM v1_compat.t_applications;

INSERT INTO utilisateurs.t_menus(id_menu, nom_menu, desc_menu, id_application)
SELECT * FROM v1_compat.t_menus;

INSERT INTO utilisateurs.cor_role_menu (id_role, id_menu)
SELECT * FROM v1_compat.cor_role_menu;

INSERT INTO utilisateurs.cor_role_droit_application (id_role, id_droit, id_application)
SELECT * FROM v1_compat.cor_role_droit_application;

--TODO rajouter les données supprimées par les truncate cascade


--------------------
--SCHEMA TAXONOMIE--
--------------------
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
FROM v1_compat.taxref WHERE cd_nom = 1000000;--temp PNE
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


---------------
--SCHEMA META--
---------------
--PROTOCOLES
DELETE FROM gn_meta.sinp_datatype_protocols WHERE id_protocol > 0;
INSERT INTO gn_meta.sinp_datatype_protocols (
  id_protocol,
  protocol_name,
  protocol_desc,
  id_nomenclature_protocol_type
)
SELECT 
  id_protocole,
  nom_protocole,
  'Question : ' || COALESCE(question,'none') || ' - ' || 
    'Objectifs : ' || COALESCE(objectifs,'none') || ' - ' || 
    'Méthode : ' || COALESCE(methode,'none') || ' - ' ||  
    'Avancement : ' || COALESCE(avancement,'none') || ' - ' ||  
    'Date_debut : ' || COALESCE(date_debut,'1000-01-01') || ' - ' ||  
    'Date_fin : ' || COALESCE(date_fin, '3000-01-01')
    AS protocol_desc,
  ref_nomenclatures.get_id_nomenclature('TYPE_PROTOCOLE','1') AS id_nomenclature_protocol_type
FROM v1_compat.t_protocoles p
WHERE nom_protocole IS NOT NULL
AND id_protocole <> 0;
--AND id_protocole IN (SELECT DISTINCT id_protocole FROM v1_compat.vm_syntheseff);
--PNE
SELECT setval('gn_meta.sinp_datatype_protocols_id_protocol_seq', (SELECT max(id_protocol)+1 FROM gn_meta.sinp_datatype_protocols), true);

--CADRE D'ACQUISITION (V2) = PROGRAMMES (V1)
TRUNCATE gn_meta.t_acquisition_frameworks CASCADE;
INSERT INTO gn_meta.t_acquisition_frameworks (
  id_acquisition_framework,
  acquisition_framework_name,
  acquisition_framework_desc,
  id_nomenclature_territorial_level,
  territory_desc,
  id_nomenclature_financing_type,
  is_parent,
  acquisition_framework_start_date
)
SELECT DISTINCT
  p.id_programme,
  nom_programme,
  desc_programme,
  ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','4') AS id_nomenclature_territorial_level,
  'Territoire du parc national des Ecrins' AS territory_desc,
  ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','1') AS id_nomenclature_financing_type,
  0 AS is_parent,
  '1000-01-01'::date AS acquisition_framework_start_date
FROM v1_compat.bib_programmes p
JOIN v1_compat.bib_lots l ON l.id_programme = p.id_programme;
--AND l.id_lot IN (SELECT DISTINCT id_lot FROM v1_compat.vm_syntheseff);
--PNE
--Mise à jour du niveau territorial
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','1') WHERE id_acquisition_framework = 3;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','2') WHERE id_acquisition_framework = 8;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','4') WHERE id_acquisition_framework IN (13,17,9) ;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','6') WHERE id_acquisition_framework = 111;

--mise à jour du type de financement
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_financing_type = ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','2') WHERE id_acquisition_framework = 111;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_financing_type = ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','4') WHERE id_acquisition_framework = 16;
SELECT setval('gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq', (SELECT max(id_acquisition_framework)+1 FROM gn_meta.t_acquisition_frameworks), true);

--DATASETS (v2) - LOTS (V1)
--DELETE FROM gn_meta.t_datasets WHERE id_dataset > 0;
INSERT INTO gn_meta.t_datasets (
  id_dataset,
  id_acquisition_framework,
  dataset_name,
  dataset_shortname,
  dataset_desc,
  id_nomenclature_data_type,
  marine_domain,
  terrestrial_domain,
  id_nomenclature_dataset_objectif,
  id_nomenclature_collecting_method,
  id_nomenclature_data_origin,
  id_nomenclature_source_status,
  id_nomenclature_resource_type
)
SELECT DISTINCT
  id_lot,
  id_programme,
  nom_lot,
  nom_lot,
  desc_lot,
  ref_nomenclatures.get_id_nomenclature('DATA_TYP','1') AS id_nomenclature_data_type, --nomenclature 103 = "donnée source"
  false AS marine_domain,
  true AS terrestrial_domain,
  ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.1') AS id_nomenclature_dataset_objectif, --nomenclature 114 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL','1') AS id_nomenclature_collecting_method, --nomenclature 115 = "Observation directe : Vue, écoute, olfactive, tactile"
  ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','Pu') AS id_nomenclature_data_origin, --nomenclature 2 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te') AS id_nomenclature_source_status, --nomenclature 19 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP','1') AS id_nomenclature_resource_type --nomenclature 102 = "jeu de données"
FROM v1_compat.bib_lots;
--WHERE id_lot NOT IN (SELECT DISTINCT id_lot FROM v1_compat.vm_syntheseff);
SELECT setval('gn_meta.t_datasets_id_dataset_seq', (SELECT max(id_dataset)+1 FROM gn_meta.t_datasets), true);
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','1') WHERE id_acquisition_framework = 3;
--PNE : id_nomenclature_dataset_objectif
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.2') WHERE id_dataset IN (104,108); --"Inventaire pour étude d’espèces ou de communautés"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.3') WHERE id_dataset IN (5,6,21,105); --"Inventaire pour étude d’espèces ou de communautés"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.5') WHERE id_dataset IN (8,43); --"Numérisation de bibliographie"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','5.2') WHERE id_dataset IN (9,10,11,16,18,19,20); --"Surveillance temporelle d'espèces"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','5.3') WHERE id_dataset IN (17); --"Surveillance temporelle d'espèces"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','7.1') WHERE id_dataset IN (47,107,111); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.1') WHERE id_dataset IN (200); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset IN (44); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset >= 25 AND id_dataset <= 42; --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset >= 48 AND id_dataset <= 54; --"Inventaires généralisés & exploration""
--PNE : id_nomenclature_collecting_method ; Même si les jeux de données peuvent comporter des méthodes de collectes mixtes, tous les lots sont considérés comme "Observation directe : Vue, écoute, olfactive, tactile"
--PNE : id_nomenclature_data_origin (données privées, publiques)
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','Pr') WHERE id_dataset IN (13,23,24,47,111); --"Privés"
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','NSP') WHERE id_dataset IN (43); --"Ne sait pas"
--PNE : id_nomenclature_source_status
UPDATE gn_meta.t_datasets SET id_nomenclature_source_status = ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Li') WHERE id_dataset IN (8,43); --"Littérature : l'observation a été extraite d'un article ou un ouvrage scientifique."

--ROLE DES ACTEURS POUR LES CADRES D'ACQUISITION ; 
--PNE "Contact principal" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','1') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE : "Point de contact base de données de production" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE : "Point de contact pour les métadonnées"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE "Fournisseur du jeu de données"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107, NULL, 1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(14, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(16, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(12, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'));

--PNE OBECTIFS SCIENTIFIQUES DES CADRES D'ACQUISITION : id_nomenclature_objectif
--"Inventaire logique espace"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','3') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(1,2,3,9,11,13,14,15,16,104,105,106,107,108,109,110,111,200);
--"Inventaire espèce"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','1') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(3,4,5,9,10,105);
--"Evolution temporelle"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','5') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(4,5,6,7,8,10,104);
--"Regroupements et autres études"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','7') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(12,14,16,107,111);

--PNE VOLET SINP : = Terre, mer, paysage ; terre pour tous les CA du PNE
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp;
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('VOLET_SINP','1') AS id_nomenclature_voletsinp
FROM gn_meta.t_acquisition_frameworks;

--ROLE DES ACTEURS POUR LES JEUX DE DONNEES ; 
--PNE "Contact principal" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','1') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE "Producteur du jeu de données = PNE"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset NOT IN (13,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,107,111);
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(13,507,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(24,null,1002,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(25,1140,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(26,1140,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(27,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(28,1168,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(29,1205,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(30,1206,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(31,1167,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(32,1207,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(33,1209,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(34,1207,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(35,1208,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(36,1210,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(37,1239,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(38,1241,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(39,1243,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(40,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(41,1244,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(42,1268,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(44,1269,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(45,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(46,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(47,null,1001,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(48,1324,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(49,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(50,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(51,1319,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(52,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(53,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(54,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
;

--PNE "Point de contact base de données de production"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset NOT IN (24,27,40,47,50,54,107,111);
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(54,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(50,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(40,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(27,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(47,null,1001,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(24,null,1002,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
;

--PNE : "Point de contact pour les métadonnées"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE TERRITOIRE ET LE JEU DE DONNEES ; = Métropole
INSERT INTO gn_meta.cor_dataset_territory (id_dataset,id_nomenclature_territory, territory_desc)
SELECT id_dataset, ref_nomenclatures.get_id_nomenclature('TERRITOIRE','METROP') AS id_nomenclature_territory, 'Territoire du parc national des Ecrins et des communes environnantes' AS territory_desc
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE PROCOLE ET JEU DE DONNEES : TODO, COMPLEXE ATTENTE Campanule ???
--INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
--(1, 140)

--PNE les publications ne sont pas traitées (notion absente dans GN1)
--gn_meta.sinp_datatype_publications & gn_meta.cor_acquisition_framework_publication


-------------------
--SCHEMA SYNTHESE--
-------------------
--rappatrier les données localement
CREATE MATERIALIZED VIEW v1_compat.vm_syntheseff AS
SELECT * FROM v1_compat.syntheseff;

--création d'index sur la vue matérialisée
CREATE UNIQUE INDEX ui_id_synthese_vm_syntheseff ON v1_compat.vm_syntheseff (id_synthese);

CREATE INDEX i_vm_syntheseff_id_lot
  ON v1_compat.vm_syntheseff
  USING btree
  (id_lot);
 
CREATE INDEX i_vm_syntheseff_id_source
  ON v1_compat.vm_syntheseff
  USING btree
  (id_source);
 
CREATE INDEX i_vm_syntheseff_id_precision
  ON v1_compat.vm_syntheseff
  USING btree
  (id_precision);
 
CREATE INDEX i_vm_syntheseff_id_critere_synthese
  ON v1_compat.vm_syntheseff
  USING btree
  (id_critere_synthese);
 
CREATE INDEX i_vm_syntheseff_cd_nom
  ON v1_compat.vm_syntheseff
  USING btree
  (cd_nom);
 
CREATE INDEX i_vm_syntheseff_dateobs
  ON v1_compat.vm_syntheseff
  USING btree
  (dateobs);
 
CREATE INDEX i_vm_syntheseff_altitude_retenue
  ON v1_compat.vm_syntheseff
  USING btree
  (altitude_retenue);
 
CREATE INDEX i_vm_syntheseff_id_organisme
  ON v1_compat.vm_syntheseff
  USING btree
  (id_organisme);

--On modifi l'id_source de Occtax pour ne pas avoir de conflit avec les id_source de la V&
UPDATE gn_synthese.t_sources 
SET id_source = (SELECT max(id_source) FROM v1_compat.bib_sources) +1
WHERE name_source = 'Occtax';
--on insert ensuite les sources de la V1
INSERT INTO gn_synthese.t_sources (
	id_source,
  name_source,
  desc_source,
  entity_source_pk_field
)
SELECT 
  id_source, 
  nom_source, 
  desc_source, 
  'historique.' || db_schema || '_' || db_table || '.' || db_field AS entity_source_pk_field,
FROM v1_compat.bib_sources


--------ETABLIR LES CORESPONDANCES DE NOMENCLATURE---------

--NATURE DE L'OBJET GEOGRAPHIQUE NAT_OBJ_GEO
--ne sait pas
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_precision, 'v1_compat.t_precisions' AS entity_source, 'id_precision' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_geo_object_nature' AS field_target, 3 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','NSP') AS id_nomenclature_cible 
FROM v1_compat.t_precisions;
--stationnel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St')
WHERE pk_source IN(1,2,3,4,10)
AND entity_source = 'v1_compat.t_precisions'
AND field_source = 'id_precision'
AND entity_target = 'gn_synthese.synthese'
AND field_target = 'id_nomenclature_geo_object_nature';
--inventoriel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In')
WHERE pk_source IN(5,6,7,8,9,11,13,14)
AND entity_source = 'v1_compat.t_precisions'
AND field_source = 'id_precision'
AND entity_target = 'gn_synthese.synthese'
AND field_target = 'id_nomenclature_geo_object_nature';


--TYPE DE REGROUPEMENT TYP_GRP
--observation
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_grp_typ' AS field_target, 24 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS') AS id_nomenclature_cible 
FROM v1_compat.bib_lots;
--Inventaire stationnel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA')
WHERE pk_source IN(105)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Ne sait pas
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP')
WHERE pk_source IN(111,107,47,8,24,43)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Point de prélèvement ou point d'observation.
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','POINT')
WHERE pk_source IN(9,10,17)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Passage (pour les comptages).
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','PASS')
WHERE pk_source IN(18,19,20)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';


--METHODE d'OBSERVATION METH_OBS 
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_obs_meth' AS field_target, 14 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--vu
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','0')
WHERE pk_source IN(2,5,6,8,9,10,11,12,14,16,18,21,22,23,26,27,29,30,31,33,34,35,37,38,101,102,103,201,204,208,209,214,215,217,221,222,224,226)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Entendu
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','1')
WHERE pk_source IN(4,7,207)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Empreintes
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','4')
WHERE pk_source IN(3,219)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--"Fèces/Guano/Epreintes"
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','6')
WHERE pk_source IN(205)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Nid/Gîte
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','8')
WHERE pk_source IN(13,15,17,19,20,216)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Restes de repas
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','12')
WHERE pk_source IN(211)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Autres
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','20')
WHERE pk_source IN(105,203,220)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Galerie/terrier
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','23')
WHERE pk_source IN(24,25)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';


--STATUT BIOLOGIQUE STATUT_BIO 
--non détermminé
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_status' AS field_target, 13 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_BIO','0') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--Reproduction
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_BIO','3')
WHERE pk_source IN(10,11,12,13,14,15,16,17,18,19,20,21,22,23,27,28,29,31,32,33,35,36,37,101,102,204,209,215,216,221,224,226)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_status';
--Hibernation
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_BIO','4')
WHERE pk_source IN(26)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_status';


--ETAT BIOLOGIQUE ETA_BIO
--vivant
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_condition' AS field_target, 7 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','2') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--trouvé mort
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('ETA_BIO','3')
WHERE pk_source IN(2)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_condition';
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_condition' AS field_target, 7 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','3') AS id_nomenclature_cible 
FROM v1_compat.bib_lots
WHERE id_lot IN(12,15);


--NATURALITE NATURALITE 
--sauvage
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_naturalness' AS field_target, 8 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NATURALITE','1') AS id_nomenclature_cible 
FROM v1_compat.bib_lots;
--inconnu (lot des partenaires, notamment de la LP0 PACA qui comporte des espèces férales)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NATURALITE','0')
WHERE pk_source IN(107,111,47,24)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_naturalness';


--PREUVE D'EXISTANCE PREUVE_EXIST 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 15
--non
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_exist_proof' AS field_target, 15 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--inconnu (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','NSP')
WHERE pk_source IN(11,12,13,17,99,107,111,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_exist_proof';


--STATUT DE VALIDATION STATUT_VALID
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 101
--probable (données PNE)
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_valid_status' AS field_target, 101 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--Certain - très probable (données PNE)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1')
WHERE pk_source IN(11,13,16,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_valid_status';
--inconnu (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_VALID','6')
WHERE pk_source IN(12,17,111)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_valid_status';


--NIVEAU DE DIFFUSION NIV_PRECIS 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 5
--Précises (données PNE). a affiner données par données une fois la sensibilité définie.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_diffusion_level' AS field_target, 5 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--aucune (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','4')
WHERE pk_source IN(11,12,17,111,107,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_diffusion_level';


--STADE DE VIE - AGE - PHENOLOGIE STADE_VIE 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 10
--Non renseigné. A affiner données par données en fonction de la structuration dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_life_stage' AS field_target, 10 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STADE_VIE','0') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--SEXE SEXE 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 9
--Non renseigné. A affiner données par données en fonction de la scturturation dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_sex' AS field_target, 9 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('SEXE','6') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--OBJET DU DENOMBREMENT OBJ_DENBR 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 6
--Ne sait pas. A affiner données par données en fonction de la structuration dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_obj_count' AS field_target, 6 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--individu (sources faune PNE)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','IND')
WHERE pk_source IN(1,2,3,4,5,6,7,8,9,10,13,14,99,200)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obj_count';


--TYPE DE DENOMBREMENT TYP_DENBR 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 21
--Ne sait pas. Pour toutes les sources. A voir si possibilité d'affiner
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_type_count' AS field_target, 21 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--SENSIBILITE
--A calculer ou définir au caspar cas. Mise à "NULL" en attendant


--STATUT DE L'OBSERVATION
--On n'a que des observations correspondant à de la présence dans la base PNE : id_nomenclature = 101


--FLOUTAGE
--PNE : A ma connaissance aucune donnée PNE ou partenaire n'a été dégradée : id_nomenclature_blurring = 200


--TYPE D'INFORMATION GEOGRAPHIQUE (géoréférencement ou rattachement) TYP_INF_GEO
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 23
--Géoréférencement.  
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_precision, 'v1_compat.t_precisions' AS entity_source, 'id_precision' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_info_geo_type' AS field_target, 23 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1') AS id_nomenclature_cible 
FROM v1_compat.t_precisions;
--rattachement
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','2')
WHERE pk_source IN(5,6,7,8,9,11,13,14)
AND entity_source = 'v1_compat.t_precisions' AND field_source = 'id_precision' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_info_geo_type';


ALTER TABLE gn_synthese.synthese DISABLE TRIGGER USER;
--DELETE FROM gn_synthese.synthese;
INSERT INTO gn_synthese.synthese (
  id_synthese, -- serial NOT NULL,
  unique_id_sinp, -- uuid,
  --unique_id_sinp_grp, -- uuid,
  id_source, --integer,
  entity_source_pk_value, --character varying,
  id_dataset, --integer,
  id_nomenclature_geo_object_nature, --integer DEFAULT gn_synthese.get_default_nomenclature_value(3), -- Correspondance nomenclature INPN = nat_obj_geo = 3
  id_nomenclature_grp_typ, --integer DEFAULT gn_synthese.get_default_nomenclature_value(24), -- Correspondance nomenclature INPN = typ_grp = 24
  id_nomenclature_obs_meth, --integer DEFAULT gn_synthese.get_default_nomenclature_value(14), -- Correspondance nomenclature INPN = methode_obs = 14
      --id_nomenclature_obs_technique, --integer DEFAULT gn_synthese.get_default_nomenclature_value(100), -- Correspondance nomenclature CAMPANULE = technique_obs = 100
  id_nomenclature_bio_status, --integer DEFAULT gn_synthese.get_default_nomenclature_value(13), -- Correspondance nomenclature INPN = statut_bio = 13
  id_nomenclature_bio_condition, --integer DEFAULT gn_synthese.get_default_nomenclature_value(7), -- Correspondance nomenclature INPN = etat_bio = 7
  id_nomenclature_naturalness, --integer DEFAULT gn_synthese.get_default_nomenclature_value(8), -- Correspondance nomenclature INPN = naturalite = 8
  id_nomenclature_exist_proof, --integer DEFAULT gn_synthese.get_default_nomenclature_value(15), -- Correspondance nomenclature INPN = preuve_exist = 15
  id_nomenclature_valid_status, --integer DEFAULT gn_synthese.get_default_nomenclature_value(101), -- Correspondance nomenclature GEONATURE = statut_valide = 101
  id_nomenclature_diffusion_level, --integer DEFAULT gn_synthese.get_default_nomenclature_value(5), -- Correspondance nomenclature INPN = niv_precis = 5 
  id_nomenclature_life_stage, --integer DEFAULT gn_synthese.get_default_nomenclature_value(10), -- Correspondance nomenclature INPN = stade_vie = 10
  id_nomenclature_sex, --integer DEFAULT gn_synthese.get_default_nomenclature_value(9), -- Correspondance nomenclature INPN = sexe = 9
  id_nomenclature_obj_count, --integer DEFAULT gn_synthese.get_default_nomenclature_value(6), -- Correspondance nomenclature INPN = obj_denbr = 6
  id_nomenclature_type_count, --integer DEFAULT gn_synthese.get_default_nomenclature_value(21), -- Correspondance nomenclature INPN = typ_denbr = 21
  id_nomenclature_sensitivity, --integer DEFAULT gn_synthese.get_default_nomenclature_value(16), -- Correspondance nomenclature INPN = sensibilite = 16
  id_nomenclature_observation_status, --integer DEFAULT gn_synthese.get_default_nomenclature_value(18), -- Correspondance nomenclature INPN = statut_obs = 18
  id_nomenclature_blurring, --integer DEFAULT gn_synthese.get_default_nomenclature_value(4), -- Correspondance nomenclature INPN = dee_flou = 4
  id_nomenclature_source_status, --integer DEFAULT gn_synthese.get_default_nomenclature_value(19), -- Correspondance nomenclature INPN = statut_source = 19
  id_nomenclature_info_geo_type, --integer DEFAULT gn_synthese.get_default_nomenclature_value(23), -- Correspondance nomenclature INPN = typ_inf_geo = 23
  count_min, --integer,
  count_max, --integer,
  cd_nom, --integer,
  nom_cite, -- character varying(255) NOT NULL,
  meta_v_taxref, -- character varying(50) DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'',NULL)'::character varying,
  sample_number_proof, -- text,
  digital_proof, -- text,
  non_digital_proof, -- text,  
  altitude_min, --integer,
  altitude_max, --integer,
  the_geom_4326, -- geometry(Geometry,4326),
  the_geom_point, -- geometry(Point,4326),
  the_geom_local, -- geometry(Geometry,2154),
  --id_area, --integer, C'est quoi ça ???
  date_min, -- date NOT NULL,
  date_max, -- date NOT NULL,
  validator, -- character varying(1000),
  validation_comment, -- text,
  observers, -- character varying(1000),
  determiner, -- character varying(1000),
  id_nomenclature_determination_method, -- character varying(20),
  comments, -- text,
  meta_validation_date, -- timestamp without time zone DEFAULT now(),
  meta_create_date, -- timestamp without time zone DEFAULT now(),
  meta_update_date, -- timestamp without time zone DEFAULT now(),
  last_action -- character(1)
)
WITH 
s AS (SELECT * FROM v1_compat.vm_syntheseff WHERE supprime = false)
,n3 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 3)
,n24 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 24)
,n14 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 14)
--,n100 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 100)
,n13 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 13)
,n7 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 7 AND entity_source = 'v1_compat.bib_criteres_synthese')
,n8 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 8)
,n15 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 15)
,n101 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 101)
,n5 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 5)
,n10 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 10)
,n9 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 9)
,n6 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 6)
,n21 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 21)
,n19 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 19)
,n23 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 23)
SELECT
  s.id_synthese
  ,uuid_generate_v4()
  ,s.id_source
  ,s.id_fiche_source
  ,s.id_lot
  ,COALESCE(n3.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','NSP')) AS id_nomenclature_geo_object_nature
  ,COALESCE(n24.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP')) AS id_nomenclature_grp_typ
  ,COALESCE(n14.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21')) AS id_nomenclature_obs_meth
  --,COALESCE(n100.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','000000')) AS id_nomenclature_obs_technique
  ,COALESCE(n13.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_BIO','0')) AS id_nomenclature_bio_status
  ,COALESCE(n7.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','1')) AS id_nomenclature_bio_condition
  ,COALESCE(n8.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NATURALITE','1')) AS id_nomenclature_naturalness
  ,COALESCE(n15.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','0')) AS id_nomenclature_exist_proof
  ,COALESCE(n101.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_VALID','6')) AS id_nomenclature_valid_status
  ,COALESCE(n5.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','4')) AS id_nomenclature_diffusion_level
  ,COALESCE(n10.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STADE_VIE','0')) AS id_nomenclature_life_stage
  ,COALESCE(n9.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('SEXE','6')) AS id_nomenclature_sex
  ,COALESCE(n6.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP')) AS id_nomenclature_obj_count
  ,COALESCE(n21.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP')) AS id_nomenclature_type_count
  ,NULL AS id_nomenclature_sensitivity
  ,ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr') AS id_nomenclature_observation_status
  ,ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON') AS id_nomenclature_blurring
  ,COALESCE(n19.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','NSP')) AS id_nomenclature_source_status
  ,COALESCE(n23.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1')) AS id_nomenclature_info_geo_type
  ,COALESCE(s.effectif_total, -1) AS count_min
  ,COALESCE(s.effectif_total, -1) AS count_max
  ,s.cd_nom
  ,'aucun' AS nom_cite -- voir avec la source
  ,'Taxref V11' AS meta_v_taxref
  ,NULL AS sample_number_proof
  ,NULL AS digital_proof
  ,NULL AS non_digital_proof
  ,s.altitude_retenue AS altitude_min
  ,s.altitude_retenue AS altitude_max --voir si besoin de faire des calculs pour les polygones et les lignes
  ,st_transform(s.the_geom_3857, 4326) AS the_geom_4326
  ,st_transform(s.the_geom_point, 4326) AS the_geom_point
  ,s.the_geom_local
  ,s.dateobs AS date_min
  ,s.dateobs AS date_max
  ,NULL AS validator
  ,NULL AS validation_comment
  ,observateurs AS observers
  ,determinateur AS determiner
  ,NULL AS id_nomenclature_determination_method --TODO
  ,s.remarques AS comments
  ,NULL AS meta_validation_date
  ,date_insert AS meta_create_date
  ,date_update AS meta_update_date
  ,derniere_action AS last_action
FROM s
LEFT JOIN n3 ON s.id_precision = n3.pk_source
LEFT JOIN n24 ON s.id_lot = n24.pk_source
LEFT JOIN n14 ON s.id_critere_synthese = n14.pk_source
--LEFT JOIN n100 ON s.id_critere_synthese = n100.pk_source
LEFT JOIN n13 ON s.id_critere_synthese = n13.pk_source
LEFT JOIN n7 ON s.id_critere_synthese = n7.pk_source
LEFT JOIN n8 ON s.id_lot = n8.pk_source
LEFT JOIN n15 ON s.id_lot = n15.pk_source
LEFT JOIN n101 ON s.id_source = n101.pk_source
LEFT JOIN n5 ON s.id_source = n5.pk_source
LEFT JOIN n10 ON s.id_source = n10.pk_source
LEFT JOIN n9 ON s.id_source = n9.pk_source
LEFT JOIN n6 ON s.id_source = n6.pk_source
LEFT JOIN n21 ON s.id_source = n21.pk_source
LEFT JOIN n19 ON s.id_source = n19.pk_source
LEFT JOIN n23 ON s.id_precision = n23.pk_source
LEFT JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
WHERE supprime = false
--AND id_source IN(107) -- voir table v1_compat.bib_sources
--LIMIT 10
;
--POST TRAITEMENT DES NOMENCLATURES SUR LA SYNTHESE
--UPDATE sur les champs de nomenclatures ayant plusieurs champs sources depuis la synthese V1
--PNE Etat biologique = "trouvé mort" sur les lots "Mortalité faune" et "Analyse pelotes rejection"
UPDATE gn_synthese.synthese
SET id_nomenclature_bio_condition = ref_nomenclatures.get_id_nomenclature('ETA_BIO','3')
WHERE id_dataset IN(12,15); --rapide dans ce cas mais à rendre plus générique avec la table "v1_compat.cor_synthese_v1_to_v2"

--DEFINITION DU SEXE SUR LES SOURCES COMPORTANT L'INFORMATION
--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','3') = mâle dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','3')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_cf 
	FROM v1_compat.t_releves_cf
	WHERE am > 0
	AND (af + ai + na +sai + jeune + yearling) = 0)
AND id_source IN(6,14) ;

--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','2') = femelle dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','2')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_cf 
	FROM v1_compat.t_releves_cf
	WHERE af > 0
	AND (am + ai + na + sai + jeune + yearling) = 0)
AND id_source IN(6,14);

--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','1') = indéterminé dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','1')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_cf 
	FROM v1_compat.t_releves_cf
	WHERE ai + sai + na  + jeune + yearling > 0
	AND (am + af ) = 0)
AND id_source IN(6,14);

--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','3') = mâle dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','3')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_inv 
	FROM v1_compat.t_releves_inv
	WHERE am > 0
	AND (af + ai + na) = 0)
AND id_source = 7;

--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','2') = femelle dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','2')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_inv 
	FROM v1_compat.t_releves_inv
	WHERE af > 0
	AND (am + ai + na) = 0)
AND id_source = 7;

--id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','1') = indéterminé dans contactfaune > 2012
UPDATE gn_synthese.synthese
SET id_nomenclature_sex = ref_nomenclatures.get_id_nomenclature('SEXE','1')
--SELECT count(*) FROM gn_synthese.synthese
WHERE entity_source_pk_value::integer IN
	(SELECT id_releve_inv 
	FROM v1_compat.t_releves_inv
	WHERE ai + na > 0
	AND (am + af ) = 0)
AND id_source = 7;

---_______________________---

ALTER TABLE gn_synthese.synthese ENABLE TRIGGER USER;

--mettre à jour la séquence de id_synthese
SELECT setval('gn_synthese.synthese_id_synthese_seq', (SELECT max(id_synthese)+1 FROM gn_synthese.synthese), true);

REFRESH MATERIALIZED VIEW CONCURRENTLY gn_synthese.vm_min_max_for_taxons;

--peupler cor_area_synthese
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
SELECT s.id_synthese, a.id_area
FROM ref_geo.l_areas a
JOIN gn_synthese.synthese s ON ST_INTERSECTS(s.the_geom_local, a.geom);


-----------------
--FLORE STATION--
-----------------
IMPORT FOREIGN SCHEMA florestation FROM SERVER geonature1server INTO v1_compat;

CREATE SCHEMA v1_florestation;

SET default_tablespace = '';
SET default_with_oids = false;

--TABLES--
CREATE TABLE v1_florestation.bib_supports
(
  id_support integer NOT NULL,
  nom_support character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);

CREATE TABLE v1_florestation.bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);

CREATE TABLE v1_florestation.bib_homogenes (
    id_homogene integer NOT NULL,
    nom_homogene character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.bib_microreliefs (
    id_microrelief integer NOT NULL,
    nom_microrelief character varying(128) NOT NULL
);

CREATE TABLE v1_florestation.bib_programmes_fs (
    id_programme_fs integer NOT NULL,
    nom_programme_fs character varying(255) NOT NULL
);

CREATE TABLE v1_florestation.bib_surfaces (
    id_surface integer NOT NULL,
    nom_surface character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_delphine (
    id_station bigint NOT NULL,
    id_delphine character varying(5) NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_microrelief (
    id_station bigint NOT NULL,
    id_microrelief integer NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);

CREATE SEQUENCE v1_florestation.cor_fs_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE v1_florestation.cor_fs_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    herb character(1),
    inf_1m character(1),
    de_1_4m character(1),
    sup_4m character(1),
    taxon_saisi character varying(150),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('v1_florestation.cor_fs_taxon_gid_seq'::regclass) NOT NULL,
    diffusable boolean DEFAULT true
);
CREATE SEQUENCE v1_florestation.cor_fs_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE v1_florestation.cor_fs_taxon_id_station_cd_nom_seq OWNED BY v1_florestation.cor_fs_taxon.id_station_cd_nom;
ALTER TABLE ONLY v1_florestation.cor_fs_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('v1_florestation.cor_fs_taxon_id_station_cd_nom_seq'::regclass);

CREATE TABLE v1_florestation.t_stations_fs (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_sophie character varying(5),
    id_programme_fs integer DEFAULT 999 NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    id_homogene integer,
    dateobs date,
    info_acces character varying(255),
    id_surface integer DEFAULT 1,
    complet_partiel character(1),
    meso_longitudinal integer DEFAULT 0,
    meso_lateral integer DEFAULT 0,
    canopee real DEFAULT 0,
    ligneux_hauts integer DEFAULT 0,
    ligneux_bas integer DEFAULT 0,
    ligneux_tbas integer DEFAULT 0,
    herbaces integer DEFAULT 0,
    mousses integer DEFAULT 0,
    litiere integer DEFAULT 0,
    altitude_saisie integer DEFAULT 0,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    remarques text,
    pdop real DEFAULT 0,
    supprime boolean DEFAULT false,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    srid_dessin integer,
    the_geom_3857 public.geometry(Point,3857),
    the_geom_local public.geometry(Point,2154),
    insee character(5),
    gid integer NOT NULL,
    validation boolean DEFAULT false,
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POINT'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154))
);
CREATE SEQUENCE v1_florestation.t_stations_fs_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE v1_florestation.t_stations_fs_gid_seq OWNED BY v1_florestation.t_stations_fs.gid;
ALTER TABLE ONLY v1_florestation.t_stations_fs ALTER COLUMN gid SET DEFAULT nextval('v1_florestation.t_stations_fs_gid_seq'::regclass);


--PRIMARY KEY--
ALTER TABLE ONLY v1_florestation.bib_supports
    ADD CONSTRAINT bib_supports_pkey PRIMARY KEY (id_support);

ALTER TABLE ONLY v1_florestation.bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);

ALTER TABLE ONLY v1_florestation.bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);

ALTER TABLE ONLY v1_florestation.bib_homogenes
    ADD CONSTRAINT pk_bib_homogenes PRIMARY KEY (id_homogene);

ALTER TABLE ONLY v1_florestation.bib_microreliefs
    ADD CONSTRAINT pk_bib_microreliefs PRIMARY KEY (id_microrelief);

ALTER TABLE ONLY v1_florestation.bib_programmes_fs
    ADD CONSTRAINT pk_bib_programmes_fs PRIMARY KEY (id_programme_fs);

ALTER TABLE ONLY v1_florestation.bib_surfaces
    ADD CONSTRAINT pk_bib_surfaces PRIMARY KEY (id_surface);

ALTER TABLE ONLY v1_florestation.cor_fs_delphine
    ADD CONSTRAINT pk_cor_fs_delphine PRIMARY KEY (id_station, id_delphine);

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT pk_cor_fs_microrelief PRIMARY KEY (id_station, id_microrelief);

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT pk_cor_fs_observateur PRIMARY KEY (id_role, id_station);

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT pk_cor_fs_taxons PRIMARY KEY (id_station, cd_nom);

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT pk_t_stations_fs PRIMARY KEY (id_station);


--FOREIGN KEY--
ALTER TABLE ONLY v1_florestation.cor_fs_delphine
    ADD CONSTRAINT cor_fs_delphine_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT cor_fs_microrelief_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT cor_fs_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT fk_cor_fs_microrelief_bib_microreliefs FOREIGN KEY (id_microrelief) REFERENCES v1_florestation.bib_microreliefs(id_microrelief) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT fk_cor_fs_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_de_1_4m FOREIGN KEY (de_1_4m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_herb FOREIGN KEY (herb) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_inf_1m FOREIGN KEY (inf_1m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_sup_4m FOREIGN KEY (sup_4m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_expositions FOREIGN KEY (id_exposition) REFERENCES v1_florestation.bib_expositions(id_exposition) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_homogenes FOREIGN KEY (id_homogene) REFERENCES v1_florestation.bib_homogenes(id_homogene) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_datasets FOREIGN KEY (id_lot) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_programmes_fs FOREIGN KEY (id_programme_fs) REFERENCES v1_florestation.bib_programmes_fs(id_programme_fs) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_supports FOREIGN KEY (id_support) REFERENCES v1_florestation.bib_supports(id_support) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_surfaces FOREIGN KEY (id_surface) REFERENCES v1_florestation.bib_surfaces(id_surface) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_sinp_datatype_protocols FOREIGN KEY (id_protocole) REFERENCES gn_meta.sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE;


--CONSTRAINTS--
ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT t_stations_fs_gid_key UNIQUE (gid);


--INDEX--
CREATE INDEX fki_t_stations_fs_bib_homogenes ON v1_florestation.t_stations_fs USING btree (id_homogene);

CREATE INDEX fki_t_stations_fs_gid ON v1_florestation.t_stations_fs USING btree (gid);
COMMENT ON INDEX v1_florestation.fki_t_stations_fs_gid IS 'pour le fonctionnement de qgis';

CREATE INDEX i_fk_t_stations_fs_bib_exposit ON v1_florestation.t_stations_fs USING btree (id_exposition);

CREATE INDEX i_fk_t_stations_fs_bib_program ON v1_florestation.t_stations_fs USING btree (id_programme_fs);

CREATE INDEX i_fk_t_stations_fs_bib_support ON v1_florestation.t_stations_fs USING btree (id_support);

CREATE INDEX index_cd_nom ON v1_florestation.cor_fs_taxon USING btree (cd_nom);

CREATE INDEX index_gist_t_stations_fs_the_geom_3857 ON v1_florestation.t_stations_fs USING gist (the_geom_3857);

CREATE INDEX index_gist_t_stations_fs_the_geom_local ON v1_florestation.t_stations_fs USING gist (the_geom_local);

--DATA--
INSERT INTO v1_florestation.bib_abondances SELECT * FROM v1_compat.bib_abondances;
INSERT INTO v1_florestation.bib_expositions SELECT * FROM v1_compat.bib_expositions;
INSERT INTO v1_florestation.bib_homogenes SELECT * FROM v1_compat.bib_homogenes;
INSERT INTO v1_florestation.bib_microreliefs SELECT * FROM v1_compat.bib_microreliefs;
INSERT INTO v1_florestation.bib_programmes_fs SELECT * FROM v1_compat.bib_programmes_fs;
INSERT INTO v1_florestation.bib_supports SELECT * FROM v1_compat.bib_supports;
INSERT INTO v1_florestation.bib_surfaces SELECT * FROM v1_compat.bib_surfaces;
INSERT INTO v1_florestation.t_stations_fs SELECT * FROM v1_compat.t_stations_fs;
INSERT INTO v1_florestation.cor_fs_taxon SELECT * FROM v1_compat.cor_fs_taxon;
INSERT INTO v1_florestation.cor_fs_observateur SELECT * FROM v1_compat.cor_fs_observateur;
INSERT INTO v1_florestation.cor_fs_microrelief SELECT * FROM v1_compat.cor_fs_microrelief;
INSERT INTO v1_florestation.cor_fs_delphine SELECT * FROM v1_compat.cor_fs_delphine;

--VIEWS--
CREATE VIEW v1_florestation.v_florestation_all AS
 SELECT cor.id_station_cd_nom AS indexbidon,
    fs.id_station,
    fs.dateobs,
    cor.cd_nom,
    btrim((tr.nom_valide)::text) AS nom_valid,
    btrim((tr.nom_vern)::text) AS nom_vern,
    public.st_transform(fs.the_geom_local, 2154) AS the_geom
   FROM ((v1_florestation.t_stations_fs fs
     JOIN v1_florestation.cor_fs_taxon cor ON ((cor.id_station = fs.id_station)))
     JOIN taxonomie.taxref tr ON ((cor.cd_nom = tr.cd_nom)))
  WHERE ((fs.supprime = false) AND (cor.supprime = false));

CREATE VIEW v1_florestation.v_florestation_patrimoniale AS
 SELECT cft.id_station_cd_nom AS indexbidon,
    fs.id_station,
    tx.nom_vern AS francais,
    tx.nom_complet AS latin,
    fs.dateobs,
    fs.the_geom_local
   FROM ((((v1_florestation.t_stations_fs fs
     JOIN v1_florestation.cor_fs_taxon cft ON ((cft.id_station = fs.id_station)))
     JOIN taxonomie.bib_noms n ON ((n.cd_nom = cft.cd_nom)))
     LEFT JOIN taxonomie.taxref tx ON ((tx.cd_nom = cft.cd_nom)))
     JOIN taxonomie.cor_taxon_attribut cta ON (((cta.cd_ref = n.cd_ref) AND (cta.id_attribut = 1) AND (cta.valeur_attribut = 'oui'::text))))
  WHERE ((fs.supprime = false) AND (cft.supprime = false))
  ORDER BY fs.id_station, tx.nom_vern;

CREATE VIEW v1_florestation.v_taxons_fs AS
 SELECT tx.cd_nom,
    tx.nom_complet
   FROM ((taxonomie.bib_noms n
     JOIN taxonomie.taxref tx ON ((tx.cd_nom = n.cd_nom)))
     JOIN taxonomie.cor_nom_liste cnl ON ((cnl.id_nom = n.id_nom)))
  WHERE ((n.id_nom IN ( SELECT cor_nom_liste.id_nom
           FROM taxonomie.cor_nom_liste
          WHERE (cor_nom_liste.id_liste = 500))) AND (cnl.id_liste = ANY (ARRAY[305, 306, 307, 308])));


--FUNCTIONS--
CREATE FUNCTION v1_florestation.application_rang_sp(id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer le cd_ref au rang espèce d'une sous-espèce, une variété ou une convariété à partir de son cd_nom
--si le cd_nom passé est d'un rang espèce ou supérieur (genre, famille...), la fonction renvoie le cd_ref du même rang que le cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011
  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='SSES' OR rang = 'VAR' OR rang = 'CVAR') THEN
	    IF(rang = 'SSES') THEN
		SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
	    END IF;
	    
	    IF(rang = 'VAR' OR rang = 'CVAR') THEN
		SELECT INTO sup cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
		SELECT INTO rangsup id_rang FROM taxonomie.taxref WHERE cd_nom = sup;
		IF(rangsup = 'ES') THEN
			SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
		IF(rangsup = 'SSES') THEN
			SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
	    END IF;
	ELSE
	   SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return ref;
  END;
$$;

CREATE FUNCTION v1_florestation.delete_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_stations_fs parce qu'il un delete cascade dans la fk id_station de cor_fs_taxon
--donc si on supprime la station, on supprime sa ou ces taxons relevés et donc ce trigger sera déclanché et fera le ménage dans la table synthese
BEGIN
        --on fait le delete dans synthese --TODO : adapter
        DELETE FROM gn_synthese.synthese WHERE id_source = 105 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
	RETURN old; 			
END;
$$;

CREATE FUNCTION v1_florestation.etiquette_utm(mongeom public.geometry) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
monx char(6);
mony char(7);
monetiquette char(24);
BEGIN
-- on prend le centroid du géom comme ça la fonction marchera avec tous les objets point ligne ou polygon
-- si la longitude en WGS84 degré decimal est < à 6 degrés on est en zone UTM 31
IF public.st_x(public.st_transform(public.st_centroid(mongeom),4326))< 6 then
	monx = CAST(public.st_x(public.st_transform(public.st_centroid(mongeom),32631)) AS integer)as string;
	mony = CAST(public.st_y(public.st_transform(public.st_centroid(mongeom),32631)) AS integer)as string;
	monetiquette = 'UTM31 x:'|| monx || ' y:' || mony;
ELSE
	-- sinon on est en zone UTM 32
	monx = CAST(public.st_x(public.st_transform(public.st_centroid(mongeom),32632)) AS integer)as string;
	mony = CAST(public.st_y(public.st_transform(public.st_centroid(mongeom),32632)) AS integer)as string;
	monetiquette = 'UTM32 x:'|| monx || ' y:' || mony;
END IF;
RETURN monetiquette;
END;
$$;

CREATE FUNCTION v1_florestation.florestation_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN	
new.date_insert= 'now';	 -- mise a jour de date insert
new.date_update= 'now';	 -- mise a jour de date update
--new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
--new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee
--new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig

--if new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  --new.altitude_retenue = new.altitude_sig;
--else
  --new.altitude_retenue = new.altitude_saisie;
--end if;

return new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			

END;
$$;

CREATE FUNCTION v1_florestation.florestation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    theinsee character varying(25);
    thealtitude integer;
BEGIN
--si aucun geom n'existait et qu'au moins un geom est ajouté, on créé les 2 geom
IF (old.the_geom_local is null AND old.the_geom_3857 is null) THEN
    IF (new.the_geom_local is NOT NULL) THEN
        new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
		new.srid_dessin = 2154;
    END IF;
    IF (new.the_geom_3857 is NOT NULL) THEN
        new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
    END IF;
    -- on calcul la commune...
    SELECT area_code INTO theinsee FROM (SELECT ref_geo.fct_get_area_intersection(new.the_geom_local,101) LIMIT 1) c;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
--si au moins un geom existait et qu'il a changé on fait une mise à jour
IF (old.the_geom_local is NOT NULL OR old.the_geom_3857 is NOT NULL) THEN
    --si c'est le 2154 qui existait on teste s'il a changé
    IF (old.the_geom_local is NOT NULL AND new.the_geom_local is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
            new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
            new.srid_dessin = 2154;
        END IF;
    END IF;
    --si c'est le 3857 qui existait on teste s'il a changé
    IF (old.the_geom_3857 is NOT NULL AND new.the_geom_3857 is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
            new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
            new.srid_dessin = 3857;
        END IF;
    END IF;
    -- on calcul la commune...
    SELECT area_code INTO theinsee FROM (SELECT ref_geo.fct_get_area_intersection(new.the_geom_local,101) LIMIT 1) c;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			-- on calcul l'altitude
			SELECT altitude_min INTO thealtitude FROM (SELECT ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
			new.altitude_retenue = thealtitude;-- mise à jour de l'altitude retenue
		else
			new.altitude_retenue = new.altitude_saisie;
		end if;
	END;	
END IF;
new.date_update= 'now';	 -- mise a jour de date insert
RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			
END;
$$;

--TODO gérer cor_observer_synthese
CREATE OR REPLACE FUNCTION v1_florestation.insert_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fiche RECORD;
    theobservers character varying(255);
    thenomcite character varying(1000);
    thetaxrefversion text;
    thevalidationstatus integer;
BEGIN
    --Récupération des données dans la table t_stations_fs
    SELECT INTO fiche * FROM v1_florestation.t_stations_fs WHERE id_station = new.id_station;
    --Récupération de la liste des observateurs
    SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM v1_florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --récuperation du nom_cite
    SELECT nom_complet INTO thenomcite FROM v1_florestation.v_taxons_fs WHERE cd_nom = new.cd_nom;
    --Récupération de la version taxref
    SELECT parameter_value INTO thetaxrefversion FROM gn_commons.t_parameters WHERE parameter_name = 'taxref_version';
    --Récupération du statut de validation
    IF (fiche.validation==true) THEN 
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
    ELSE
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') INTO thevalidationstatus;
    END IF;
    -- MAJ de la synthese
    INSERT INTO gn_synthese.synthese
    (
      id_source,
      entity_source_pk_value,
      id_dataset,
      id_nomenclature_geo_object_nature,
      id_nomenclature_grp_typ,
      id_nomenclature_obs_meth,
      id_nomenclature_bio_status,
      id_nomenclature_bio_condition,
      id_nomenclature_naturalness,
      id_nomenclature_exist_proof,
      id_nomenclature_valid_status,
      id_nomenclature_diffusion_level,
      id_nomenclature_life_stage,
      id_nomenclature_sex,
      id_nomenclature_obj_count,
      id_nomenclature_type_count,
      id_nomenclature_sensitivity,
      id_nomenclature_observation_status,
      id_nomenclature_blurring,
      id_nomenclature_source_status,
      id_nomenclature_info_geo_type,
      count_min,
      count_max,
      cd_nom,
      nom_cite,
      meta_v_taxref,
      altitude_min,
      altitude_max,
      the_geom_4326,
      the_geom_point,
      the_geom_local,
      date_min,
      date_max,
      observers,
      determiner,
      comments,
      last_action
    )
    VALUES
    ( 
      105, 
      new.gid,
      fiche.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      thevalidationstatus,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      ref_nomenclatures.get_id_nomenclature('STADE_VIE','1'),
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'),
      NULL,--todo sensitivity
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      -1,--count_min
      -1,--count_max
      new.cd_nom,
      thenomcite,
      thetaxrefversion,
      fiche.altitude_retenue,--altitude_min
      fiche.altitude_retenue,--altitude_max
      public.st_transform(fiche.the_geom_3857,4326),
      fiche.the_geom_local,
      public.st_transform(fiche.the_geom_3857,4326),
      fiche.dateobs,--date_min
      fiche.dateobs,--date_max
      theobservers,--observers
      theobservers,--determiner
      fiche.remarques,
      'c'
    );
RETURN NEW;       
END;
$$;

--TODO gérer cor_observer_synthese
CREATE FUNCTION v1_florestation.update_synthese_cor_fs_observateur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    myreleve RECORD;
    theobservers character varying(255);
BEGIN
    --Récupération de la liste des observateurs 
    --ici on va mettre à jour l'enregistrement dans synthese autant de fois qu'on insert dans cette table
    SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM v1_florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR myreleve IN SELECT gid FROM v1_florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
        --on fait le update du champ observateurs dans synthese
        UPDATE gn_synthese.synthese 
        SET 
            observers = theobservers,
            last_action = 'u'
        WHERE id_source = 105 AND entity_source_pk_value = myreleve.gid::character varying;
    END LOOP;
  RETURN NEW;       
END;
$$;


--TODO : gérer le supprime = false
CREATE FUNCTION v1_florestation.update_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--On ne fait qq chose que si l'un des champs de la table cor_fs_taxon concerné dans synthese a changé
IF (
        new.id_station <> old.id_station 
        OR new.gid <> old.gid 
        OR new.cd_nom <> old.cd_nom 
        OR new.supprime <> old.supprime 
    ) THEN
    --on fait le update dans synthese
    UPDATE gn_synthese.synthese 
    SET 
	entity_source_pk_value = new.gid,
	cd_nom = new.cd_nom,
	last_action = 'u'
    WHERE id_source = 105 AND entity_source_pk_value = old.gid::character varying;
END IF;
RETURN NEW; 			
END;
$$;

CREATE FUNCTION v1_florestation.update_synthese_stations_fs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
    thevalidationstatus integer;
BEGIN
FOR monreleve IN SELECT gid, cd_nom FROM v1_florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_stations_fs concerné dans synthese a changé
    IF (
            new.id_station <> old.id_station 
            OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
            OR ((NOT ST_EQUALS(old.the_geom_local, new.the_geom_local)) OR (new.the_geom_local is null and old.the_geom_local is NOT NULL) OR (new.the_geom_local is NOT NULL and old.the_geom_local is null))
            OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
            OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
	    OR ((new.validation <> old.validation) OR (new.validation is null and old.validation is NOT NULL) OR (new.validation is NOT NULL and old.validation is null))
            
        ) THEN
        --Récupération du statut de validation
	IF (new.validation==true) THEN 
		SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
	ELSE
		SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') INTO thevalidationstatus;
	END IF;
        --on fait le update dans synthese
        UPDATE gn_synthese.synthese 
        SET 
	    id_nomenclature_valid_status = thevalidationstatus,
            date_min = new.dateobs,
            date_max = new.dateobs,
            altitude_min = new.altitude_retenue,
            altitude_max = new.altitude_retenue,
            comments = new.remarques,
            last_action = 'u',
            the_geom_4326 = public.st_transform(new.the_geom_3857,4326),
            the_geom_local = new.the_geom_local,
            the_geom_point = public.st_transform(new.the_geom_3857,4326)
            --diffusable usage ou pas
        WHERE id_source = 105 AND entity_source_pk_value = old.gid::character varying;
    END IF;
END LOOP;
	RETURN NEW; 
END;
$$;

--TRIGGERS--
CREATE TRIGGER tri_delete_synthese_cor_fs_taxon AFTER DELETE ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.delete_synthese_cor_fs_taxon();

CREATE TRIGGER tri_insert BEFORE INSERT ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.florestation_insert();

CREATE TRIGGER tri_insert_synthese_cor_fs_observateur AFTER INSERT ON v1_florestation.cor_fs_observateur FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_cor_fs_observateur();

CREATE TRIGGER tri_insert_synthese_cor_fs_taxon AFTER INSERT ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.insert_synthese_cor_fs_taxon();

CREATE TRIGGER tri_update BEFORE UPDATE ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.florestation_update();

CREATE TRIGGER tri_update_synthese_cor_fs_taxon AFTER UPDATE ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_cor_fs_taxon();

CREATE TRIGGER tri_update_synthese_stations_fs AFTER UPDATE ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_stations_fs();





