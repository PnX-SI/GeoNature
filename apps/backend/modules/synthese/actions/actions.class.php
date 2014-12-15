<?php
class syntheseActions extends sfFauneActions
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
        ini_set("memory_limit",'256M');
        $this->geojson = new Services_GeoJson();
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
        $nbreleves = SynthesefauneTable::preSearch($params);
        if($nbreleves<10000){
            // GeoJSON list of relevés de la synthèse
            $userNom = $this->getUser()->getAttribute('userNom');
            $userPrenom = $this->getUser()->getAttribute('userPrenom');
            $statuscode = $this->getUser()->getAttribute('statuscode');
            $lesreleves = SynthesefauneTable::search($params,$nbreleves,$userNom,$userPrenom,$statuscode );
            if (empty($lesreleves)){return $this->renderText(sfFauneActions::$EmptyGeoJSON);}
            //si on est au dela de la limite, on renvoi un geojson avec une feature contenant une geometry null (voir lib/sfFauneActions.php)
            elseif($lesreleves=='trop'){return $this->renderText(sfFauneActions::$toManyFeatures);}
            else{
                return $this->renderText($lesreleves);
                // if($request->getParameter('zoom')<5){
                    // return $this->renderText($this->geojson->encode($lesreleves, 'the_geom_point', 'id_synthese'));
                    // return $this->renderText($this->geojson->encode($lesreleves, 'the_geom', 'id_synthese'));
                    // return $this->renderText($lesreleves); 
                // }
                // else{
                    // return $this->renderText($this->geojson->encode($lesreleves, 'the_geom_ignfxx', 'id_synthese')); 
                    // return $this->renderText($this->geojson->encode($lesreleves, 'the_geom', 'id_synthese')); 
                    // return $this->renderText($lesreleves); 
                // }
            }
        }
        else{return sfFauneActions::comptFeatures($nbreleves);}
    }
    
    public function executeXlsObs(sfRequest $request)
    {
        $params = $request->getParams();
        $lesobs = SynthesefauneTable::listXlsObs($params);
        $srid_local_export = sfSyntheseConfig::$srid_local;
        $csv_output = "id_synthese\torganisme\tdateobs\tobservateurs\ttaxon_francais\ttaxon_latin\tfamille\tordre\tclasse\tcd_ref\tpatrimonial\tnom_critere_synthese\teffectif_total\tremarques\tsecteur\tcommune\tinsee\taltitude\tcoeur\tx_".$srid_local_export."\ty_".$srid_local_export."\tx_WGS84\ty_WGS84\ttype_objet\tgeometrie_source";
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
            $taxon_francais = $obs['taxon_francais'];
            $patrimonial = ($obs['patrimonial']=='t')?'oui':'non';
            $famille = $obs['famille'];
            $ordre = $obs['ordre'];
            $classe = $obs['classe'];
            $cd_nom = $obs['cd_nom'];
            $cd_ref = $obs['cd_ref'];
            $nom_critere_synthese = $obs['nom_critere_synthese'];
            $effectif_total = $obs['effectif_total'];
            $remarques = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $obs['remarques'] );
            $organisme = $obs['organisme'];
            $id_synthese = $obs['id_synthese'];
            $x_srid_local_export = $obs['x_srid_local_export'];
            $y_srid_local_export = $obs['y_srid_local_export'];
            $x_wgs84 = $obs['x_wgs84'];
            $y_wgs84 = $obs['y_wgs84'];
            $type_objet = 'point';
            $geom_type = ($obs['geom_type']=='ST_Point')?'point':'maille';
            $coeur = ($obs['coeur']=='t')?'oui':'non';
            $csv_output .= "$id_synthese\t$organisme\t$dateobs\t$observateurs\t$taxon_francais\t$taxon_latin\t$famille\t$ordre\t$classe\t$cd_ref\t$patrimonial\t$nom_critere_synthese\t$effectif_total\t$remarques\t$secteur\t$commune\t$insee\t$altitude\t$coeur\t$x_srid_local_export\t$y_srid_local_export\t$x_wgs84\t$y_wgs84\t$type_objet\t$geom_type\n";
        }
        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=synthese_observations_faune_".date("Y-m-d_His").".xls");
        print utf8_decode($csv_output);
        exit;
    }
    
    public function executeXlsStatus(sfRequest $request)
    {
        $params = $request->getParams();
        $statuts = SynthesefauneTable::listXlsStatus($params);
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
        header("Content-disposition: attachment; filename=synthese_statuts_faune_".date("Y-m-d_His").".xls");
        print utf8_decode($csv_output);
        exit;
    
    }
    
    public function executeShp(sfRequest $request)
    {
        //Récupération des paramètres de connexion à la base
        $ogrConnexionString = $this::getOgrConnexionString();
        $params = $request->getParams(); // récup des paramètres de la requête utilisateur
        $user = str_replace(' ','_',$this->getUser()->getAttribute('nom')); //récup du nom de l'utilisateur connecté
        $user = self::enleveaccents($user); //nettoyage
        $path = 'exportshape/'; //chemin public pour téléchargement du fichier zip
        $madate = date("Y-m-d_His");
        $srid_local_export = sfSyntheseConfig::$srid_local;
        //pour les points
        $sql = SynthesefauneTable::listShp($params,'ST_Point'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/faune_synthese_'.$madate.'_points.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\""; 
        system($command);//execution de la commande
        //pour les mailles
        $sql = SynthesefauneTable::listShp($params,'ST_Polygon'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/faune_synthese_'.$madate.'_mailles.shp '.$ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\""; 
        system($command);//execution de la commande
        //pour les centroids
        $sql = SynthesefauneTable::listShp($params,'centroid'); // exécution de la requête sql
        //construction de la ligne de commande ogr2ogr
        $ogr = 'ogr2ogr  -overwrite -s_srs EPSG:'.$srid_local_export.' -t_srs EPSG:'.$srid_local_export.' -f "ESRI Shapefile" '.sfConfig::get('sf_web_dir').'/exportshape/faune_synthese_'.$madate.'_centroids.shp '.    $ogrConnexionString.' -sql ';
        $command = $ogr." \"".$sql."\""; 
        system($command);//execution de la commande
        //on zipe le tout
        $zip = new zipfile(); 
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_points.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_points.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_points.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_points.dbf') ;
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_mailles.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_mailles.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_mailles.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_mailles.dbf') ;
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_centroids.shp') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_centroids.shx') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_centroids.prj') ;       
        $zip = self::zipemesfichiers($zip,$path.'faune_synthese_'.$madate.'_centroids.dbf') ;
        $archive = $zip->file();
        header('Content-Type: application/x-zip');      
        header('Content-Disposition: inline; filename=synthese_faune_'.$madate.'.zip') ;
        echo $archive ; //on retourne le contenu du zip à l'utilisateur
        unlink($path.'faune_synthese_'.$madate.'_points.shp');       
        unlink($path.'faune_synthese_'.$madate.'_points.shx');       
        unlink($path.'faune_synthese_'.$madate.'_points.prj');       
        unlink($path.'faune_synthese_'.$madate.'_points.dbf');
        unlink($path.'faune_synthese_'.$madate.'_mailles.shp');       
        unlink($path.'faune_synthese_'.$madate.'_mailles.shx');       
        unlink($path.'faune_synthese_'.$madate.'_mailles.prj');       
        unlink($path.'faune_synthese_'.$madate.'_mailles.dbf');
        unlink($path.'faune_synthese_'.$madate.'_centroids.shp');       
        unlink($path.'faune_synthese_'.$madate.'_centroids.shx');       
        unlink($path.'faune_synthese_'.$madate.'_centroids.prj');       
        unlink($path.'faune_synthese_'.$madate.'_centroids.dbf');
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
}
