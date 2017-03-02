<?php
class apActions extends sfGeonatureActions
{ 
    /**
	 * GeoJson encoder/decoder
	 *
	 * @var Service_GeoJson
	 */
	private $geojson;
    
    const ADD = 1;
    const UPDATE = 2;

  /**
   * preExecute : set corrects sequences for Doctrine
   *
   */
    public function preExecute()
    {
        $this->geojson = new Services_GeoJson();
        $manager = Doctrine_Manager::getInstance();
        $manager->setAttribute(Doctrine::ATTR_SEQNAME_FORMAT, '%s');
    }
    
    public function executeXls(sfRequest $request)
    {
        $aps = TApresenceTable::listXls($request);
        $csv_output = "organisme_source\tsecteur\tcommune_zp\tindexzp\tindexap\tdateobs\ttaxon\tobservateurs\tphenologie\tmethode_frequence\tfrequenceap\tsurfaceap\tmethode_comptage\tdenombrement\tperturbations\tmilieux\tcommune_ap\taltitude\trelue\tap_topo_valid\tzp_topo_valid\tpdop\tremarques\tx_Local\ty_Local\tx_WGS84\ty_WGS84";
        $csv_output .= "\n";
        foreach ($aps as $ap)
        {  
            $organisme = $ap['organisme'];
            $secteur = $ap['secteur'];     
            $communeap = $ap['communeap']; 
            $communezp = $ap['communezp']; 
            $indexzp = $ap['indexzp'];
            $indexap = $ap['indexap'];
            $dateobs = $ap['dateobs'];
            $taxon = $ap['taxon'];
            $observateurs = $ap['observateurs'];
            $phenologie = $ap['phenologie'];
            $frequenceap = $ap['frequenceap'];
            $surfaceap = $ap['surfaceap'];
            $denombrement = $ap['denombrement'];
            $perturbations = $ap['perturbations'];
            $milieux = $ap['milieux'];
            $methode_frequence = $ap['methode_frequence'];
            $methode_comptage = $ap['methode_comptage'];
            $remarques = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $ap['remarques'] );
            $altitude = $ap['altitude'];
            $ap_topo_valid = $ap['ap_topo_valid'];
            $zp_topo_valid = $ap['zp_topo_valid'];
            if ($ap['pdop']==-1){$ap['pdop'] = 'non précisé';}
            $pdop = $ap['pdop'];
            $relue = $ap['relue'];
            $x_local = $ap['x_local'];
            $y_llocal = $ap['y_local'];
            $x_wgs84 = $ap['x_wgs84'];
            $y_wgs84 = $ap['y_wgs84'];
            $csv_output .= "$organisme\t$secteur\t$communezp\t$indexzp\t$indexap\t$dateobs\t$taxon\t$observateurs\t$phenologie\t$methode_frequence\t$frequenceap\t$surfaceap\t$methode_comptage\t$denombrement\t$perturbations\t$milieux\t$communeap\t$altitude\t$relue\t$ap_topo_valid\t$zp_topo_valid\t$pdop\t$remarques\t$x_local\t$y_local\t$x_wgs84\t$y_wgs84\n";
        }
        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=zp_".date("Y-m-d_His").".xls");
        print utf8_decode($csv_output);
        exit;
    }
 /**
  * Geojson list of element for passed site
  *
  * @param sfRequest $request A request object
  */
    public function executeGet(sfRequest $request)
    {
        $aps = TApresenceTable::listFor($request->getParameter('indexzp'), $this->getUser());
        if (empty($aps))
          return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
        else
          return $this->renderText($this->geojson->encode($aps, 'the_geom_3857', 'indexap'));
    }
  
    public function executeListone(sfRequest $request)
    {
        if ($request->hasParameter('indexap') && $request->getParameter('format','')=='geoJSON')
        {
            $ap = TApresenceTable::findOne($request->getParameter('indexap'), 'geoJSON');
            if (empty($ap)){
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);}
            else{//print_r($ap['observateurs']);
                return $this->renderText($this->geojson->encode(array($ap), 'the_geom_3857', 'indexap'));
                //return $this->renderJson(array($ap));
                }
                
        }
    }

  /**
   * Toggle element validation state
   *
   * @param sfRequest $request
   */
    public function executeValidate(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){    
            $this->forward404Unless($ap=TApresenceTable::get($request->getParameter('indexap')));
            $ap->set('validation', !$ap->getValidationap());
            if ($ap->trySave())
              return $this->renderSuccess();
            else
              return $this->throwError();
        }
        else{return sfView::ERROR;}
    }

  /**
   * Update element
   *
   * @param sfRequest $request
   */
  public function executeSave(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){ 
        $monaction = $request->getParameter('monaction');
        $objets_a_compter = $request->getParameter('objets_a_compter');
        if($request->getParameter('nb_transects_frequence')==null||$request->getParameter('nb_transects_frequence')==''){$nb_transects_frequence = 0;}
        else{$nb_transects_frequence = $request->getParameter('nb_transects_frequence');}
        if($request->getParameter('nb_points_frequence')==null||$request->getParameter('nb_points_frequence')==''){$nb_points_frequence = 0;}
        else{$nb_points_frequence = $request->getParameter('nb_points_frequence');}
        if($request->getParameter('nb_contacts_frequence')==null||$request->getParameter('nb_contacts_frequence')==''){$nb_contacts_frequence = 0;}
        else{$nb_contacts_frequence = $request->getParameter('nb_contacts_frequence');}
        if($request->getParameter('nb_placettes_comptage')==null||$request->getParameter('nb_placettes_comptage')==''){$nb_placettes_comptage = 0;}
        else{$nb_placettes_comptage = $request->getParameter('nb_placettes_comptage');}
        if($request->getParameter('surface_placette_comptage')==null||$request->getParameter('surface_placette_comptage')==''){$surface_placette_comptage = 0;}
        else{$surface_placette_comptage =$request->getParameter('surface_placette_comptage');}    
        if($request->getParameter('effectif_placettes_comptage_sterile')==null||$request->getParameter('effectif_placettes_comptage_sterile')==''){$effectif_placettes_comptage_sterile = 0;}
        else{$effectif_placettes_comptage_sterile = $request->getParameter('effectif_placettes_comptage_sterile');} 
        if($request->getParameter('effectif_placettes_comptage_fertile')==null||$request->getParameter('effectif_placettes_comptage_fertile')==''){$effectif_placettes_comptage_fertile = 0;}
        else{$effectif_placettes_comptage_fertile = $request->getParameter('effectif_placettes_comptage_fertile');}
        if($request->getParameter('nbsterile')==null||$request->getParameter('nbsterile')==''){$nbsterile = 0;}
        else{$nbsterile = $request->getParameter('nbsterile');}
        if($request->getParameter('nbfertile')==null||$request->getParameter('nbfertile')==''){$nbfertile = 0;}
        else{$nbfertile = $request->getParameter('nbfertile');}
        switch ($monaction) {
            case 'add':
                $new_indexap = TApresenceTable::getMaxIndexAp()+1;
                $indexap = $new_indexap;
                $ap = new TApresence();
                $ap->indexap = $indexap;
                $ap->indexzp = $request->getParameter('indexzp');
                break;
            case 'update':
                $indexap = $request->getParameter('indexap');
                $ap = Doctrine::getTable('TApresence')->find($indexap);               
                break;
            default:
                break;
        }
        $ap->altitude_saisie=$request->getParameter('altitude');
        $ap->surfaceap=$request->getParameter('surface');
        $ap->id_frequence_methodo_new=$request->getParameter('id_frequence_methodo_new');
        $ap->nb_transects_frequence=$nb_transects_frequence;
        $ap->nb_points_frequence=$nb_points_frequence;
        $ap->nb_contacts_frequence=$nb_contacts_frequence;
        $ap->frequenceap=$request->getParameter('frequenceap');
        $ap->id_comptage_methodo=$request->getParameter('id_comptage_methodo');
        $ap->nb_placettes_comptage=$nb_placettes_comptage;
        $ap->surface_placette_comptage=$surface_placette_comptage;
        $ap->codepheno=$request->getParameter('codepheno');
        $ap->remarques=$request->getParameter('remarques');
        $ap->supprime=false;
        // return $this->renderText("{success: true,data:".print_r($ap)."}");
        $ap->save();
        
        //sauvegarde de la géometrie
        $geometry = $request->getParameter('geometry');
        Doctrine_Query::create()
            ->update('TApresence')
            ->set('the_geom_3857','multi(geometryFromText(?, 3857))', $geometry)
            ->where('indexap=?', $indexap)
            ->execute();
        //gestion du comptage selon ajout ou update ; on ne peut pas supprimer car il faut garder les infos pda non utilisées en mode web
        //on test s'il y a des enregistrement pour cette ap dans la table cor_ap_objet
            $query = Doctrine_Query::create()
              ->select('indexap')
              ->from('CorApObjet')
              ->where('indexap=?', $indexap)
              ->fetchArray();
            //s'il y a déjà des enregistrements de comptage
            if(count($query)>0){
                //s'il y a des enregistrement et qu'on update avec 'aucun comptage', on supprime ces enregistrements de comptage
                if($request->getParameter('id_comptage_methodo')==9){
                   Doctrine_Query::create()
                    ->delete()
                    ->from('CorApObjet')
                    ->where('indexap=?', $indexap)
                    ->execute(); 
                }
                //sinon on update l'existant            
                else{
                // return $this->renderText("{success: true,data:".print_r(substr_count($objets_a_compter,'ES'))."}");
                    if(substr_count($objets_a_compter,'ES')>0){
                        //on test s'il y a un enregistrement pour les stériles de cette ap dans la table cor_ap_objet
                        $s = Doctrine_Query::create()
                          ->select('indexap')
                          ->from('CorApObjet')
                          ->where('indexap=?', $indexap)
                          ->addWhere('id_objet_new=?', 'ES')
                          ->fetchArray();
                        //si oui on update
                        if(count($s)>0){
                            Doctrine_Query::create()
                                ->update('CorApObjet')
                                ->set('nombre', '?', $nbsterile)
                                ->set('effectif_placettes_comptage', '?', $effectif_placettes_comptage_sterile)
                                ->where('indexap=?', $indexap)
                                ->addWhere('id_objet_new=?', 'ES')
                                ->execute();
                        }
                        //sinon on insert
                        else{
                            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                            $sql = "INSERT INTO florepatri.cor_ap_objet (indexap, nombre, id_objet_new, effectif_placettes_comptage)
                                    VALUES(".$indexap.",".$nbsterile.",'ES',".$effectif_placettes_comptage_sterile.")";
                            $dbh->query($sql);
                        }
                    }
                    
                    if(substr_count($objets_a_compter,'EF')>0){
                        //on test s'il y a un enregistrement pour les fertiles de cette ap dans la table cor_ap_objet
                        $s = Doctrine_Query::create()
                          ->select('indexap')
                          ->from('CorApObjet')
                          ->where('indexap=?', $indexap)
                          ->addWhere('id_objet_new=?', 'EF')
                          ->fetchArray();
                        //si oui on update
                        if(count($s)>0){
                            Doctrine_Query::create()
                                ->update('CorApObjet')
                                ->set('nombre', '?', $nbfertile)
                                ->set('effectif_placettes_comptage', '?', $effectif_placettes_comptage_fertile)
                                ->where('indexap=?', $indexap)
                                ->addWhere('id_objet_new=?', 'EF')
                                ->execute();
                        }
                        //sinon on insert
                        else{
                            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                            $sql = "INSERT INTO florepatri.cor_ap_objet (indexap, nombre, id_objet_new, effectif_placettes_comptage)
                                    VALUES(".$indexap.",".$nbfertile.",'EF',".$effectif_placettes_comptage_fertile.")";
                            $dbh->query($sql); 
                        }
                    }
                }
            }
            //s'il n'y a pas d'enregistrements de comptage on les ajoute
            else{
                //normalement on ne peut ajouter des valeurs que si la méthode de comptage est différente de 'aucun comptage'
                if($request->getParameter('id_comptage_methodo')!=9){
                    if(substr_count($objets_a_compter,'ES')>0){
                        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                        $sql = "INSERT INTO florepatri.cor_ap_objet (indexap, nombre, id_objet_new, effectif_placettes_comptage)
                                VALUES(".$indexap.",".$nbsterile.",'ES',".$effectif_placettes_comptage_sterile.")";
                        $dbh->query($sql);
                    }
                    if(substr_count($objets_a_compter,'EF')>0){
                        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                        $sql = "INSERT INTO florepatri.cor_ap_objet (indexap, nombre, id_objet_new, effectif_placettes_comptage)
                                VALUES(".$indexap.",".$nbfertile.",'EF',".$effectif_placettes_comptage_fertile.")";
                        $dbh->query($sql);
                    }
                }
            }
        //enregistrement des perturbations
        if($request->getParameter('codesper')!=''){
            $array_perturbs = array();
            $array_perturbs =  explode(',',$request->getParameter('codesper'));
            Doctrine_Query::create()
              ->delete()
              ->from('CorApPerturb')
              ->andWhere('indexap=?', $indexap)
              ->execute();
          // return $this->renderText("{success: true,data:8}");
            foreach ($array_perturbs as $codeper)
            {
                // $cap = new CorApPerturb();
                // $cap->indexzp = $indexap;
                // $cap->codeobs = $codeper; 
                // $cap->save();
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "INSERT INTO florepatri.cor_ap_perturb (indexap, codeper)
                    VALUES(".$indexap.",".$codeper.")";
            $dbh->query($sql);
            }
        }
        //enregistrement des physionomies
        if($request->getParameter('ids_physionomie')!=''){
            $array_physios = array();
            $array_physios =  explode(',',$request->getParameter('ids_physionomie'));
            Doctrine_Query::create()
              ->delete()
              ->from('CorApPhysionomie')
              ->andWhere('indexap=?', $indexap)
              ->execute();
            foreach ($array_physios as $id_physionomie)
            {
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "INSERT INTO florepatri.cor_ap_physionomie (indexap, id_physionomie)
                    VALUES(".$indexap.",".$id_physionomie.")";
            $dbh->query($sql);
            }
        }
        return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }

  /**
   * Delete an element
   *
   * @param sfRequest $request
   */
  public function executeDelete(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){    
        $this->forward404Unless($ap=TApresenceTable::get($request->getParameter('indexap')));
        $ap->set('supprime', true);
        if ($ap->trySave())
          return $this->renderSuccess();
        else
          return $this->throwError();
    }
    else{return sfView::ERROR;}
  }
  
    public function executeUploadFileGpx(sfRequest $request)
    {
        // $gpx = self::uploadGpx($request);
        //récupération des variables postées
        $username =   str_replace(' ','_',$request->getParameter('username'));//récupération du nom utilisateur
        $file =   $request->getFiles('nom_fichier');//récupération du fichier
        // $chemin =  paUsers::getFilesDir().'/';//chemin dans l'appli où stocker les fichiers des evenements. Changer ce chemin si besoin dans la classe /lib/model/paUser.class.php, fonction getFilesDir
        $chemin =  sfConfig::get('sf_web_dir')."/uploads/gpx/";//chemin dans l'appli où stocker les fichiers gpx.
        $extensionlistok = array(".gpx");
        foreach ($extensionlistok as $item) {
            if(preg_match("/$item\$/i", $file['name'])) {
                $nom_fichier = "gpx_".$username.".gpx"; //renommer le fichier avec l'id de l'événement
                $chemin_fichier = $chemin.$nom_fichier; //nom du fichier avec son chemin
                //si la copie du fichier temporaire téléchargé réussie, on le place dans son répertoire 
                if(rename($file['tmp_name'], $chemin_fichier)){$msg='{success: true ,data:"Le fichier gpx a été téléchargé avec succès."}';}
                else{$msg='{success: false ,errors:"Le fichier gpx n\'a pas pu être téléchargé."}';}
            }
            else{$msg='{success: false ,errors:"Le fichier comporte une extention non valide. Utilisez une extention .gpx uniquement."}';}
        }
        return $this->renderText($msg);
    }
    
    private static function uploadGpx(sfRequest $request) {
        //récupération des variables postées
        $username =   str_replace(' ','_',$request->getParameter('username'));//récupération du nom utilisateur
        $file =   $request->getFiles('nom_fichier');//récupération du fichier
        // $chemin =  paUsers::getFilesDir().'/';//chemin dans l'appli où stocker les fichiers des evenements. Changer ce chemin si besoin dans la classe /lib/model/paUser.class.php, fonction getFilesDir
        $chemin =  sfConfig::get('sf_web_dir')."/uploads/gpx/";//chemin dans l'appli où stocker les fichiers des evenements. Changer ce chemin si besoin dans la classe /lib/model/paUser.class.php, fonction getFilesDir
        $extensionlistok = array(".gpx");
        foreach ($extensionlistok as $item) {
            if(preg_match("/$item\$/i", $file['name'])) {
                $nom_fichier = "gpx_".$username.".gpx"; //renommer le fichier avec l'id de l'événement
                $chemin_fichier = $chemin.$nom_fichier; //nom du fichier avec son chemin
                //si la copie du fichier temporaire téléchargé réussie, on le place dans son répertoire 
                if(rename($file['tmp_name'], $chemin_fichier)){
                    $msg=1;
                }
                else{$msg=0;}
            }
            else{$msg='refus';}
            return $msg;
        }
    }
  
  public function executeMsg($request)
  {
    if($this->getUser()->isAuthenticated()){
            $corps = $request->getParameter('corps').'<br/><br/><a href="http://cartodev.ecrins-parcnational.fr/flore/pda?indexzp='.$request->getParameter('indexzp').'">Lien vers la fiche de la zone de prospection concernée</a><br/>Attention, il est nécessaire d\'être déjà connecté à l\'application Flore pour pouvoir accéder à cette zone de prospection directement avec le lien ci-dessus.';
            $headers ='From: '.$request->getParameter('username').'<'.$request->getParameter('mailexpediteur').'>'."\n";
            $headers .='Reply-To: '.$request->getParameter('mailexpediteur')."\n";
            $headers .='Content-Type: text/html; charset="utf-8"'."\n";
            $headers .='Content-Transfer-Encoding: 8bit';
            if(mail($request->getParameter('maildestinataire'), $request->getParameter('sujet'), $corps, $headers)){
                //enregistrement de l'erreur signalée en base
                if($request->getParameter('indexap')){
                    $this->forward404Unless($request->isMethod('post'));
                    $ap = Doctrine::getTable('TApresence')->find($request->getParameter('indexap'));
                    $this->forward404Unless($ap);
                    $ap->setErreur_signalee(true);
                    if ($ap->trySave()){return $this->renderSuccess();}
                    else{return $this->throwError();}
                }
                else{
                    $this->forward404Unless($request->isMethod('post'));
                    $zp = Doctrine::getTable('TZprospection')->find($request->getParameter('indexzp'));
                    $this->forward404Unless($zp);
                    $zp->setErreur_signalee(true);
                    if ($zp->trySave()){return $this->renderSuccess();}
                    else{return $this->throwError();}
                }
                return $this->renderSuccess();
            }
            else{return $this->throwError();}
    }
    //else{return $this->throwError(array('msg' => 'toto'));}  
    else{return sfView::ERROR;}    
  }
  /**
   * Adds or update Element if indexap set in GeoJson,
   *  & returns Extjs formatted response
   *
   * @param sfRequest $request
   * @param integer $action
   */
  private function save(sfRequest $request, $action)
  {
    if($this->getUser()->isAuthenticated()){    
        # Fetch raw post geojson & extract properties & geometry
        //list($fields, $geometry) = GeoJSON::extractOne($request->getRawBody());

        $fields = $request->getParams();
        $geometry = $fields['geometry'];
        unset($fields['geometry']);

        $object = (isset($fields['indexap']) && $action==self::UPDATE)?
          (Doctrine::getTable('TApresence')->findOneByIdElement($fields['indexap'])):
          null;
    /*
        if ($fields['categorie_id']=='' || $fields['site_id']=='')
        {
          $errors = array();
          if ($fields['categorie_id']=='') $errors['categorie_id'] = 'requis';
          return $this->renderText(json_encode(array(
            'success' => false,
            'errors' => $errors
          )));
        }
    modification pour permettre l'enregistrement même si l'élément est validé
        # Check if element can be modified
        if (is_null($object) && !BibCategoriesTable::isCatWritable($fields['site_id'], $fields['categorie_id']))
          return $this->throwError(array('msg'=>'On ne peut ajouter d\'element à cette catégorie'));
        else if (!is_null($object) && !BibCategoriesTable::isWritable($object))
          return $this->throwError(array('msg'=>'Cet element n\'est pas modifiable'));
        */

        $form = new TApresenceForm($object);

        # Try to save attribute data
        if ($form->bindAndSave($fields))
        {
          # Update geometry if successfull
          $form->getObject()->updateGeometry($geometry);
          return $this->renderSuccess();
        }
        else
          return $this->throwError($form->getErrorSchema());
    }
    else{return sfView::ERROR;}
  }
}
