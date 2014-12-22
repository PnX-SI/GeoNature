<?php
class cfActions extends sfFauneActions
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
    * Get GeoJSON fiche from id_cf passed
    * @param sfRequest $request
    * @return sfView::NONE
    */
    public function executeGetOneFiche(sfRequest $request)
    {
        if ($request->hasParameter('id_cf') && $request->getParameter('format','')=='geoJSON')
        {
            $fiche = TFichesCfTable::findOne($request->getParameter('id_cf'), 'geoJSON');
            if (empty($fiche))
                return $this->renderText(sfFauneActions::$EmptyGeoJSON);
            else
                return $this->renderText($this->geojson->encode(array($fiche), 'the_geom_3857', 'id_cf'));
        }
    }
	
    public function executeGetListRelevesCf(sfRequest $request)
    {
        $taxons = TRelevesCfTable::getListRelevesCf($request->getParameter('id_cf'));
        return $this->renderJSON($taxons);
    }

  /**
   * Delete a fiche (in fact mark it as supprime=true)
   * @param sfRequest $request
   * @return sfView::NONE
   */
  public function executeDeleteFicheCf(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){ 
        $this->forward404Unless($t=TfichesCfTable::get($request->getParameter('id_cf')));
        $t->set('supprime', true);
        if ($t->trySave()){
          Doctrine_Query::create()
            ->update('TfichesCf')
            ->set('supprime', '?', true)
            ->where('id_cf=?', $t->getId_cf())
            ->execute();
          return $this->renderSuccess();
        }
        else{return $this->throwError();}
    }
    else{return sfView::ERROR;}
  }
  
  public function executeDeleteReleveCf(sfRequest $request)
  {
    if($this->getUser()->isAuthenticated()){
        $id_releve_cf = $request->getParameter('id_releve_cf');
          Doctrine_Query::create()
            ->update('TRelevesCf')
            ->set('supprime', '?', true)
            ->where('id_releve_cf=?', $id_releve_cf)
            ->execute();
          return $this->renderSuccess();
    }
    else{return sfView::ERROR;}
  }
  
    public function saveTaxons($id_cf,$string_taxons,$monaction)
    {
        if($this->getUser()->isAuthenticated()){
            // $new_cd_nom = $request->getParameter('new_cd_nom');
            // $old_cd_nom = $request->getParameter('old_cd_nom');

            //on vérifie que le taxon (old ou new) n'existe pas déjà éventuellement avec supprime = true pour cette station
            // $verif_new = Doctrine::getTable('CorFsTaxon')->find(array($id_station,$new_cd_nom));
            // if($verif_new){$verif_new->delete();}// si oui on le supprime
            // if($old_cd_nom>0){
                // $verif_old = Doctrine::getTable('CorFsTaxon')->find(array($id_station,$old_cd_nom));
                // if($verif_old){$verif_old->delete();}// si oui on le supprime
            // }
            // print_r($string_taxons);
            
            $array_taxons = explode('|',$string_taxons);
            // Suppression des taxons qui existe et qui ont été supprimé dans le formulaire javascript
            $mon_array = array(); // dans ce tableau on va pousser tous les enregistrements qui ont un id_releve_cf donc ceux qui ne sont pas nouveau
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                if($array_taxon[0]!='' OR $array_taxon[0]!=null){array_push($mon_array,$array_taxon[0]);}
            }
            //s'il y a des id_releve_cf on boucle pour supprimer ceux de la fiche qui ne serait plus dans le tableau $array_taxon
            // si comme dans le cas d'un ajout de taxon pour une nouvelle fiche, il n'y a pas encore de id_releve_cf il n'y a rien à supprimer
            if(count($mon_array)>0){
                $string_del_tx = implode(', ',$mon_array);//on créé une chaine avec les taxon à supprimer
                $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                $sql = "UPDATE contactfaune.t_releves_cf SET supprime = true WHERE id_cf = $id_cf AND id_releve_cf NOT IN ($string_del_tx);";
                $a = $dbh->query($sql);
            }
            //on boucle sur la chaine des taxons envoyée par le formulaire pour récupérer les champs et on insert ou on update
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                // Récupération des valeurs dans des variables
                $id_releve_cf = $array_taxon[0];
                $id_taxon = $array_taxon[1];
                $nom_taxon_saisi = $array_taxon[4];
                $id_critere_cf = $array_taxon[5];
                $am = $array_taxon[6];
                $af = $array_taxon[7];
                $ai = $array_taxon[8];
                $na = $array_taxon[9];
                $jeune = $array_taxon[10];
                $yearling = $array_taxon[11];
                $sai = $array_taxon[12];
                $commentaire = $array_taxon[13];
                $cd_ref_origine = $array_taxon[14];
                //on récupère l'enregistrement ou on le crée
                // $taxon = new TRelevesCf();
                if($id_releve_cf==null OR $id_releve_cf==''){
                    $taxon = new TRelevesCf();
                    $id_releve_cf = TRelevesCfTable::getMaxIdReleve()+1;
                }
                else{$taxon = Doctrine::getTable('TRelevesCf')->find($id_releve_cf);}
                //on passe les valeur et on enregistre
                $taxon->id_releve_cf = $id_releve_cf;
                $taxon->id_cf = $id_cf;
                $taxon->id_taxon = $id_taxon;
                $taxon->nom_taxon_saisi = str_replace('<!>',',',$nom_taxon_saisi);
                $taxon->id_critere_cf = $id_critere_cf;
                $taxon->am= $am;
                $taxon->af = $af;
                $taxon->ai = $ai;
                $taxon->na = $na;
                $taxon->jeune = $jeune;
                $taxon->yearling = $yearling;
                $taxon->sai = $sai;
                $taxon->commentaire = str_replace('<!>',',',$commentaire);
                $taxon->cd_ref_origine = $cd_ref_origine;
                $taxon->save();
                // return $this->renderText("{success: true,toto}");
            }
            // return $this->renderText("{success: true,data:".print_r($taxon)."}");
            return true;
        }
        else{return sfView::ERROR;}
    }
  
    public function executeSaveCf(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){    
            $monaction = $request->getParameter('monaction');//on récupère l'action pour savoir si on update ou si on créé un nouvel enregistrement
            //création de l'objet selon update ou ajout
            switch ($monaction) {
                case 'add':
                    $new_id_cf = TFichesCfTable::getMaxIdFiche()+1;
                    $fiche = new TfichesCf();
                    break;
                case 'update':
                    $fiche = Doctrine::getTable('TfichesCf')->find($request->getParameter('id_cf')); 
                    break;
                default:
                    break;
            }
            if($monaction=='add') {
                $id_cf = $new_id_cf;
                $fiche->id_cf = $id_cf;
                $fiche->saisie_initiale = 'web';
                $fiche->id_organisme = sfGeonatureConfig::$id_organisme;
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
            $fiche->id_protocole = sfGeonatureConfig::$id_protocole_cf;
            $fiche->srid_dessin = sfGeonatureConfig::$srid_dessin;
            $fiche->id_lot = sfGeonatureConfig::$id_lot_cf;
            // $fiche->id_lot = $request->getParameter('id_lot');
            $fiche->save();//enregistrement avec la methode save de symfony
            // ensuite on commence par supprimer tout ce qui concerne cette fiche si on est en update
            
            if($monaction=='update'){
                $id_cf = $request->getParameter('id_cf');
                //suppression des observateurs de la fiche
                $deleted = Doctrine_Query::create()
                      ->delete()
                      ->from('CorRoleFicheCf crfc')
                      ->where('crfc.id_cf = ?', $id_cf)
                      ->execute();            
            }
            //enregistrement dans la table cor_role_fiche_cf
            $ids_observateurs = $request->getParameter('ids_observateurs');
            $array_observateurs = array();
            if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
            if(count($array_observateurs)>0){
                foreach ($array_observateurs as $id_role)
                {
                    $crfc = new CorRoleFicheCf();
                    $crfc->id_cf = $id_cf;
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
             ->update('TFichesCf')
             ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
             ->where('id_cf= ?', $fiche->getId_cf())
             ->execute();
            
            if($request->hasParameter('sting_taxons')){self::saveTaxons($id_cf,$request->getParameter('sting_taxons'),$monaction);}
            return $this->renderText("{success: true,id_cf:".$fiche->getId_cf()."}");
            // return $this->renderSuccess();//retour ajax pour Extjs ; retourne {success: true}
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function saveTaxonsMortalite($id_cf,$string_taxons,$monaction)
    {
        if($this->getUser()->isAuthenticated()){
            $array_taxons = explode('|',$string_taxons);
            // Suppression des taxons qui existe et qui ont été supprimé dans le formulaire javascript
            $mon_array = array(); // dans ce tableau on va pousser tous les enregistrements qui ont un id_releve_cf donc ceux qui ne sont pas nouveau
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                if($array_taxon[0]!='' OR $array_taxon[0]!=null){array_push($mon_array,$array_taxon[0]);}
            }
            //s'il y a des id_releve_cf on boucle pour supprimer ceux de la fiche qui ne serait plus dans le tableau $array_taxon
            // si comme dans le cas d'un ajout de taxon pour une nouvelle fiche, il n'y a pas encore de id_releve_cf il n'y a rien à supprimer
            if(count($mon_array)>0){
                $string_del_tx = implode(', ',$mon_array);//on créé une chaine avec les taxon à supprimer
                $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
                $sql = "UPDATE contactfaune.t_releves_cf SET supprime = true WHERE id_cf = $id_cf AND id_releve_cf NOT IN ($string_del_tx);";
                $a = $dbh->query($sql);
            }
            //on boucle sur la chaine des taxons envoyée par le formulaire pour récupérer les champs et on insert ou on update
            foreach ($array_taxons as $string_taxon){
                $array_taxon = explode(",",$string_taxon);
                //construction de variable dynamique avec le nom des champs
                // for($i=1;$i<count($array_keys);$i++){
                    // ${$var$array_keys[$i]} = $array_taxon[$i];
                    // $taxons->{$var$array_keys[$i]} = $array_taxon[$i];
                // }
                // Récupération des valeurs dans des variables
                $id_releve_cf = $array_taxon[0];
                $id_taxon = $array_taxon[1];
                $nom_taxon_saisi = $array_taxon[4];
                $id_critere_cf = 2;
                $am = $array_taxon[7];
                $af = $array_taxon[8];
                $ai = $array_taxon[9];
                $na = $array_taxon[10];
                $jeune = $array_taxon[11];
                $yearling = $array_taxon[12];
                $sai = $array_taxon[13];
                $commentaire = $array_taxon[14];
                $cd_ref_origine = $array_taxon[15];
                $prelevement = $array_taxon[17];
                //on récupère l'enregistrement ou on le crée
                // $taxon = new TRelevesCf();
                if($id_releve_cf==null OR $id_releve_cf==''){
                    $taxon = new TRelevesCf();
                    $id_releve_cf = TRelevesCfTable::getMaxIdReleve()+1;
                }
                else{$taxon = Doctrine::getTable('TRelevesCf')->find($id_releve_cf);}
                //on passe les valeur et on enregistre
                $taxon->id_releve_cf = $id_releve_cf;
                $taxon->id_cf = $id_cf;
                $taxon->id_taxon = $id_taxon;
                $taxon->nom_taxon_saisi = str_replace('<!>',',',$nom_taxon_saisi);
                $taxon->id_critere_cf = $id_critere_cf;
                $taxon->am = $am;
                $taxon->af = $af;
                $taxon->ai = $ai;
                $taxon->na = $na;
                $taxon->jeune = $jeune;
                $taxon->yearling = $yearling;
                $taxon->sai = $sai;
                $taxon->commentaire = str_replace('<!>',',',$commentaire);
                $taxon->cd_ref_origine = $cd_ref_origine;
                $taxon->prelevement = $prelevement;
                $taxon->save();
            }
            // return $this->renderText("{success: true,data:".print_r($taxon)."}");
            return true;
        }
        else{return sfView::ERROR;}
    }
    
    public function executeSaveMortalite(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){    
            $monaction = $request->getParameter('monaction');//on récupère l'action pour savoir si on update ou si on créé un nouvel enregistrement
            //création de l'objet selon update ou ajout
            switch ($monaction) {
                case 'add':
                    $new_id_cf = TFichesCfTable::getMaxIdFiche()+1;
                    $fiche = new TfichesCf();
                    break;
                case 'update':
                    $fiche = Doctrine::getTable('TfichesCf')->find($request->getParameter('id_cf')); 
                    break;
                default:
                    break;
            }
            if($monaction=='add') {
                $id_cf = $new_id_cf;
                $fiche->id_cf = $id_cf;
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
            $fiche->saisie_initiale = 'web';
            $fiche->srid_dessin = sfGeonatureConfig::$srid_dessin;
            $fiche->id_organisme = sfGeonatureConfig::$id_organisme;
            $fiche->id_protocole = sfGeonatureConfig::$id_protocole_mortalite;
            $fiche->id_lot = sfGeonatureConfig::$id_lot_mortalite;
            // $fiche->id_lot = $request->getParameter('id_lot');
            $fiche->save();//enregistrement avec la methode save de symfony
            // ensuite on commence par supprimer tout ce qui concerne cette fiche si on est en update
            if($monaction=='update'){
                $id_cf = $request->getParameter('id_cf');
                //suppression des observateurs de la fiche
                $deleted = Doctrine_Query::create()
                      ->delete()
                      ->from('CorRoleFicheCf crfc')
                      ->where('crfc.id_cf = ?', $id_cf)
                      ->execute();            
            }
            //enregistrement dans la table cor_role_fiche_cf
            $ids_observateurs = $request->getParameter('ids_observateurs');
            $array_observateurs = array();
            if($ids_observateurs!=''){$array_observateurs = explode(",",$ids_observateurs);}
            if(count($array_observateurs)>0){
                foreach ($array_observateurs as $id_role)
                {
                    $crfc = new CorRoleFicheCf();
                    $crfc->id_cf = $id_cf;
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
             ->update('TFichesCf')
             ->set('the_geom_3857','st_geometryFromText(?, 3857)', $geometry)
             ->where('id_cf= ?', $fiche->getId_cf())
             ->execute();
            
            if($request->hasParameter('sting_taxons')){self::saveTaxonsMortalite($id_cf,$request->getParameter('sting_taxons'),$monaction);}
            return $this->renderText("{success: true,id_cf:".$fiche->getId_cf()."}");
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
