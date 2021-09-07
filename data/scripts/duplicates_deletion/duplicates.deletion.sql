---------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------OBSERVATION DES DOUBLONS -------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Création d'une vue matéralisée avec pour chaque donnée de la synthèse une signature et l'uuid associé
CREATE materialized view doublons_vm AS
SELECT concat(replace(concat(cast(date_min AS date)), '-', ''), replace(st_x(the_geom_4326)::text, '.',''), replace(st_y(the_geom_4326)::text, '.',''), cd_nom) AS signature, unique_id_sinp
FROM gn_synthese.synthese s
WHERE geometrytype(the_geom_4326)='POINT'
ORDER BY signature;

-- Si la vue est déjà créée 
REFRESH materialized VIEW doublons_vm

-- Observation de la vue matérialisée
SELECT * FROM doublons_vm;

-- Extraction de toutes les signatures avec au moins deux uuid différents 
CREATE OR REPLACE view nb_doublon_par_signature as 
SELECT   signature, COUNT(unique_id_sinp) AS nbr_doublon
FROM     doublons_vm
GROUP BY signature
HAVING   COUNT(unique_id_sinp) >= 2;

-- Observation de la vue 
SELECT * FROM nb_doublon_par_signature;

-- Nb de signatures avec doublon
SELECT count(*) FROM nb_doublon_par_signature;

-- Nb de doublons
SELECT sum(nbr_doublon)-count(nbr_doublon) FROM nb_doublon_par_signature;

-- Observation des doublons dans la synthèse pour une signature donnée 
SELECT * 
FROM gn_synthese.synthese 
WHERE gn_synthese.synthese.unique_id_sinp IN (SELECT unique_id_sinp
												FROM doublons_vm
												WHERE signature = 'valeurdelasignature')
                                                                        

---------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------SUPPRESSION DES DOUBLONS -------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

--Suppression des doublons pour chaque signature 
--Pour 1000 signatures le temps à compter est d'environ 3min

DO language plpgsql 
$$DECLARE s VARCHAR;
u uuid; 
nb_doublon INT;
tablesource VARCHAR; --Utile si la table des sources est implémentée 
BEGIN
    FOR s IN SELECT signature FROM nb_doublon_par_signature -- Pour chaque singature il est nécessaire de parcourir chaque uuid sauf le dernier
   	LOOP
   	raise notice 'Ma signature --> %', s;
    nb_doublon=(SELECT nbr_doublon FROM nb_doublon_par_signature WHERE signature = s);
    raise notice 'Nb doublon --> %', nb_doublon;
   		FOR u in SELECT unique_id_sinp FROM doublons_vm WHERE signature = s limit nb_doublon-1 -- POur chaque uuid sauf le dernier 
   		LOOP
   		    raise notice 'UUID --> %', u;
		
   		   -- Si toutes les tables sources sont implémentées --> décommenter et tester, IL FAUDRA SUREMENT TROUVER UN MOYEN DE TRANSFORMER LA VARIABLE tablesource EN NOM DE TABLE
			
   		   -- Retrouver la table source de la donnée

			/*
			 * tablesource=(SELECT entity_source_pk_field FROM gn_synthese.t_sources
			WHERE id_source = (SELECT syn.id_source FROM gn_synthese.synthese syn WHERE syn.unique_id_sinp = u));
			-- hist_embrun2016.embrun_2016.gid
			raise notice 'Table source --> %', tablesource;
		
			IF (tablesource is null) THEN
    			raise notice 'Table source nulle';
    			-- Supprimer la donnée de la table source (essayer de faire une seule avec la ligne précédente) 

    		else
    			raise notice 'Table source non nulle';
    			DELETE FROM tablesource 
				WHERE gid=(SELECT syn.entity_source_pk_value FROM gn_synthese.synthese syn WHERE unique_id_sinp = u);

			END IF;
			*/
		
		    -- Supprimer la donnée de la synthèse
		    DELETE FROM gn_synthese.synthese syn 
			    WHERE unique_id_sinp = u;

   		END LOOP;
    END LOOP;
END$$

