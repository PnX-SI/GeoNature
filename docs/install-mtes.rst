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
  
  SQL

Il faut ensuite ajouter tous ces noms à la liste ``Saisie possible`` : 
 
::  
  
  SQL
        
        
