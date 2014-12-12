<?php 

class sfSyntheseConfig extends sfActions
{
	public static $id_lot_cf = 1;
	public static $id_lot_inv = 3;
	public static $id_lot_mortalite = 2;
	public static $id_protocole_cf = 1;
	public static $id_protocole_inv = 3;
	public static $id_protocole_mortalite = 2;
	public static $id_source_cf = 1;
	public static $id_source_inv = 3;
	public static $default_pdop = -1;
    //organisme producteur et propriétaire des données
	public static $id_organisme = 2;
    //srid du fond de carte sur lequel les données sont saisies.
    //ATTENTION ! Cette valeur doit être laissée à 3857. Elle correspond au srid du geoportail. Elle est valable en métropole et outre mer.
    //Cette valeur est présente en dur dans le code de l'application. Elle correspond également aux champ des géométries utilisées dans la base pour consulter ou enregistrer des données.
	public static $srid_dessin = 3857;
    //srid local et des couches communes, secteurs, unites géographiques, isoline20 et zones à statuts
    //Ce srid est utilisé dans les exports. 
    //Lorsque la base de données est créée avec les scripts sql fournis (synthese_srid.sql), il faut choisir le script correspondant à la valeur portée ci-dessous. 
    //Idem pour le script d'insertion des données (synthese_data_srid.sql)
    //ATTENTION. Il faut mettre à jour le service wms interne de l'application qui utilise ce script. Fichier /var/www/localhost/private/trunk/synthesepn/wms/faune.map
	public static $srid_local = 2154;
  
  
  //Nom des applications et titres affichés
  public static $appname_main = 'Synthèse PNF';
  public static $appname_cf = 'Contact faune - Synthese PN';
  public static $appname_inv = 'Contact invertébrés - Synthese PN';
  public static $appname_mortalite =  'Mortalite faune - Synthese PN';
  public static $appname_synthese = 'Synthèse - Synthese PN';
  public static $apptitle_main = 'Parc nationaux - Gestion des données faune';

}
