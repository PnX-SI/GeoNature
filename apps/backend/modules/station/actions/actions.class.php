<?php
class stationActions extends sfGeonatureActions
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
        $this->geojson = new Services_GeoJson();
	}
    
    public function executeIndexFs(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_florestation);
        }
        else{
            $this->redirect('@login');
        }
    }
	
	/**
	 * Simple list of all stations
	 *
	 * @return sfView::NONE
	 */
	public function executeAll()
	{
    $stations = TStationsFsTable::listAll();
		return $this->renderJSON($stations);
	}
	
	public function executeGetStationCount(sfRequest $request)
	{
		$query = TStationsFsTable::search(
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
            $station = TStationsFsTable::findOne($request->getParameter('id_station'), 'geoJSON');
            if (empty($station))
                return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($station), 'the_geom_3857', 'id_station'));
        }
        else if ($request->hasParameter('id_station'))
        {
            // detail of a station, without geom
          $station = TStationsFsTable::findOne($request->getParameter('id_station'));
          $this->forward404Unless($station);
          return $this->renderJSON(array($station));
        }
        else
        {
            // GeoJSON list of station
            $lesstations = TStationsFsTable::search(
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
        $taxons = CorFsTaxonTable::listTaxons($request->getParameter('id_station'), $this->getUser());
        if (empty($taxons))
          return $this->renderText(sfGeonatureActions::$EmptyGeoJSON);
        else
          return $this->renderText($this->geojson->encode($taxons, 'the_geom_3857', 'id_station'));
    }
    
    public function executeGetOneReleveTaxons(sfRequest $request)
    {
        $taxons = CorFsTaxonTable::listOneReleveTaxons($request->getParameter('id_station'));
        return $this->renderJSON($taxons);
    }
    
    public function executeGetTaxonsReference(sfRequest $request)
    {
        $taxons = TaxrefTable::getTaxonRefence($request->getParameter('lb_nom'),$request->getParameter('cd_nom'));
        return $this->renderText("{success: true,text:'".$taxons."'}");
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
        $this->forward404Unless($t=TStationsFsTable::get($request->getParameter('id_station')));
        $t->set('supprime', true);
        if ($t->trySave()){
          Doctrine_Query::create()
            ->update('CorFsTaxon')
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
            ->update('CorFsTaxon')
            ->set('supprime', '?', true)
            ->where('id_station=?', $id_station)
            ->addWhere('cd_nom=?', $cd_nom)
            ->execute();
          return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }
  
  public function executeValidate(sfRequest $request)
  {
  	if($this->getUser()->isAuthenticated()){
        $this->forward404Unless($request->isMethod('post'));
        $station = Doctrine::getTable('TStationsFs')->find($request->getParameter('id_station'));
        $this->forward404Unless($station);
        $station->setValidation(!$station->getValidation());
        if ($station->trySave())
          return $this->renderSuccess();
        else
          return $this->throwError();
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
        $verif_new = Doctrine::getTable('CorFsTaxon')->find(array($id_station,$new_cd_nom));
        if($verif_new){$verif_new->delete();}// si oui on le supprime
        if($old_cd_nom>0){
            $verif_old = Doctrine::getTable('CorFsTaxon')->find(array($id_station,$old_cd_nom));
            if($verif_old){$verif_old->delete();}// si oui on le supprime
        }
        //maintenant on créé un nouveau = new CorFsTaxon()
        $taxon = new CorFsTaxon();
        $taxon->id_station = $id_station;
        $taxon->cd_nom = $new_cd_nom;
        //on gère les nuls dans les strates
        if($request->getParameter('herb')=='' OR $request->getParameter('herb')==null){$herb=null;} else{$herb=$request->getParameter('herb');}
        if($request->getParameter('inf_1m')=='' OR $request->getParameter('inf_1m')==null){$inf_1m=null;} else{$inf_1m=$request->getParameter('inf_1m');}
        if($request->getParameter('de_1_4m')=='' OR $request->getParameter('de_1_4m')==null){$de_1_4m=null;} else{$de_1_4m=$request->getParameter('de_1_4m');}
        if($request->getParameter('sup_4m')=='' OR $request->getParameter('sup_4m')==null){$sup_4m=null;} else{$sup_4m=$request->getParameter('sup_4m');}
        if($request->getParameter('taxon_saisi')=='' OR $request->getParameter('taxon_saisi')==null){$taxon_saisi=null;} else{$taxon_saisi=$request->getParameter('taxon_saisi');}
        //on attribue les valeurs aux strates
        $taxon->herb = $herb;
        $taxon->inf_1m = $inf_1m;
        $taxon->de_1_4m = $de_1_4m;
        $taxon->sup_4m = $sup_4m;
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
                $new_id_station = TStationsFsTable::getMaxIdStation()+1;
                $station = new TStationsFs();
                break;
            case 'update':
                $station = Doctrine::getTable('TStationsFs')->find($request->getParameter('id_station')); 
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
        if($request->getParameter('pdop')=='' OR $request->getParameter('pdop')==null){$pdop=sfGeonatureConfig::$default_pdop;} else{$pdop=$request->getParameter('pdop');}
        $station->pdop = $pdop;
        $station->id_surface = $request->getParameter('id_surface');
        if($request->getParameter('id_sophie')=='' OR $request->getParameter('id_sophie')==null){$id_sophie=0;} else{$id_sophie=$request->getParameter('id_sophie');}
        $station->id_sophie = $id_sophie;
        $station->id_exposition = $request->getParameter('id_exposition');
        $station->id_protocole = sfGeonatureConfig::$id_protocole_florestation;
        $station->id_lot = sfGeonatureConfig::$id_lot_florestation;
        $station->id_organisme = sfGeonatureConfig::$id_organisme;
        $station->complet_partiel = $request->getParameter('releve');
        $station->altitude_saisie = $request->getParameter('altitude');
        $station->id_programme_fs = $request->getParameter('id_programme_fs');
        $station->id_homogene = $request->getParameter('id_homogene');
        if($request->getParameter('meso_longitudinal')=='' OR $request->getParameter('meso_longitudinal')==null){$meso_longitudinal=null;} else{$meso_longitudinal=$request->getParameter('meso_longitudinal');}
        $station->meso_longitudinal = $meso_longitudinal;
        if($request->getParameter('meso_lateral')=='' OR $request->getParameter('meso_lateral')==null){$meso_lateral=null;} else{$meso_lateral=$request->getParameter('meso_lateral');}
        $station->meso_lateral = $meso_lateral;
        if($request->getParameter('canopee')=='' OR $request->getParameter('canopee')==null){$canopee=0;} else{$canopee=$request->getParameter('canopee');}
        $station->canopee = $canopee;
        if($request->getParameter('ligneux_hauts')=='' OR $request->getParameter('ligneux_hauts')==null){$ligneux_hauts=0;} else{$ligneux_hauts=$request->getParameter('ligneux_hauts');}
        $station->ligneux_hauts = $ligneux_hauts;
        if($request->getParameter('ligneux_bas')=='' OR $request->getParameter('ligneux_bas')==null){$ligneux_bas=0;} else{$ligneux_bas=$request->getParameter('ligneux_bas');}
        $station->ligneux_bas = $ligneux_bas;
        if($request->getParameter('ligneux_tbas')=='' OR $request->getParameter('ligneux_tbas')==null){$ligneux_tbas=0;} else{$ligneux_tbas=$request->getParameter('ligneux_tbas');}
        $station->ligneux_tbas = $ligneux_tbas;
        if($request->getParameter('herbaces')=='' OR $request->getParameter('herbaces')==null){$herbaces=0;} else{$herbaces=$request->getParameter('herbaces');}
        $station->herbaces = $herbaces;
        if($request->getParameter('mousses')=='' OR $request->getParameter('mousses')==null){$mousses=0;} else{$mousses=$request->getParameter('mousses');}
        $station->mousses = $mousses;
        if($request->getParameter('litiere')=='' OR $request->getParameter('litiere')==null){$litiere=0;} else{$litiere=$request->getParameter('litiere');}
        $station->litiere = $litiere;
        $station->remarques = $request->getParameter('remarques');
        $station->srid_dessin = sfGeonatureConfig::$srid_dessin;
        $station->supprime = false;
        $station->save();//enregistrement avec la methode save de symfony
        //sauvegarde de la géometrie
        $geometry = $request->getParameter('geometry');
        Doctrine_Query::create()
         ->update('TStationsFs')
         ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
         ->where('id_station= ?', $station->getIdStation())
         ->execute();
        // ensuite on commence par supprimer tout ce qui concerne ce relevé si on est en update
        if($monaction=='update'){
            $id_station = $request->getParameter('id_station');
            //suppression des code Delphine du relevé
            $deleted = Doctrine_Query::create()
                  ->delete()
                  ->from('CorFsDelphine cfd')
                  ->where('cfd.id_station = ?', $id_station)
                  ->execute();
            //suppression des code Delphine du relevé
            $deleted = Doctrine_Query::create()
                  ->delete()
                  ->from('CorFsMicrorelief cfm')
                  ->where('cfm.id_station = ?', $id_station)
                  ->execute();
            //suppression des observateurs du relevé
            $deleted = Doctrine_Query::create()
                  ->delete()
                  ->from('CorFsObservateur cfo')
                  ->where('cfo.id_station = ?', $id_station)
                  ->execute();            
        }
        //enregistrement dans la table cor_fs_delphine
        for ($i=1; $i<=2;$i++){
            if($request->getParameter('id_delphine'.$i)!=null OR $request->getParameter('id_delphine'.$i)!=''){
                $cfd = new CorFsDelphine();
                $cfd->id_station = $id_station;
                $cfd->id_delphine = $request->getParameter('id_delphine'.$i);
                $cfd->save();
            }
        }
        //enregistrement dans la table cor_fs_microrelief
        for ($i=1; $i<=3;$i++){
            if($request->getParameter('id_microrelief'.$i)!=null OR $request->getParameter('id_microrelief'.$i)!=''){
                $cfm = new CorFsMicrorelief();
                $cfm->id_station = $id_station;
                $cfm->id_microrelief = $request->getParameter('id_microrelief'.$i);
                $cfm->save();
            }
        }
        //enregistrement dans la table cor_fs_observateur
        $ids_observateurs = $request->getParameter('ids_observateurs');
        $array_observateurs = array();
        if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
        if(count($array_observateurs)>0){
            foreach ($array_observateurs as $id_role)
            {
                $cfo = new CorFsObservateur();
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
        $listes = CorFsTaxonTable::listXls($request);
        $csv_output = "Id_station\tTaxon_saisi\tTaxon enregistré\tTaxon_reference\tTaxon_complet\tHerb\tinf_1m\t1a4m\tSup_4m\tDate\tSecteur\tCommune\tAcces\tObservateurs\tNiveau\tProgramme\tIdSophie\tPointage\tSurface\tHomogene\tExposition\tAltitude\tMicro-reliefs\tMeso-relief_longitudinal\tmeso-relief_lateral\tCanopee\tLigneux_hauts\tLigneux_bas\tLigneux_tbas\tHerbaces\tMousses\tLitiere\tCodes_delphine\tRemarques\tPdop\tX\tY\tRelue";
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
            $herb = $l['herb'];
            $inf_1m = $l['inf_1m'];
            $de_1_4m = $l['de_1_4m'];
            $sup_4m = $l['sup_4m'];
            $observateurs = $l['observateurs'];
            $nom_programme = $l['nom_programme_fs'];
            $id_sophie = $l['id_sophie'];
            $complet_partiel = $l['complet_partiel'];
            $nom_support = $l['nom_support'];
            $nom_surface = $l['nom_surface'];
            $nom_homogene = $l['nom_homogene'];
            $nom_exposition = $l['nom_exposition'];
            $altitude = $l['altitude'];
            $microreliefs = $l['microreliefs'];
            $meso_longitudinal = $l['meso_longitudinal'];
            $meso_lateral = $l['meso_lateral'];
            $canopee = $l['canopee'];
            $ligneux_hauts = $l['ligneux_hauts'];
            $ligneux_bas = $l['ligneux_bas'];
            $ligneux_tbas = $l['ligneux_tbas'];
            $herbaces = $l['herbaces'];
            $mousses = $l['mousses'];
            $litiere = $l['litiere'];
            $delphines = $l['delphines'];
            $remarques = str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $l['remarques'] );
            $x = $l['y_local'];
            $y = $l['y_local'];
            $relue = (!$l['relue'])?'non':'oui';
            if ($l['pdop']==-1){$l['pdop'] = 'non précisé';}
            $pdop = $l['pdop'];
            $csv_output .= "$id_station\t$taxon_saisi\t$taxon\t$taxon_ref\t$taxon_complet\t$herb\t$inf_1m\t$de_1_4m\t$sup_4m\t$dateobs\t$nom_secteur\t$nomcommune\t$info_acces\t$observateurs\t$complet_partiel\t$nom_programme\t$id_sophie\t$nom_support\t$nom_surface\t$nom_homogene\t$nom_exposition\t$altitude\t$microreliefs\t$meso_longitudinal\t$meso_lateral\t$canopee\t$ligneux_hauts\t$ligneux_bas\t$ligneux_tbas\t$herbaces\t$mousses\t$litiere\t$delphines\t$remarques\t$pdop\t$x\t$y\t$relue\n";
        }
        header("Content-type: application/vnd.ms-excel; charset=utf-8\n\n");
        header("Content-disposition: attachment; filename=fs_".date("Y-m-d_His").".xls");
        print utf8_decode($csv_output);
        exit;
    }
  
}
