<?php
class syntheseActions extends sfGeonatureActions
{

    /**
	 * GeoJson encoder/decoder
	 *
	 * @var Service_GeoJson
	 */
	private $geojson;
	
	/**
	 * Create Service_GeoJson instance
	 *
	*/
	public function preExecute()
	{
        sfContext::getInstance()->getConfiguration()->loadHelpers('Partial');
        ini_set("memory_limit",'256M');
        $this->geojson = new Services_GeoJson();
	}
    
    public function executeIndexSynthese(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_synthese);
        }
        else{
           $this->redirect('@login');
        }
    }
    
    /**
	 * replace allcharacter with accents
	 *
	*/
	 private static function enleveaccents($chaine)
    {
     $array_source = array("À","Á","Â","Ã","Ä","Å","à","á","â","ã","ä","å","Ò","Ó","Ô","Õ","Ö","Ø","ò","ó","ô","õ","ö","ø","È","É","Ê","Ë","è","é","ê","ë","Ç","ç","Ì","Í","Î","Ï","ì","í","î","ï","Ù","Ú","Û","Ü","ù","ú","û","ü","ÿ","Ñ","ñ");
     $array_dest = array("a","a","a","a","a","a","a","a","a","a","a","a","o","o","o","o","o","o","o","o","o","o","o","o","e","e","e","e","e","e","e","e","c","c","i","i","i","i","i","i","i","i","u","u","u","u","u","u","u","u","y","n","n");
     $string = str_replace($array_source,$array_dest,$chaine);
     return $string;
    }
    
    private static function zipemesfichiers($zip,$filename)
    {
        $fp = fopen ($filename, 'r');
        $content = fread($fp, filesize($filename));
        fclose($fp);
        $zip->addfile($content, $filename);
        return $zip;
    }
    
    /**
   * Get GeoJSON list of releves
   * @param sfRequest $request
   * @return sfView::NONE
   */
    public function executeGet(sfRequest $request)
    {
        $this->getResponse()->setContentType('application/json');
        $params = $request->getParams();
        $nbreleves = SyntheseffTable::preSearch($params);
        if($nbreleves<10000){
            // GeoJSON list of relevés de la synthèse
            $userNom = $this->getUser()->getAttribute('userNom');
            $userPrenom = $this->getUser()->getAttribute('userPrenom');
            $statuscode = $this->getUser()->getAttribute('statuscode');
            $lesreleves = SyntheseffTable::search($params,$nbreleves,$userNom,$userPrenom,$statuscode );
            if (empty($lesreleves)){return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);}
            //si on est au dela de la limite, on renvoi un geojson avec une feature contenant une geometry null (voir lib/sfGeonatureActions.php)
            elseif($lesreleves=='trop'){return $this->renderText(sfGeonatureActions::$toManyFeatures);}
            else{
                return $this->renderText($lesreleves);
            }
        }
        else{return sfGeonatureActions::comptFeatures($nbreleves);}
    }
    
    public function executeXlsObs(sfRequest $request)
    {
        $params = $request->getParams();
        $lesobs = SyntheseffTable::listXlsObs($params);
        $csv_output = "id_synthese\tsource\tprogramme\tlot\torganisme\tdateobs\tobservateurs\ttaxon_francais\ttaxon_latin\tnom_valide\tfamille\tordre\tclasse\tphylum\tregne\tcd_nom\tcd_ref\tpatrimonial\tnom_critere_synthese\teffectif_total\tremarques\tsecteur\tcommune\tinsee\taltitude\tx_local\ty_local\tx_WGS84\ty_WGS84\ttype_objet\tgeometrie_source\tdiffusable";
        $csv_output .= "\n";
        foreach ($lesobs as $obs)
        {  
            $secteur = $obs['secteur'];     
            $commune = $obs['commune']; 
            $insee = $obs['insee'];
            $dateobs = $obs['dateobs'];
            $altitude = $obs['altitude'];
            $observateurs = $obs['observateurs'];
            $taxon_latin = $obs['taxon_latin'];
            $nom_valide = $obs['nom_valide'];
            $taxon_francais = $obs['taxon_francais'];
            $patrimonial = ($obs['patrimonial']=='t')?'oui':'non';
            $famille = $obs['famille'];
            $ordre = $obs['ordre'];
            $classe = $obs['classe'];
            $phylum = $obs['phylum'];
            $regne = $obs['regne'];
            $cd_nom = $obs['cd_nom'];
            $cd_ref = $obs['cd_ref'];
            $nom_critere_synthese = $obs['nom_critere_synthese'];
            $effectif_total = $obs['effectif_total'];
            $remarques = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $obs['remarques'] );
            $organisme = $obs['organisme'];
            $id_synthese = $obs['id_synthese'];
            $nom_source = $obs['nom_source'];
            $nom_programme = $obs['nom_programme'];
            $nom_lot = $obs['nom_lot'];
            $x_local = $obs['x_local'];
            $y_local = $obs['y_local'];
            $x_wgs84 = $obs['x_wgs84'];
            $y_wgs84 = $obs['y_wgs84'];
            $type_objet = 'point';
            $geom_type = ($obs['geom_type']=='ST_Point')?'point':'maille';
            $diffusable = ($obs['diffusable']=='t')?'oui':'non';
            $csv_output .= "$id_synthese\t$nom_source\t$nom_programme\t$nom_lot\t$organisme\t$dateobs\t$observateurs\t$taxon_francais\t$taxon_latin\t$nom_valide\t$famille\t$ordre\t$classe\t$phylum\t$regne\t$cd_nom\t$cd_ref\t$patrimonial\t$nom_critere_synthese\t$effectif_total\t$remarques\t$secteur\t$commune\t$insee\t$altitude\t$x_local\t$y_local\t$x_wgs84\t$y_wgs84\t$type_objet\t$geom_type\t$diffusable\n";
        }
        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=synthese_observations_".date("Y-m-d_His").".xls");
        print $csv_output;
        exit;
    }
    
    public function executeXlsStatus(sfRequest $request)
    {
        $params = $request->getParams();
        $statuts = SyntheseffTable::listXlsStatus($params);
        $csv_output = "cd_ref\tclasse\tordre\tfamille\ttaxon_francais\ttaxon_latin\ttype_protection\tpatrimonial\ttaxon_url\tstatut_resume\tstatut_titre\tstatut_article\tdate_texte\turl_texte";
        $csv_output .= "\n";
        foreach ($statuts as $statut)
        {  
            $taxon_francais = $statut['taxon_francais'];     
            $taxon_latin = $statut['taxon_latin']; 
            $famille = $statut['famille'];
            $ordre = $statut['ordre'];
            $classe = $statut['classe'];
            $cd_ref = $statut['cd_ref'];
            $patrimonial = ($statut['patrimonial']=='t')?'oui':'non';
            $type_protection = $statut['type_protection'];
            $article = $statut['article'];
            $arrete = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $statut['arrete'] );
            $intitule = $statut['intitule'];
            $date_arrete = $statut['date_arrete'];
            $url_texte = $statut['url_texte'];
            $url_taxon = $statut['url_taxon'];
            $csv_output .= "$cd_ref\t$classe\t$ordre\t$famille\t$taxon_francais\t$taxon_latin\t$type_protection\t$patrimonial\t$url_taxon\t$intitule\t$arrete\t$article\t$date_arrete\t$url_texte\n";      
        }

        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=synthese_statuts_".date("Y-m-d_His").".xls");
        print $csv_output;
        exit;
    
    }
    
    public function executeShp(sfRequest $request)
    {
        //Récupération des paramètres de connexion à la base
        $ogrConnexionString = $this::getOgrConnexionString();
        $params = $request->getParams(); // récup des paramètres de la requête utilisateur
        $path = 'exportshape/'; //chemin public pour téléchargement du fichier zip

        $madate = date("Y-m-d_His");
        $srid_local_export = sfGeonatureConfig::$srid_local;
        
        //pour les points
        $sql = SyntheseffTable::listShp($params,'ST_Point'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/synthese_'.$madate.'_points.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\"";
        
        system($command);//execution de la commande
        //pour les lignes
        $sql = SyntheseffTable::listShp($params,'ST_Line'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/synthese_'.$madate.'_lignes.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\"";
        // return print_r($command);        
        system($command);//execution de la commande
        
        //pour les mailles
        $sql = SyntheseffTable::listShp($params,'ST_Polygon'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/synthese_'.$madate.'_mailles.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\""; 
        system($command);//execution de la commande

        //pour les centroids
        $sql = SyntheseffTable::listShp($params,'centroid'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/synthese_'.$madate.'_centroids.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\""; 
        system($command);//execution de la commande
                
        //on zipe le tout
        $zip = new zipfile(); 
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_points.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_points.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_points.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_points.dbf') ;
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_lignes.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_lignes.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_lignes.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_lignes.dbf') ;
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_mailles.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_mailles.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_mailles.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_mailles.dbf') ;
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_centroids.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_centroids.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_centroids.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'synthese_'.$madate.'_centroids.dbf') ;
        $archive = $zip->file();
        header('Content-Type: application/x-zip');      
        header('Content-Disposition: inline; filename=synthese_'.$madate.'.zip') ;
        echo $archive ; //on retourne le contenu du zip à l'utilisateur
        unlink($path.'synthese_'.$madate.'_points.shp');       
        unlink($path.'synthese_'.$madate.'_points.shx');       
        unlink($path.'synthese_'.$madate.'_points.prj');       
        unlink($path.'synthese_'.$madate.'_points.dbf');
        unlink($path.'synthese_'.$madate.'_lignes.shp');       
        unlink($path.'synthese_'.$madate.'_lignes.shx');       
        unlink($path.'synthese_'.$madate.'_lignes.prj');       
        unlink($path.'synthese_'.$madate.'_lignes.dbf');
        unlink($path.'synthese_'.$madate.'_mailles.shp');       
        unlink($path.'synthese_'.$madate.'_mailles.shx');       
        unlink($path.'synthese_'.$madate.'_mailles.prj');       
        unlink($path.'synthese_'.$madate.'_mailles.dbf');
        unlink($path.'synthese_'.$madate.'_centroids.shp');       
        unlink($path.'synthese_'.$madate.'_centroids.shx');       
        unlink($path.'synthese_'.$madate.'_centroids.prj');       
        unlink($path.'synthese_'.$madate.'_centroids.dbf');
        exit;
    }
    
    
    private static function getOgrConnexionString() {
      
      $connexion = Doctrine_Manager::getInstance()->getConnections('all');
      $options = array_pop($connexion)->getOptions();
      preg_match('/host=(.*);dbname=(.*)$/', $options['dsn'], $host);
      
      return 'PG:"host='.$host[1].' user='.$options['username'].' dbname='.$host[2].' password='.$options['password'].'"';
      
    }
    
    private static function unzip($file, $path='', $newname, $effacer_zip=false)
    {
        /*Méthode qui permet de décompresser un fichier zip $file dans un répertoire de destination $path
        et qui retourne un tableau contenant la liste des fichiers extraits
        Si $effacer_zip est égal à true, on efface le fichier zip d'origine $file*/
        $tab_liste_fichiers = array(); //Initialisation
        $zip = zip_open($file);
        if ($zip)
        {
            while ($zip_entry = zip_read($zip)) //Pour chaque fichier contenu dans le fichier zip
            {
                if (zip_entry_filesize($zip_entry) > 0)
                {
                    // $complete_path = $path.dirname(zip_entry_name($zip_entry));
                    /*On supprime les éventuels caractères spéciaux et majuscules*/
                    $nom_fichier = zip_entry_name($zip_entry);
                    // $nom_fichier = strtr($nom_fichier,"ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ","AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn");
                    // $nom_fichier = strtolower($nom_fichier);
                    // $nom_fichier = ereg_replace('[^a-zA-Z0-9.]','-',$nom_fichier);
                    $ext = end(explode('.', $nom_fichier));//récup de l'extention
                    $nom_fichier = $newname.'.'.$ext;//on renome le fichier avec le nom passé en paramètre
                    $complete_name = $path.$nom_fichier; //Nom et chemin de destination
                    // if(!file_exists($complete_path))
                    // {
                        // $tmp = '';
                        // foreach(explode('/',$complete_path) AS $k)
                        // {
                            // $tmp .= $k.'/';
                            // if(!file_exists($tmp)){ mkdir($tmp, 0755); }
                        // }
                    // }
                    /*On extrait le fichier*/
                    if (zip_entry_open($zip, $zip_entry, "r"))
                    {
                        $fd = fopen($complete_name, 'w');
                        fwrite($fd, zip_entry_read($zip_entry, zip_entry_filesize($zip_entry)));
                        fclose($fd);
                        zip_entry_close($zip_entry);
                        // chmod($complete_name, 0777);//on change les droits
                    }
                }
            }
            zip_close($zip);
            /*On efface éventuellement le fichier zip d'origine*/
            if ($effacer_zip === true){unlink($file);}
        }
    }  
    public function executeUploadFileShp(sfRequest $request)
    {
        // $gpx = self::uploadGpx($request);
        //récupération des variables postées
        $randomnumber = $request->getParameter('randomnumber');
        $username =   str_replace(' ','_',$request->getParameter('username'));//récupération du nom utilisateur
        $file = $request->getFiles('nom_fichier');//récupération du fichier
        $chemin =  sfConfig::get('sf_web_dir')."/uploads/shapes/";//chemin dans l'appli où stocker les fichiers zip des shapes et ou sera généré le gml.
        $monshape = $username.'.shp'; //nom du fichier shape
        $mongml = $username."_".$randomnumber.'.gml'; //nom du fichier gml
        $extensionlistok = array(".zip");
        foreach ($extensionlistok as $item) {
            if(preg_match("/$item\$/i", $file['name'])) {
                $nom_fichier = $username.".zip"; //renommer le fichier avec le nom de l'utilisateur et un random
                $chemin_fichier_zip = $chemin.$nom_fichier; //nom du fichier avec son chemin
                //si la copie du fichier temporaire téléchargé réussie, on le place dans son répertoire 
                if(rename($file['tmp_name'], $chemin_fichier_zip)){
                    // chmod($chemin_fichier_zip, 0777);//on change les droits
                    self::unzip($chemin_fichier_zip,$chemin,$username,true);// on dezippe et on efface le fichier zip
                    $msg='{success: true ,data:"Le fichier zip de la shape a été téléchargé avec succès."}';
                    //génération du gml par ogr2ogr à partir du .shp généré ci-dessus
                    system('ogr2ogr -f "GML" '.$chemin.$mongml.' '.$chemin.$monshape);
                    chmod($chemin.$mongml, 0755);//on change les droits
                    unlink($chemin.$monshape);
                    unlink($chemin.$username.'.shx');
                    unlink($chemin.$username.'.prj');
                    unlink($chemin.$username.'.qpj');
                    unlink($chemin.$username.'.dbf');
                    unlink($chemin.$username.'_'.$randomnumber.'.xsd');
                }
                else{$msg='{success: false ,errors:"Le fichier zip de la shape n\'a pas pu être téléchargé."}';}
            }
            else{$msg='{success: false ,errors:"Le fichier comporte une extention non valide. Utilisez une extention .zip uniquement."}';}
        }
        return $this->renderText($msg);
    }
    
    /**
	 * return a json message for the GeoJson web api service
	 *
	*/
	private static function return_content($success ,$msg ,$id_synthese ,$id_source ,$id_fiche_source)
    {
        $status = array();
        $status["success"] = $success;
        $status["message"] = $msg;
        $status["id_synthese"] = $id_synthese;
        $status["id_source"] = $id_source;
        $status["id_fiche_source"] = $id_fiche_source;
        return $status;
    }
    /**
	 * Test if given JSON is valid or not
	 *
	*/
	private static function json_test($json)
    {
        $json_status = 'Erreur JSON';
        json_decode($json);
        switch (json_last_error()) {
            case JSON_ERROR_NONE:
                $json_status=true ;
                break;
            case JSON_ERROR_DEPTH:
                $json_status.= ' - Profondeur maximale atteinte';
                break;
            case JSON_ERROR_STATE_MISMATCH:
                $json_status.= ' - Inadéquation des modes ou underflow';
                break;
            case JSON_ERROR_CTRL_CHAR:
                $json_status.= ' - Erreur lors du contrôle des caractères';
                break;
            case JSON_ERROR_SYNTAX:
                $json_status.= ' - Erreur de syntaxe ; JSON malformé';
                break;
            case JSON_ERROR_UTF8:
                $json_status.= ' - Caractères UTF-8 malformés, probablement une erreur d\'encodage';
                break;
            default:
                $json_status.= ' - Erreur inconnue';
            break;
        }
        return $json_status;
    }
    
    public function executeAdd(sfRequest $request)
    {
        // initialisation des valeurs retournées par la fonction
        $success = null;
        $msg = "";
        $id_synthese = null;
        $id_source = null;
        $id_fiche_source = null;
        
        // récupération des paramètres transmis
        $token = $request->getParameter('token');
        $json = $request->getParameter('json');
        
        // on test si le token est valide
        if($token=="05ff)giOklRTb;sedqw4xaz56Tmoi5!"){    
            // test si le json est valid
            if(self::json_test($json) != 1){
                $success = false;
                $msg = self::json_test($json);
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }

            // récupération des valeurs transmises dans le json
            $synthese_val = json_decode($json, true);
            $id_source = $synthese_val['properties']['id_source'];
            $id_fiche_source = $synthese_val['properties']['id_fiche_source'];
            $code_fiche_source = $synthese_val['properties']['code_fiche_source'];
            $id_organisme = $synthese_val['properties']['id_organisme'];
            $id_protocole = $synthese_val['properties']['id_protocole'];
            $id_precision = $synthese_val['properties']['id_precision'];
            $id_lot = $synthese_val['properties']['id_lot'];
            $dateobs = $synthese_val['properties']['dateobs'];
            $cd_nom = $synthese_val['properties']['cd_nom'];
            $effectif_total = $synthese_val['properties']['effectif_total'];
            $insee = $synthese_val['properties']['insee'];
            $altitude = $synthese_val['properties']['altitude'];
            $observateurs = $synthese_val['properties']['observateurs'];
            $determinateur = $synthese_val['properties']['determinateur'];
            $remarques = $synthese_val['properties']['remarques'];
            $id_critere_synthese = $synthese_val['properties']['id_critere_synthese'];
            $json_geom = json_encode($synthese_val['geometry']);
        
            // on teste les champs obligatoires ; si soucis on retourne un message d'erreur qui stoppe le script
            if($id_organisme === null || $id_organisme === '' || $id_organisme < 0){
                $success = false;
                $msg = "Opération stoppée : L'identifiant de l'organisme est obligatoire ; valeur attendue = id_organisme";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($id_protocole === null || $id_protocole === '' || $id_protocole < 0){
                $success = false;
                $msg = "Opération stoppée : L'identifiant du protocole est obligatoire ; valeur attendue = id_protocole";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($id_precision === null || $id_precision === '' || $id_precision < 0){
                $success = false;
                $msg = "Opération stoppée : L'identifiant de la précision de saisie est obligatoire ; valeur attendue = id_precision";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($id_critere_synthese === null || $id_critere_synthese === '' || $id_critere_synthese < 0){
                $success = false;
                $msg = "Opération stoppée : L'identifiant du critère d'observation est obligatoire ; valeur attendue = id_critere_synthese";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($cd_nom === null || $cd_nom === '' || $cd_nom < 0){
                $success = false;
                $msg = "Opération stoppée : Le taxon est obligatoire ; valeur attendue = cd_nom";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($dateobs == null || $dateobs ==''){
                $success = false;
                $msg = "Opération stoppée : La date de l'observation est obligatoire ; valeur attendue = dateobs";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($observateurs == null || $observateurs ==''){
                $success = false;
                $msg = "Opération stoppée : Au moins un observateur est obligatoire ; valeur attendue = observateurs";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            if($json_geom == null || $json_geom ==''){
                $success = false;
                $msg = "Opération stoppée : La localisation est obligatoire ; valeur attendue = geometry. Voir les spécifications du format GeoJSON";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            
            // on teste si le ou les paramètres nécessaires à la création sont bien fournis
            $where = "WHERE ";
            if($id_source !== null && $id_source >= 0 && $id_fiche_source != null && $id_fiche_source!= ''){
                $where.= "id_source = ".$id_source." AND id_fiche_source = ".$id_fiche_source."::text";
            }
            else{
                $success = false;
                $msg = "Opération stoppée : identifiants nécessaires à la création de l'enregistrement non fournis.";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            
            $synthese = new Syntheseff();
            $synthese->id_source = $id_source;
            $synthese->id_fiche_source = $id_fiche_source;
            $synthese->code_fiche_source = $code_fiche_source;
            $synthese->id_organisme = $id_organisme;
            $synthese->id_protocole = $id_protocole;
            $synthese->id_precision = $id_precision;
            $synthese->id_lot = $id_lot;
            $synthese->id_critere_synthese = $id_critere_synthese;
            $synthese->dateobs = $dateobs;
            $synthese->cd_nom = $cd_nom;
            $synthese->effectif_total = $effectif_total;
            $synthese->insee = $insee;
            $synthese->altitude_retenue = $altitude;
            $synthese->observateurs = $observateurs;
            $synthese->determinateur = $determinateur;
            $synthese->remarques = $remarques;
            $synthese->derniere_action = 'c';
            $synthese->supprime = false;
            
            // on peut lancer l'action sur la base de données
            try{
                $synthese->save();
                $id_synthese = $synthese->getIdSynthese();
                $monjson = "ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857)";
                $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                // insertion des géometries
                // doctrine ne gère pas le  type geometry. Du coup on le fait en Update en SQL.
                $sql = "UPDATE synthese.syntheseff 
                        SET the_geom_3857 = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857)
                        ,the_geom_local = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),".sfGeonatureConfig::$srid_local.")
                        ,the_geom_point = ST_PointOnSurface(ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857))
                        WHERE id_synthese = ".$id_synthese;
                $dbh->query($sql);
                // test si l'enregistrement existe dans la table synthese.syntheseff
                $sql = "SELECT id_synthese, id_source, id_fiche_source FROM synthese.syntheseff ".$where;
                $result = $dbh->query($sql)->fetchAll();
                // si l'enregistrement existe dans la table synthese.syntheseff c'est qu'il a bien été créé
                if($result[0]['id_synthese']>0){
                    $id_source = $result[0]['id_source'];
                    $id_fiche_source = $result[0]['id_fiche_source'];
                    $success = true;
                    $msg = "insertion dans la table syntheseff avec l'id_synthese : ".$id_synthese;
                }
                else{
                    $success = false;
                    $msg = "Une erreur s'est produite. L'observation n'a pas été enregistrée.";
                }
            }
            catch(Exception $e) {
                $success = false;
                $msg = "Une erreur s'est produite :".$e->getMessage();
            }
        }
        // si le token n'est pas valide
        else{
            $success = false;
            $msg = "Opération stoppée : identification incorrecte";
            return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
        }
        return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
    }
    
    public function executeUpdate(sfRequest $request)
    {
        // initialisation des valeurs retournées par la fonction
        $success = null;
        $msg = "";
        $id_synthese = null;
        $id_source = null;
        $id_fiche_source = null;
        
        // récupération des paramètres transmis
        $token = $request->getParameter('token');
        $json = $request->getParameter('json');
        
        // on test si le token est valide
        if($token=="05ff)giOklRTb;sedqw4xaz56Tmoi5!"){
            //test si le json est valid
            if(self::json_test($json) != 1){
                $success = false;
                $msg = self::json_test($json);
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }

            // récupération des valeurs transmises dans le json
            // comme les valeurs sont facultatives, on test systématiquement si elles sont passées ou non
            $synthese_val = json_decode($json, true);
            if($synthese_val['properties']['id_source'] !== null && $synthese_val['properties']['id_source'] >= 0){$id_source = $synthese_val['properties']['id_source'];}
            if($synthese_val['properties']['id_fiche_source'] !== null && $synthese_val['properties']['id_fiche_source'] !== ''){$id_fiche_source = $synthese_val['properties']['id_fiche_source'];}
            if($synthese_val['properties']['code_fiche_source'] !== null && $synthese_val['properties']['code_fiche_source'] !== ''){$code_fiche_source = $synthese_val['properties']['code_fiche_source'];}
            if($synthese_val['properties']['id_organisme'] !== null && $synthese_val['properties']['id_organisme'] >=0){$id_organisme = $synthese_val['properties']['id_organisme'];}
            if($synthese_val['properties']['id_protocole'] !== null && $synthese_val['properties']['id_protocole'] >=0){$id_protocole = $synthese_val['properties']['id_protocole'];}
            if($synthese_val['properties']['id_precision'] !== null && $synthese_val['properties']['id_precision'] >=0){$id_precision = $synthese_val['properties']['id_precision'];}
            if($synthese_val['properties']['id_precision'] !== null && $synthese_val['properties']['id_precision'] >=0){$id_lot = $synthese_val['properties']['id_lot'];}
            if($synthese_val['properties']['dateobs'] !== null && $synthese_val['properties']['dateobs'] !== ''){$dateobs = $synthese_val['properties']['dateobs'];}
            if($synthese_val['properties']['cd_nom'] !== null && $synthese_val['properties']['cd_nom'] >=0){$cd_nom = $synthese_val['properties']['cd_nom'];}
            if($synthese_val['properties']['effectif_total'] !== null && $synthese_val['properties']['effectif_total'] >=0){$effectif_total = $synthese_val['properties']['effectif_total'];}
            if($synthese_val['properties']['altitude'] !== null && $synthese_val['properties']['altitude'] !== ''){$insee = $synthese_val['properties']['insee'];}
            if($synthese_val['properties']['altitude'] !== null && $synthese_val['properties']['altitude'] !== ''){$altitude = $synthese_val['properties']['altitude'];}
            if($synthese_val['properties']['observateurs'] !== null && $synthese_val['properties']['observateurs'] !== ''){$observateurs = $synthese_val['properties']['observateurs'];}
            if($synthese_val['properties']['determinateur'] !== null && $synthese_val['properties']['determinateur'] !== ''){$determinateur = $synthese_val['properties']['determinateur'];}
            if($synthese_val['properties']['remarques'] !== null && $synthese_val['properties']['remarques'] !== ''){$remarques = $synthese_val['properties']['remarques'];}
            if($synthese_val['properties']['id_critere_synthese'] !== null && $synthese_val['properties']['id_critere_synthese'] >=0){$id_critere_synthese = $synthese_val['properties']['id_critere_synthese'];}
            if($synthese_val['geometry'] !== null && $synthese_val['geometry']!==''){$json_geom = json_encode($synthese_val['geometry']);}
            
            // on teste si le ou les paramètres nécessaires à l'identification de la données sont bien fournis
            $where = "WHERE ";
            if($request->hasParameter('id_synthese') && $request->getParameter('id_synthese') != 0){
                $id_synthese = $request->getParameter('id_synthese');
                $where .= "id_synthese = ".$id_synthese;
            }
            elseif(isset($id_fiche_source) && isset($id_fiche_source)){
                $where.= "id_source = ".$id_source." AND id_fiche_source = ".$id_fiche_source."::text";
            }
            else{
                $success = false;
                $msg = "Opération stoppée : identifiants nécessaires à la création de l'enregistrement non fournis.";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            // test si l'enregistrement existe dans la table synthese.syntheseff
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "SELECT id_synthese FROM synthese.syntheseff ".$where;
            $result = $dbh->query($sql)->fetchAll();
            // si l'enregistrement existe dans la table synthese.syntheseff on récupère ses informations d'identification unique et on met à jour les champs
            if($result[0]['id_synthese']>0){
                $id_synthese = $result[0]['id_synthese'];
                // on récupère l'enregistrement et on met à jour
                $synthese = Doctrine::getTable('Syntheseff')->find($id_synthese);
                if(isset($code_fiche_source)){$synthese->code_fiche_source = $code_fiche_source;}
                if(isset($id_organisme)){$synthese->id_organisme = $id_organisme;}
                if(isset($id_protocole)){$synthese->id_protocole = $id_protocole;}
                if(isset($id_precision)){$synthese->id_precision = $id_precision;}
                if(isset($id_lot)){$synthese->id_lot = $id_lot;}
                if(isset($id_critere_synthese)){$synthese->id_critere_synthese = $id_critere_synthese;}
                if(isset($dateobs)){$synthese->dateobs = $dateobs;}
                if(isset($cd_nom)){$synthese->cd_nom = $cd_nom;}
                if(isset($effectif_total)){$synthese->effectif_total = $effectif_total;}
                if(isset($insee)){$synthese->insee = $insee;}
                if(isset($altitude)){$synthese->altitude_retenue = $altitude;}
                if(isset($observateurs)){$synthese->observateurs = $observateurs;}
                if(isset($determinateur)){$synthese->determinateur = $determinateur;}
                if(isset($remarques)){$synthese->remarques = $remarques;}
                $synthese->derniere_action = 'u';
            }
            // si l'enregistrement n'existe pas dans la table synthese.syntheseff
            else{
                $success = false;
                $msg = "Les informations d'identification de l'observation ne correspondent à aucune donnée dans la table synthese.syntheseff.";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            // on peut lancer l'action sur la base de données
            try{
                $synthese->save();
                if($json_geom !== null && $json_geom !== ''){
                    $monjson = "ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857)";
                    // update des géometries
                    // doctrine ne gère pas le type geometry. Du coup on le fait en Update en SQL.
                    $sql = "UPDATE synthese.syntheseff 
                            SET the_geom_3857 = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857)
                            ,the_geom_local = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),".sfGeonatureConfig::$srid_local.")
                            ,the_geom_point = ST_PointOnSurface(ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('".$json_geom."'),4326),3857))
                            WHERE id_synthese = ".$id_synthese;
                    $dbh->query($sql);
                }
                $success = true;
                $msg = "La modification dans la table syntheseff avec l'id_synthese : ".$id_synthese." a bien été réalisée";
            }
            catch(Exception $e) {
                $success = false;
                $msg = "Une erreur s'est produite :".$e->getMessage();
            }
        }
        // si le token n'est pas valide
        else{
            $success = false;
            $msg = "Opération stoppée : identification incorrecte";
            return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
        }
        
        return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
    }
    
    public function executeDelete(sfRequest $request)
    {
        // initialisation des valeurs retournées par la fonction
        $success;
        $msg = "";
        $id_synthese = null;
        $id_source = null;
        $id_fiche_source = null;
        
        // récupération des paramètres transmis
        $token = $request->getParameter('token'); 
        $json = $request->getParameter('json');
        
        // on test si le token est valide
        if($token=="05ff)giOklRTb;sedqw4xaz56Tmoi5!"){
            // test si le json est valid
            if(self::json_test($json) != 1){
                $success = false;
                $msg = self::json_test($json);
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            $synthese_val = json_decode($json, true);
            
            // on teste si le ou les paramètres d'identification de l'enregistrement sont bien fournis
            $where = "WHERE ";
            if($request->hasParameter('id_synthese') && $request->getParameter('id_synthese') != 0){
                $id_synthese = $request->getParameter('id_synthese');
                $where .= "id_synthese = ".$id_synthese;
            }
            elseif($synthese_val['id_source'] != null && $synthese_val['id_source'] >= 0 && $synthese_val['id_fiche_source'] != null && $synthese_val['id_fiche_source'] != ''){
                $id_source = $synthese_val['id_source'];
                $id_fiche_source = $synthese_val['id_fiche_source'];
                $where.= "id_source = ".$id_source." AND id_fiche_source = ".$id_fiche_source."::text";
            }
            else{
                $success = false;
                $msg = "Opération stoppée : identifiant de l'enregistrement non valide.";
                return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
            }
            // on peut lancer l'action sur la base de données
            try{
                $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                // test si l'enregistrement existe dans la table synthese.syntheseff
                $sql = "SELECT id_synthese, id_source, id_fiche_source FROM synthese.syntheseff ".$where;
                $result = $dbh->query($sql)->fetchAll();
                // si l'enregistrement existe dans la table synthese.syntheseff
                if(isset($result[0])){
                    if($result[0]['id_synthese']>0){
                        // récupération de toutes les informations d'identification de l'enregistrement qui va être supprimé pour le retour
                        $id_synthese = $result[0]['id_synthese'];
                        $id_source = $result[0]['id_source'];
                        $id_fiche_source = $result[0]['id_fiche_source'];
                        // suppression de l'enregistrement
                        $sql = "DELETE FROM synthese.syntheseff ".$where;
                        // $sql = "UPDATE synthese.syntheseff SET supprime = true ".$where;
                        $dbh->query($sql); 
                        $success = true;
                        $msg = "L'enregistrement portant l'id_synthese : ".$id_synthese." a été supprimé avec succès.";
                    }
                }
                // si l'enregistrement n'existe pas dans la table synthese.syntheseff
                else{
                    $success = false;
                    $msg = "Aucun enregistrement ne correspond aux identifiants fournis. La suppression n'a pas été réalisée.";
                }
            // si une erreur sql se produit dans le 'try' on la récupère et on l'expose
            }
            catch(Exception $e) {
                $success = false;
                $msg = "Une erreur s'est produite : ".$e->getMessage();
            }
        }
        // si le token n'est pas valide
        else{
             $success = false;
             $msg = "Opération stoppée : identification incorrecte";
        }
        // construction du json de retour
        // if($success===true){header('HTTP/1.1 200 OK');}
        // else{header('HTTP/1.1 433 Error');}
        // header('Content-Type: application/json');
        return $this->renderJSON(self::return_content($success,$msg,$id_synthese,$id_source,$id_fiche_source));
    }
}
