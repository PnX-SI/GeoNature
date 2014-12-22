<?php
class invertebreActions extends sfFauneActions
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
    $this->geojson = new Services_GeoJson();
	} 
	
    /**
    * Get GeoJSON fiche from id_inv passed
    * @param sfRequest $request
    * @return sfView::NONE
    */
    public function executeGetOneFiche(sfRequest $request)
    {
        if ($request->hasParameter('id_inv') && $request->getParameter('format','')=='geoJSON')
        {
            $fiche = TFichesInvTable::findOne($request->getParameter('id_inv'), 'geoJSON');
            if (empty($fiche))
                return $this->renderText(sfRessourcesActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($fiche), 'the_geom_3857', 'id_inv'));
        }
    }
	
    public function executeGetListRelevesInv(sfRequest $request)
    {
        $taxons = TRelevesInvTable::getListRelevesInv($request->getParameter('id_inv'));
        return $this->renderJSON($taxons);
    }

  /**
   * Delete a fiche (in fact mark it as supprime=true)
   * @param sfRequest $request
   * @return sfView::NONE
   */
  public function executeDeleteFicheInv(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){ 
        $this->forward404Unless($t=TfichesInvTable::get($request->getParameter('id_inv')));
        $t->set('supprime', true);
        if ($t->trySave()){
          Doctrine_Query::create()
            ->update('TfichesInv')
            ->set('supprime', '?', true)
            ->where('id_inv=?', $t->getId_inv())
            ->execute();
          return $this->renderSuccess();
        }
        else{return $this->throwError();}
    }
    else{return sfView::ERROR;}
  }
  
  public function executeDeleteReleveInv(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){
        $id_releve_inv = $request->getParameter('id_releve_inv');
          Doctrine_Query::create()
            ->update('TRelevesInv')
            ->set('supprime', '?', true)
            ->where('id_releve_inv=?', $id_releve_inv)
            ->execute();
          return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }
  
  public function saveTaxons($id_inv,$string_taxons,$monaction)
  {
    if($this->getUser()->isAuthenticated()){
        $array_taxons = explode('|',$string_taxons);
        // Suppression des taxons qui existe et qui ont été supprimé dans le formulaire javascript
        $mon_array = array(); // dans ce tableau on va pousser tous les enregistrements qui ont un id_releve_inv donc ceux qui ne sont pas nouveau
        foreach ($array_taxons as $string_taxon){
            $array_taxon = explode(",",$string_taxon);
            if($array_taxon[0]!='' OR $array_taxon[0]!=null){array_push($mon_array,$array_taxon[0]);}
        }
        //s'il y a des id_releve_inv on boucle pour supprimer ceux de la fiche qui ne serait plus dans le tableau $array_taxon
        // si comme dans le cas d'un ajout de taxon pour une nouvelle fiche, il n'y a pas encore de id_releve_inv il n'y a rien à supprimer
        if(count($mon_array)>0){
            $string_del_tx = implode(', ',$mon_array);//on créé une chaine avec les taxon à supprimer
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "UPDATE contactinv.t_releves_inv SET supprime = true WHERE id_inv = $id_inv AND id_releve_inv NOT IN ($string_del_tx);";
            $a = $dbh->query($sql);
        }
        //on boucle sur la chaine des taxons envoyée par le formulaire pour récupérer les champs et on insert ou on update
        foreach ($array_taxons as $string_taxon){
            $array_taxon = explode(",",$string_taxon);
            // Récupération des valeurs dans des variables
            $id_releve_inv = $array_taxon[0];
            $id_taxon = $array_taxon[1];
            $nom_taxon_saisi = $array_taxon[4];
            $id_critere_inv = $array_taxon[5];
            $am = $array_taxon[6];
            $af = $array_taxon[7];
            $ai = $array_taxon[8];
            $na = $array_taxon[9];
            $commentaire = $array_taxon[10];
            $cd_ref_origine = $array_taxon[11];
            //on récupère l'enregistrement ou on le crée
            // $taxon = new TRelevesInv();
            if($id_releve_inv==null OR $id_releve_inv==''){
                $taxon = new TRelevesInv();
                $id_releve_inv = TRelevesInvTable::getMaxIdReleve()+1;
            }
            else{$taxon = Doctrine::getTable('TRelevesInv')->find($id_releve_inv);}
            //on passe les valeur et on enregistre
            $taxon->id_releve_inv = $id_releve_inv;
            $taxon->id_inv = $id_inv;
            $taxon->id_taxon = $id_taxon;
            $taxon->nom_taxon_saisi = str_replace('<!>',',',$nom_taxon_saisi);
            $taxon->id_critere_inv = $id_critere_inv;
            $taxon->am= $am;
            $taxon->af = $af;
            $taxon->ai = $ai;
            $taxon->na = $na;
            $taxon->commentaire = str_replace('<!>',',',$commentaire);
            $taxon->cd_ref_origine = $cd_ref_origine;
            $taxon->save();
        }
        // return $this->renderText("{success: true,data:".print_r($taxon)."}");
        return true;
    }
    else{return sfView::ERROR;}
  }
  
  public function executeSaveInv(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){    
        $monaction = $request->getParameter('monaction');//on récupère l'action pour savoir si on update ou si on créé un nouvel enregistrement
        //création de l'objet selon update ou ajout
        switch ($monaction) {
            case 'add':
                $new_id_inv = TFichesInvTable::getMaxIdFiche()+1;
                $fiche = new TfichesInv();
                break;
            case 'update':
                $fiche = Doctrine::getTable('TfichesInv')->find($request->getParameter('id_inv')); 
                break;
            default:
                break;
        }
        if($monaction=='add') {
            $id_inv = $new_id_inv;
            $fiche->id_inv = $id_inv;
            $fiche->saisie_initiale = 'web';
            $fiche->id_organisme = sfGeonatureConfig::$id_organisme;
        }
        //remise au format de la date
        $d = array(); $pattern = '/^(\d{2})\/(\d{2})\/(\d{4})/';
        preg_match($pattern, $request->getParameter('dateobs'), $d);
        $datepg = sprintf('%s-%s-%s', $d[3],$d[2],$d[1]);
        //affectation des valeurs reçues du formulaire extjs
        $fiche->dateobs = $datepg;
        $fiche->heure = $request->getParameter('heure');
        $fiche->id_milieu_inv = $request->getParameter('id_milieu_inv');
        $fiche->pdop = sfGeonatureConfig::$default_pdop;
        if($request->getParameter('altitude_saisie')=='' OR !$request->hasParameter('altitude_saisie')){$altitude_saisie=-1;} else{$altitude_saisie=$request->getParameter('altitude_saisie');}
        $fiche->altitude_saisie = $altitude_saisie;
        $fiche->supprime = false;
        $fiche->srid_dessin = sfGeonatureConfig::$srid_dessin;
        $fiche->id_protocole = sfGeonatureConfig::$id_protocole_inv;
        $fiche->id_lot = sfGeonatureConfig::$id_lot_inv;
        // $fiche->id_lot = $request->getParameter('id_lot');
        $fiche->save();//enregistrement avec la methode save de symfony
        // ensuite on commence par supprimer tout ce qui concerne cette fiche si on est en update
        if($monaction=='update'){
            $id_inv = $request->getParameter('id_inv');
            //suppression des observateurs de la fiche
            $deleted = Doctrine_Query::create()
                  ->delete()
                  ->from('CorRoleFicheInv crfc')
                  ->where('crfc.id_inv = ?', $id_inv)
                  ->execute();            
        }
        //enregistrement dans la table cor_role_fiche_inv
        $ids_observateurs = $request->getParameter('ids_observateurs');
        $array_observateurs = array();
        if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
        if(count($array_observateurs)>0){
            foreach ($array_observateurs as $id_role)
            {
                $crfc = new CorRoleFicheInv();
                $crfc->id_inv = $id_inv;
                $crfc->id_role = $id_role; 
                $crfc->save();
            }
        }
        //sauvegarde de la géometrie de la fiche
        // on le fait après l'enregistrement des observateurs car l'insertion de la géométrie va provoquer le trigger update
        // et ce trigger met à jour la synthesefaune, dont les observateurs. Si on insert les observateurs après, cela ne mettrait
        //pas à jour la synthesefaune.
        $geometry = $request->getParameter('geometry');
        Doctrine_Query::create()
         ->update('TFichesInv')
         ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
         ->where('id_inv= ?', $fiche->getId_inv())
         ->execute();
        
        if($request->hasParameter('sting_taxons')){self::saveTaxons($id_inv,$request->getParameter('sting_taxons'),$monaction);}
        return $this->renderText("{success: true,id_inv:".$fiche->getId_inv()."}");
        // return $this->renderSuccess();//retour ajax pour Extjs ; retourne {success: true}
    }
    else{
        $this->redirect('@login');
    }
  }
    public function executeGetZ(sfRequest $request)
    {
        $point = $request->getParameter('point');
        $srid_layer_commune = sfGeonatureConfig::$srid_local;
        $srid_layer_isoline = sfGeonatureConfig::$srid_local;
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT layers.f_isolines20(ST_transform(st_setsrid(ST_GeomFromText('$point',3857),3857),".$srid_layer_isoline.")) AS z,
                layers.f_nomcommune(ST_transform(st_setsrid(ST_GeomFromText('$point',3857),3857),".$srid_layer_commune.")) AS nom_commune";
        $array_z = $dbh->query($sql);
        foreach($array_z as $val){
            $z = $val['z'];
            $nom_commune = str_replace("'","\'",$val['nom_commune']);
        }
        if($z==null){$z=0;}
        if($nom_commune==null){$nom_commune='hors zone';}
        return $this->renderText("{success: true,data:{altitude:".$z.",nomcommune:'".$nom_commune."'}}");
        // print_r(json_encode($val));
    }
}
