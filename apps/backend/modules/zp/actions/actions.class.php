<?php
class zpActions extends sfGeonatureActions
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
	 * Simple list of all zp
	 *
	 * @return sfView::NONE
	 */
	public function executeAll()
	{
    $zp = TZprospectionTable::listAll();
		return $this->renderJSON($zp);
	}
	
	public function executeGetZpCount(sfRequest $request)
	{
		$leszps = TZprospectionTable::search(
			$request->getParams(), 
			$this->getUser()->hasCredential('consultant')
		);
		$leszp['nb']= count($leszps);
		return $this->renderText($leszp['nb']);
	}

  /**
   * Get GeoJSON list of zps, filtered, or zp detail if id passed
   *
   * @param sfRequest $request
   * 
   * @return sfView::NONE
   */
    public function executeGet(sfRequest $request)
    {
        if ($request->hasParameter('indexzp') && $request->getParameter('format','')=='geoJSON')
        {
            $zp = TZprospectionTable::findOne($request->getParameter('indexzp'), 'geoJSON');
            if (empty($zp))
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($zp), 'the_geom_ignfxx', 'indexzp'));
        }
        else if ($request->hasParameter('indexzp'))
        {
            // detail of a zp, without geom
          $zp = TZprospectionTable::findOne($request->getParameter('indexzp'));
          $this->forward404Unless($zp);
          return $this->renderJSON(array($zp));
        }
        else
        {
            // GeoJSON list of zp
            $leszps = TZprospectionTable::search(
                $request->getParams(), 
                $this->getUser()->hasCredential('utilisateur')
            );
            if (empty($leszps)){
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);}
            //si on est au dela de la limite, on renvoi un geojson avec une feature contenant une geometry null (voir lib/sfGeonatureActions.php)
            elseif($leszps=='trop'){return $this->renderText(sfGeonatureActions::$toManyFeatures);}
            else{
                if($request->getParameter('zoom')<5){
                    return $this->renderText($this->geojson->encode($leszps, 'geom_point_ignfxx', 'indexzp'));
                }
                elseif($request->getParameter('zoom')<7 && $request->getParameter('zoom')>=5){
                    return $this->renderText($this->geojson->encode($leszps, 'geom_mixte_ignfxx', 'indexzp'));
                }
                else{
                    return $this->renderText($this->geojson->encode($leszps, 'the_geom_ignfxx', 'indexzp')); 
                }
            }
        }
    }
	
  /**
   * Update a zp
   *
   * @param sfRequest $request
   */
  public function executeSave(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){
        $monaction = $request->getParameter('monaction');
        //remise au format de la date
        $d = array(); $pattern = '/^(\d{2})\/(\d{2})\/(\d{4})/';
        preg_match($pattern, $request->getParameter('dateobs'), $d);
        $datepg = sprintf('%s-%s-%s', $d[3],$d[2],$d[1]);        
         switch ($monaction) {
            case 'add':
                $new_indexzp = TZprospectionTable::getMaxIndexZp()+1;
                $indexzp = $new_indexzp;
                $zp = new TZprospection();
                $zp->indexzp = $indexzp;
                $zp->saisie_initiale = 'web';
                $zp->id_protocole = sfGeonatureConfig::$id_protocole_florepatri;
                $zp->id_lot = sfGeonatureConfig::$id_lot_florepatri;
                // $station->id_organisme = sfGeonatureConfig::$id_organisme;
                $zp->id_organisme = $request->getParameter('id_organisme');//si update d'un admin d'un autre organisme (cbna par ex) on ne change pas l'organisme source de la donnée
                break;
            case 'update':
                $indexzp = $request->getParameter('indexzp');
                $zp = Doctrine::getTable('TZprospection')->find($indexzp); 
                break;
            default:
                break;
        }
        
        $zp->dateobs = $datepg;
        $zp->cd_nom = $request->getParameter('cd_nom');
        $zp->taxon_saisi = $request->getParameter('taxon_saisi');
        $zp->id_organisme = $request->getParameter('id_organisme');
        $zp->srid_dessin = sfGeonatureConfig::$srid_dessin;
        $zp->supprime = false;
        $zp->save();
        // return $this->renderText("{success: true,data:".print_r($zp)."}");
        //sauvegarde de la géometrie
        $geometry = $request->getParameter('geometry');
        Doctrine_Query::create()
            ->update('TZprospection')
            ->set('the_geom_ignfxx','multi(geometryFromText(?, 310024001))', $geometry)
            // ->set('the_geom','st_transform(multi(geometryFromText(?, 310024001)),27572)', $geometry)
            // ->set('the_geom_2154','st_transform(multi(geometryFromText(?, 310024001)),2154)', $geometry)
            ->where('indexzp=?', $indexzp)
            ->execute();
        if($monaction =='update'){
            //suppression des observateurs de la zp (table cor_zp_obs)
            $deleted = Doctrine_Query::create()
              ->delete()
              ->from('CorZpObs czo')
              ->where('czo.indexzp = ?', $indexzp)
              ->execute();
        }
        //enregistrement dans la table cor_zp_obs
        $ids_observateurs = $request->getParameter('ids_observateurs');
        $array_observateurs = array();
        if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
        if(count($array_observateurs)>0){
            foreach ($array_observateurs as $codeobs)
            {
                $czo = new CorZpObs();
                $czo->indexzp = $indexzp;
                $czo->codeobs = $codeobs; 
                $czo->save();
            }
        }
          
        return $this->renderText("{success: true,indexzp:".$indexzp."}");
        // return $this->renderSuccess(); 
    }
    else{return sfView::ERROR;}
  }
  
  /**
   * Delete an site (in fact mark it as deleted)
   *
   * @param sfRequest $request
   * 
   * @return sfView::NONE
   */
  public function executeDelete(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){ 
//print_r ($request->getParameter('indexzp')) ;   
        $this->forward404Unless($zp=TZprospectionTable::get($request->getParameter('indexzp')));
        $zp->set('supprime', true);
        if ($zp->trySave())
        {
          Doctrine_Query::create()
            ->update('TApresence')
            ->set('supprime', '?', true)
            ->where('indexzp=?', $zp->getIndexzp())
            ->execute();
          return $this->renderSuccess();
        }
        else
          return $this->throwError();
    }
    else{return sfView::ERROR;}
  }
  
  
  /**
   * Validate a site, if all categories are validated for it
   *
   * @param sfRequest $request
   * 
   * @return sfView::NONE
   */
  public function executeValidate(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){
        $this->forward404Unless($request->isMethod('post'));
        $zp = Doctrine::getTable('TZprospection')->find($request->getParameter('indexzp'));
        $this->forward404Unless($zp);
        $zp->setValidation(!$zp->getValidation());
        if ($zp->trySave())
          return $this->renderSuccess();
        else
          return $this->throwError();
    }
    else{return sfView::ERROR;}
  }
  
  private function save(TZProspectionForm $form, sfRequest $request)
  {
  	# Format parameters
  	$fields = $request->getParams(); 
  	if ($form->isNew())
  	  $fields = array_merge($fields, TZProspectionForm::$default);
  	//else
      //$fields['no_id'] = $form->getObject()->getNoId();  		
  	  
    $geometry = $fields['geometry'];
    unset($fields['geometry']);


    # Do it in a transaction cause the geometry is updated afterward
    $conn = Doctrine_Manager::getInstance()->getConnection('doctrine');
    $conn->beginTransaction();
      
    # Try to save attribute data
    //$zp = Doctrine::getTable('TZprospection')->find($request->getParameter('indexzp'));
    //$this->forward404Unless($zp);
    //if ($request->hasParameter('erreur_signalee')){$zp->setErreur_signalee(true);}
    //else{$zp->setErreur_signalee(false);}
    //$zp->setCd_nom($request->getParameter('cd_nom'));
    if ($form->bindAndSave($fields))
    {
      # Update geometry if successfull
      try {
        $form->getObject()->updateGeometry($geometry);
      } catch (Exception $e) {
        $conn->rollback();
        return $this->throwError(array('msg'=>'La géometrie saisie est invalide.'));
      }
      $conn->commit();
      return $this->renderText("{success: true, id: {$form->getObject()->getIndexzp()}}");
    }
    else
    {
      $conn->rollback();
      return $this->throwError($form->getErrorSchema());
    }
  }
  
}
