===============================
SPECIFICITES INSTANCE NATIONALE
===============================

Voir la procédure d'installation de GeoNature et ses dépendances. 

Ne pas insérer les données exemple si possible. 

Attention, communes, zonages et MNT national ?

Taxons saisissables
===================

GeoNature n'interroge pas directement la table ``taxonomie.taxref`` pour permettre à l'administrateur de choisir quels taxons sont disponibles à la saisie. 

La table ``taxonomie.bib_noms`` contient tous les noms (noms de référence et synonymes) utilisables dans GeoNature. 
Il faut ensuite les ajouter à la liste ``Saisie possible`` (``id_liste=500`` de ``taxonomie.bib_listes``) pour rendre ces noms saisissables dans le module OCCTAX.

Une fois TaxHub installé, il faut donc remplir la table ``taxonomie.bib_noms`` avec les noms souhaités. Dans cet exemple, on va y insérer tous les taxons de TAXREF des rangs Genre et inférieurs :
 
::  

  DELETE FROM taxonomie.cor_nom_liste;
  DELETE FROM taxonomie.bib_noms;

  INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
  SELECT cd_nom, cd_ref, nom_vern
  FROM taxonomie.taxref
  WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
     'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR')

Il faut ensuite ajouter tous ces noms à la liste ``Saisie possible`` : 
 
::  
  
  INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
  SELECT 500,n.id_nom FROM taxonomie.bib_noms n
        
        
