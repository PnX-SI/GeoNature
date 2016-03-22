<?php
class cfloreActions extends sfGeonatureActions
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
    * Get GeoJSON fiche from id_cflore passed
    * @param sfRequest $request
    * @return sfView::NONE
    */
    public function executeGetOneFiche(sfRequest $request)
    {
        if ($request->hasParameter('id_cflore') && $request->getParameter('format','')=='geoJSON')
        {
            $fiche = TFichesCfloreTable::findOne($request->getParameter('id_cflore'), 'geoJSON');
            if (empty($fiche))
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($fiche), 'the_geom_3857', 'id_cflore'));
        }
    }
	
    public function executeGetListRelevesCflore(sfRequest $request)
    {
        $taxons = TRelevesCfloreTable::getListRelevesCflore($request->getParameter('id_cflore'));
        return $this->renderJSON($taxons);
    }

  /**
   * Delete a fiche (in fact mark it as supprime=true)
   * @param sfRequest $request
   * @return sfView::NONE
   */
  public function executeDeleteFicheCflore(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){ 
        $this->forward404Unless($t=TfichesCfloreTable::get($request->getParameter('id_cflore')));
        $t->set('supprime', true);
        if ($t->trySave()){
          Doctrine_Query::create()
            ->update('TfichesCflore')
            ->set('supprime', '?', true)
            ->where('id_cflore=?', $t->getId_cflore())
            ->execute();
          return $this->renderSuccess();
        }
        else{return $this->throwError();}
    }
    else{return sfView::ERROR;}
  }
  
  public function executeDeleteReleveCflore(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){
        $id_releve_cflore = $request->getParameter('id_releve_cflore');
          Doctrine_Query::create()
            ->update('TRelevesCflore')
            ->set('supprime', '?', true)
            ->where('id_releve_cflore=?', $id_releve_cflore)
            ->execute();
          return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }
  
    public function saveTaxons($id_cflore,$string_taxons,$monaction)
    {
        if($this->getUser()->isAuthenticated()){
            $array_taxons = explode('|',$string_taxons);
            // Suppression des taxons qui existe et qui ont été supprimé dans le formulaire javascript
            $mon_array = array(); // dans ce tableau on va pousser tous les enregistrements qui ont un id_releve_cflore donc ceux qui ne sont pas nouveau
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                if($array_taxon[0]!='' OR $array_taxon[0]!=null){array_push($mon_array,$array_taxon[0]);}
            }
            //s'il y a des id_releve_cflore on boucle pour supprimer ceux de la fiche qui ne serait plus dans le tableau $array_taxon
            // si comme dans le cas d'un ajout de taxon pour une nouvelle fiche, il n'y a pas encore de id_releve_cflore il n'y a rien à supprimer
            if(count($mon_array)>0){
                $string_del_tx = implode(', ',$mon_array);//on créé une chaine avec les taxon à supprimer
                $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                $sql = "UPDATE contactflore.t_releves_cflore SET supprime = true WHERE id_cflore = $id_cflore AND id_releve_cflore NOT IN ($string_del_tx);";
                $a = $dbh->query($sql);
            }
            //on boucle sur la chaine des taxons envoyée par le formulaire pour récupérer les champs et on insert ou on update
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                // Récupération des valeurs dans des variables
                $id_releve_cflore = $array_taxon[0];
                $id_taxon = $array_taxon[1];
                $nom_taxon_saisi = $array_taxon[4];
                $id_abondance_cflore = $array_taxon[5];
                $id_phenologie_cflore = $array_taxon[6];
                $validite_cflore = $array_taxon[7];
                $commentaire = $array_taxon[8];
                $determinateur = $array_taxon[9];
                $cd_ref_origine = $array_taxon[10];
                $herbier = $array_taxon[12];
                //on récupère l'enregistrement ou on le crée
                // $taxon = new TRelevesCflore();
                if($id_releve_cflore==null OR $id_releve_cflore==''){
                    $taxon = new TRelevesCflore();
                    $id_releve_cflore = TRelevesCfloreTable::getMaxIdReleve()+1;
                }
                else{$taxon = Doctrine::getTable('TRelevesCflore')->find($id_releve_cflore);}
                //on passe les valeur et on enregistre
                $taxon->id_releve_cflore = $id_releve_cflore;
                $taxon->id_cflore = $id_cflore;
                $taxon->id_taxon = $id_taxon;
                $taxon->nom_taxon_saisi = str_replace('<!>',',',$nom_taxon_saisi);
                $taxon->id_abondance_cflore = $id_abondance_cflore;
                $taxon->id_phenologie_cflore = $id_phenologie_cflore;
                $taxon->validite_cflore = $validite_cflore;
                $taxon->commentaire = str_replace('<!>',',',$commentaire);
                $taxon->determinateur = str_replace('<!>',',',$determinateur);
                $taxon->cd_ref_origine = $cd_ref_origine;
                $taxon->herbier = $herbier;
                $taxon->save();
            }
            // return $this->renderText("{success: true,data:".print_r($taxon)."}");
            return true;
        }
        else{return sfView::ERROR;}
    }
  
    public function executeSaveCflore(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){    
            $monaction = $request->getParameter('monaction');//on récupère l'action pour savoir si on update ou si on créé un nouvel enregistrement
            //création de l'objet selon update ou ajout
            switch ($monaction) {
                case 'add':
                    $new_id_cflore = TFichesCfloreTable::getMaxIdFiche()+1;
                    $fiche = new TfichesCflore();
                    break;
                case 'update':
                    $fiche = Doctrine::getTable('TfichesCflore')->find($request->getParameter('id_cflore')); 
                    break;
                default:
                    break;
            }
            if($monaction=='add') {
                $id_cflore = $new_id_cflore;
                $fiche->id_cflore = $id_cflore;
                $fiche->saisie_initiale = 'web';
                $fiche->id_organisme = sfGeonatureConfig::$id_organisme;
                $fiche->id_protocole = sfGeonatureConfig::$id_protocole_cflore;
            }
            //remise au format de la date
            $d = array(); $pattern = '/^(\d{2})\/(\d{2})\/(\d{4})/';
            preg_match($pattern, $request->getParameter('dateobs'), $d);
            $datepg = sprintf('%s-%s-%s', $d[3],$d[2],$d[1]);
            //affectation des valeurs reçues du formulaire extjs
            $fiche->dateobs = $datepg;
            $fiche->pdop = sfGeonatureConfig::$default_pdop;
            if($request->getParameter('altitude_saisie')=='' OR !$request->hasParameter('altitude_saisie')){$altitude_saisie=-1;} else{$altitude_saisie=$request->getParameter('altitude_saisie');}
            $fiche->altitude_saisie = $altitude_saisie;
            $fiche->supprime = false;
            $fiche->srid_dessin = sfGeonatureConfig::$srid_dessin;
            $fiche->id_lot = sfGeonatureConfig::$id_lot_cflore;
            $fiche->save();//enregistrement avec la methode save de symfony
            // ensuite on commence par supprimer tout ce qui concerne cette fiche si on est en update
            
            if($monaction=='update'){
                $id_cflore = $request->getParameter('id_cflore');
                //suppression des observateurs de la fiche
                $deleted = Doctrine_Query::create()
                      ->delete()
                      ->from('CorRoleFicheCflore crfc')
                      ->where('crfc.id_cflore = ?', $id_cflore)
                      ->execute();            
            }
            //enregistrement dans la table cor_role_fiche_cflore
            $ids_observateurs = $request->getParameter('ids_observateurs');
            $array_observateurs = array();
            if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
            if(count($array_observateurs)>0){
                foreach ($array_observateurs as $id_role)
                {
                    $crfc = new CorRoleFicheCflore();
                    $crfc->id_cflore = $id_cflore;
                    $crfc->id_role = $id_role; 
                    $crfc->save();
                }
            }
            //sauvegarde de la géometrie de la fiche
            // on le fait après l'enregistrement des observateurs car l'insertion de la géométrie va provoquer le trigger update
            // et ce trigger met à jour la synthese, dont les observateurs. Si on insert les observateurs après, cela ne mettrait
            //pas à jour la synthese.
            $geometry = $request->getParameter('geometry');
            Doctrine_Query::create()
             ->update('TFichesCflore')
             ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
             ->where('id_cflore= ?', $fiche->getId_cflore())
             ->execute();
            
            if($request->hasParameter('sting_taxons')){self::saveTaxons($id_cflore,$request->getParameter('sting_taxons'),$monaction);}
            return $this->renderText("{success: true,id_cflore:".$fiche->getId_cflore()."}");
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
                layers.f_nomcommune(ST_transform(st_setsrid(ST_GeomFromText('$point',3857),3857),".$srid_layer_commune.")) AS nomcommune";
        $array_z = $dbh->query($sql);
        foreach($array_z as $val){
            $z = $val['z'];
            $nomcommune = str_replace("'","\'",$val['nomcommune']);
        }
        if($z==null){$z=0;}
        if($nomcommune==null){$nomcommune='hors zone';}
        return $this->renderText("{success: true,data:{altitude:".$z.",nomcommune:'".$nomcommune."'}}");
    }    
}
