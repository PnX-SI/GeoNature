<?php
class bryoActions extends sfGeonatureActions
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
	 * Simple list of all stations
	 *
	 * @return sfView::NONE
	 */
	public function executeAll()
	{
    $stations = TStationsBryoTable::listAll();
		return $this->renderJSON($stations);
	}
	
	public function executeGetStationCount(sfRequest $request)
	{
		$query = TStationsBryoTable::search(
			$request->getParams(), 
			$this->getUser()->hasCredential('consultant')
		);
		$stations['nb']= count($query);
		return $this->renderText($stations['nb']);
	}

  /**
   * Get GeoJSON list of stations, filtered, or stations detail if id passed
   *
   * @param sfRequest $request
   * 
   * @return sfView::NONE
   */
    public function executeGet(sfRequest $request)
    {
        if ($request->hasParameter('id_station') && $request->getParameter('format','')=='geoJSON')
        {
            $station = TStationsBryoTable::findOne($request->getParameter('id_station'), 'geoJSON');
            if (empty($station))
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($station), 'the_geom_3857', 'id_station'));
        }
        else if ($request->hasParameter('id_station'))
        {
            // detail of a station, without geom
          $station = TStationsBryoTable::findOne($request->getParameter('id_station'));
          $this->forward404Unless($station);
          return $this->renderJSON(array($station));
        }
        else
        {
            // GeoJSON list of station
            $lesstations = TStationsBryoTable::search(
                $request->getParams(), 
                $this->getUser()->hasCredential('utilisateur')
            );
            if (empty($lesstations)){return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);}
            //si on est au dela de la limite, on renvoi un geojson avec une feature contenant une geometry null (voir lib/sfGeonatureActions.php)
            elseif($lesstations=='trop'){return $this->renderText(sfGeonatureActions::$toManyFeatures);}
            else{return $this->renderText($this->geojson->encode($lesstations, 'the_geom_3857', 'id_station'));}
        }
    }
	
    public function executeGetTaxons(sfRequest $request)
    {
        $taxons = CorBryoTaxonTable::listTaxons($request->getParameter('id_station'), $this->getUser());
        if (empty($taxons))
          return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
        else
          return $this->renderText($this->geojson->encode($taxons, 'the_geom_3857', 'id_station'));
    }
    
    public function executeGetOneReleveTaxons(sfRequest $request)
    {
        $taxons = CorBryoTaxonTable::listOneReleveTaxons($request->getParameter('id_station'));
        return $this->renderJSON($taxons);
    }
  
  /**
   * Delete an station (in fact mark it as supprime=true)
   *
   * @param sfRequest $request
   * 
   * @return sfView::NONE
   */
  public function executeDelete(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){ 
        $this->forward404Unless($t=TStationsBryoTable::get($request->getParameter('id_station')));
        $t->set('supprime', true);
        if ($t->trySave()){
          Doctrine_Query::create()
            ->update('CorBryoTaxon')
            ->set('supprime', '?', true)
            ->where('id_station=?', $t->getId_station())
            ->execute();
          return $this->renderSuccess();
        }
        else{return $this->throwError();}
    }
    else{return sfView::ERROR;}
  }
  
  public function executeDeleteTaxon(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){
        $cd_nom = $request->getParameter('cd_nom');
        $id_station = $request->getParameter('id_station');
          Doctrine_Query::create()
            ->update('CorBryoTaxon')
            ->set('supprime', '?', true)
            ->where('id_station=?', $id_station)
            ->addWhere('cd_nom=?', $cd_nom)
            ->execute();
          return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }
  
  public function executeSaveTaxon(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){
        $new_cd_nom = $request->getParameter('new_cd_nom');
        $old_cd_nom = $request->getParameter('old_cd_nom');
        $id_station = $request->getParameter('id_station');
        //on vérifie que le taxon (old ou new) n'existe pas déjà éventuellement avec supprime = true pour cette station
        $verif_new = Doctrine::getTable('CorBryoTaxon')->find(array($id_station,$new_cd_nom));
        if($verif_new){$verif_new->delete();}// si oui on le supprime
        if($old_cd_nom>0){
            $verif_old = Doctrine::getTable('CorBryoTaxon')->find(array($id_station,$old_cd_nom));
            if($verif_old){$verif_old->delete();}// si oui on le supprime
        }
        //maintenant on créé un nouveau = new CorBryoTaxon()
        $taxon = new CorBryoTaxon();
        $taxon->id_station = $id_station;
        $taxon->cd_nom = $new_cd_nom;
        //on gère les nuls dans les strates
        if($request->getParameter('id_abondance')=='' OR $request->getParameter('id_abondance')==null){$id_abondance=null;} else{$id_abondance=$request->getParameter('id_abondance');}
        if($request->getParameter('taxon_saisi')=='' OR $request->getParameter('taxon_saisi')==null){$taxon_saisi=null;} else{$taxon_saisi=$request->getParameter('taxon_saisi');}
        //on attribue les valeurs aux strates
        $taxon->id_abondance = $id_abondance;
        $taxon->taxon_saisi = $taxon_saisi;
        // $taxon->supprime = false;
        // return $this->renderText("{success: true,data:".print_r($taxon)."}");
        //on enregistre le taxon
        $taxon->save();
        //on retourne success = true
        return $this->renderSuccess();
        
    }
    else{return sfView::ERROR;}
  }
  
  public function executeSave(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){    
        $monaction = $request->getParameter('monaction');//on récupère l'action pour savoir si on update ou si on créé un nouvel enregistrement
        //création de l'objet selon update ou ajout
        switch ($monaction) {
            case 'add':
                $new_id_station = TStationsBryoTable::getMaxIdStation()+1;
                $station = new TStationsBryo();
                break;
            case 'update':
                $station = Doctrine::getTable('TStationsBryo')->find($request->getParameter('id_station')); 
                break;
            default:
                break;
        }
        if($monaction=='add') {
            $id_station = $new_id_station;
            $station->id_station = $id_station;
        }
        //remise au format de la date
        $d = array(); $pattern = '/^(\d{2})\/(\d{2})\/(\d{4})/';
        preg_match($pattern, $request->getParameter('dateobs'), $d);
        $datepg = sprintf('%s-%s-%s', $d[3],$d[2],$d[1]);
        //affectation des valeurs reçues du formulaire extjs
        $station->dateobs = $datepg;
        $station->info_acces = $request->getParameter('info_acces');
        if($request->getParameter('id_support')=='' OR $request->getParameter('id_support')==null){$id_support=999;} else{$id_support=$request->getParameter('id_support');}
        $station->id_support = $request->getParameter('id_support');
        $station->id_protocole = sfGeonatureConfig::$id_protocole_bryo;
        $station->id_lot = sfGeonatureConfig::$id_lot_bryo;
        $station->id_organisme = sfGeonatureConfig::$id_organisme;
        if($request->getParameter('pdop')=='' OR $request->getParameter('pdop')==null){$pdop=sfGeonatureConfig::$default_pdop;} else{$pdop=$request->getParameter('pdop');}
        $station->pdop = $pdop;
        $station->surface = $request->getParameter('surface');
        $station->id_exposition = $request->getParameter('id_exposition');
        $station->complet_partiel = $request->getParameter('releve');
        $station->altitude_saisie = $request->getParameter('altitude');
        $station->remarques = $request->getParameter('remarques');
        $station->supprime = false;
        $station->srid_dessin = sfGeonatureConfig::$srid_dessin;
        $station->save();//enregistrement avec la methode save de symfony
        //sauvegarde de la géometrie
        $geometry = $request->getParameter('geometry');
        Doctrine_Query::create()
         ->update('TStationsBryo')
         ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
         // ->set('the_geom_27572','st_transform(st_geometryFromText(?, 3857),27572)', $geometry)
         // ->set('the_geom_2154','st_transform(st_geometryFromText(?, 3857),2154)', $geometry)
         ->where('id_station= ?', $station->getIdStation())
         ->execute();
        // ensuite on commence par supprimer tout ce qui concerne ce relevé si on est en update
        if($monaction=='update'){
            $id_station = $request->getParameter('id_station');
            //suppression des observateurs du relevé
            $deleted = Doctrine_Query::create()
                  ->delete()
                  ->from('CorBryoObservateur cfo')
                  ->where('cfo.id_station = ?', $id_station)
                  ->execute();            
        }
        //enregistrement dans la table cor_bryo_observateur
        $ids_observateurs = $request->getParameter('ids_observateurs');
        $array_observateurs = array();
        if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
        if(count($array_observateurs)>0){
            foreach ($array_observateurs as $id_role)
            {
                $cfo = new CorBryoObservateur();
                $cfo->id_station = $id_station;
                $cfo->id_role = $id_role; 
                $cfo->save();
            }
        }
        return $this->renderText("{success: true,id_station:".$station->getId_station()."}");
        // return $this->renderSuccess();//retour ajax pour Extjs ; retourne {success: true}
    }
    else{
        $this->redirect('@login');
    }
  }
  
  public function executeXls(sfRequest $request)
    {
        $listes = CorBryoTaxonTable::listXls($request);
        $csv_output = "Id_station\tTaxon_saisi\tTaxon enregistré\tTaxon_reference\tTaxon_complet\tAbondance\tDate\tSecteur\tCommune\tAcces\tObservateurs\tNiveau\tPointage\tSurface\tExposition\tAltitude\tRemarques\tPdop\tL93X\tL93Y";
        $csv_output .= "\n";
        foreach ($listes as $l)
        {  
            $id_station = $l['id_station'];
            $dateobs = $l['dateobs'];
            $nomcommune = $l['nomcommune'];
            $nom_secteur = $l['nom_secteur'];
            $info_acces = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $l['info_acces'] );
            $taxon = $l['taxon'];
            $taxon_ref = $l['taxon_ref'];
            $taxon_complet = $l['taxon_complet'];
            $taxon_saisi = $l['taxon_saisi'];
            $abondance = $l['id_abondance'];
            $observateurs = $l['observateurs'];
            $complet_partiel = $l['complet_partiel'];
            $nom_support = $l['nom_support'];
            $nom_exposition = $l['nom_exposition'];
            $altitude = $l['altitude'];
            $remarques = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $l['remarques'] );
            $l93x = $l['l93x'];
            $l93y = $l['l93y'];
            if ($l['pdop']==-1){$l['pdop'] = 'non précisé';}
            $pdop = $l['pdop'];
            $csv_output .= "$id_station\t$taxon_saisi\t$taxon\t$taxon_ref\t$taxon_complet\t$abondance\t$dateobs\t$nom_secteur\t$nomcommune\t$info_acces\t$observateurs\t$complet_partiel\t$nom_support\t$surface\t$nom_exposition\t$altitude\t$remarques\t$pdop\t$l93x\t$l93y\n";
        }
        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=bryophytes_".date("Y-m-d_His").".xls");
        print utf8_decode($csv_output);
        exit;
    }
  
}
