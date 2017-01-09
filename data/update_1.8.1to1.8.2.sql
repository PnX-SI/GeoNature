-- Function: contactflore.synthese_update_fiche_cflore()

-- DROP FUNCTION contactflore.synthese_update_fiche_cflore();

CREATE OR REPLACE FUNCTION contactflore.synthese_update_fiche_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsourcecflore integer;
BEGIN

    --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' LOOP
	IF sources.url = 'cflore' THEN
	    idsourcecflore = sources.id_source;
	END IF;
    END LOOP;
	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactflore.t_releves_cflore WHERE id_cflore = old.id_cflore LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore);
		IF test IS NOT NULL THEN
			SELECT INTO mesobservateurs o.observateurs FROM contactflore.t_releves_cflore r
			JOIN contactflore.t_fiches_cflore f ON f.id_cflore = r.id_cflore
			LEFT JOIN (
				SELECT id_cflore, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactflore.cor_role_fiche_cflore c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cflore
			) o ON o.id_cflore = f.id_cflore
			WHERE r.id_releve_cflore = releves.id_releve_cflore;
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cflore||'-r'||releves.id_releve_cflore,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
				WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore) ;
			ELSE
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cflore||'-r'||releves.id_releve_cflore,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
			    WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore);
			END IF;
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--récupération des taxons protégés. 
--Cette opération aurait du être faite dans le script "update_1.7to1.8.sql" mais une coquille sur la requête l'a rendu inopérante.  
INSERT INTO taxonomie.cor_taxon_attribut
SELECT 2 as id_attribut, 'oui' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM save.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre3 = 'oui'
AND tx.cd_nom = tx.cd_ref;