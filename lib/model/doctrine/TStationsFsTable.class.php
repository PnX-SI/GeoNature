<?php


class TStationsFsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TStationsFs');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_station, dateobs')
          ->from('TStationsFs')
          ->where('supprime=?', false)
          ->fetchArray();
        return $query;
    }
    
    public static function listAnneeFs()
    {
        $query = Doctrine_Query::create()
          ->select ("DATE_PART('year' ,dateobs) annee")
          ->distinct()
          ->from('TStationsFs')
          ->where('supprime=?', false)
          ->fetchArray();
        return $query;
    }
    
    private static function getcounterTaxon()
    {
        $query = Doctrine_Query::create()
          ->select('count(cft.id_station) nb')
          ->from('CorFsTaxon cft')
          ->innerJoin('cft.TStationsFs t')
          ->where('cft.id_station=?')
          ->addWhere('t.supprime is not true')
          ->addWhere('cft.supprime is not true');
        return $query;
    }

    private static function listObservateurs($id_station)
    {
        $observateurs = Doctrine_Query::create()
          ->select("o.id_role, concat(o.prenom_role, ' ', o.nom_role) observateur")
          ->distinct()
          ->from('TRoles o')
          ->innerJoin('o.CorFsObservateur cfo')
          ->where('cfo.id_station=?', $id_station)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['observateur'];
          array_push($obs,$o);
        }
        return implode(', ',$obs);
    }
    
    private static function listIdsObservateurs($id_station)
    {
        $observateurs = Doctrine_Query::create()
          ->select("id_role")
          ->distinct()
          ->from('CorFsObservateur')
          ->where('id_station=?', $id_station)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['id_role'];
          array_push($obs,$o);
        }
        return implode(',',$obs);
    }
    
    private static function listMicroreliefs($id_station)
    {
        $mrs = Doctrine_Query::create()
          ->select("m.id_microrelief, nom_microrelief")
          ->distinct()
          ->from('BibMicroreliefs m')
          ->innerJoin('m.CorFsMicrorelief cfm')
          ->where('cfm.id_station=?', $id_station)
          ->fetchArray();
          $microreliefs = array();
        foreach ($mrs as $mr)
        {
          $a = $mr['nom_microrelief'];
          array_push($microreliefs,$a);
        }
        return implode(', ',$microreliefs);
    }
    
    private static function listDelphines($id_station)
    {
        $ds = Doctrine_Query::create()
          ->select("id_delphine")
          ->from('CorFsDelphine ')
          ->where('id_station=?', $id_station)
          ->fetchArray();
        return $ds;
    }
    
    private static function listMicroreliefsForForm($id_station)
    {
        $mrs = Doctrine_Query::create()
          ->select("id_microrelief")
          ->from('CorFsMicrorelief')
          ->where('id_station=?', $id_station)
          ->fetchArray();

        return $mrs;
    }
 
    private static function getCounterObservateurs()
    {
        $o = Doctrine_Query::create()
          ->select('count(id_role) nb')
          ->from('CorFsObservateur cfo')
          ->where('cfo.id_station=?');
        return $o;
    } 

    private static function getGeomCommune($insee)
    {
        $geom = Doctrine_Query::create()
          ->select('the_geom')
          ->from('LCommunes')
          ->where('insee=?', $insee)
          ->fetchArray();
        return $geom[0]['the_geom'];
    } 
    
    private static function addFilters(mfQuery $query, array $params)
    {
        
        if (isset($params['secteur']) && $params['secteur']!=''){
            if (!isset($params['commune']) && $params['commune']==''){
                $query->leftJoin('com.LSecteurs se');
                $query->addWhere('com.id_secteur = ?', $params['secteur']);
            }
        }
        if (isset($params['commune']) && $params['commune']!=''){
            $query->addWhere('s.insee = ?', $params['commune']);
            // $geomcommune=self::getGeomCommune($params['commune']);
            // $query->addWhere("st_intersects(?,s.the_geom)=?",array($geomcommune,true));
        }
        if (isset($params['relecture']) && $params['relecture']!=null){
            if($params['relecture']=='o'){$relecture = true;}
            if($params['relecture']=='n'){$relecture = false;}
            $query->addWhere('s.validation= ?', $relecture);
        }       
        if (isset($params['box']) && count(explode(',',$params['box']))==4)
            $query->inBBox(explode(',',$params['box']));
        if (isset($params['releve']) && $params['releve']!='')
            $query->addWhere('s.complet_partiel = ?', $params['releve']);
        if (isset($params['by_id_station']) && $params['by_id_station']!='')
            $query->addWhere('s.id_station = ?', $params['by_id_station']);
        if (isset($params['programme']) && $params['programme']!='')
            $query->addWhere('s.id_programme_fs = ?', $params['programme']);
        if (isset($params['exposition']) && $params['exposition']!='')
            $query->addWhere('s.id_exposition = ?', $params['exposition']);
        if (isset($params['surface']) && $params['surface']!='')
            $query->addWhere('s.id_surface = ?', $params['surface']);
        if (isset($params['sophie']) && $params['sophie']!='')
            $query->addWhere('s.id_sophie = ?', $params['sophie']);
        if (isset($params['geom']) && $params['geom']!='')
            $query->intersect($params['geom']);
        if (isset($params['otaxon']) && $params['otaxon']!='')
            $query->addWhere('t.cd_nom = ?', $params['otaxon']);
        if (isset($params['rcd_nom']) && $params['rcd_nom']!=''){
            $statement = Doctrine_Manager::getInstance()->connection();
            $cd_nom=$params['rcd_nom'];
            $sql = "SELECT application_aggregate_taxons_rang_sp($cd_nom) AS les_cd_nom";
            $results = $statement->execute($sql);
            $liste = $results->fetchAll();
            $cds_nom = str_replace(array("{","}"),array("(",")"),array_values($liste['0']));
            // $mes_cd_nom = explode(",",$cds_nom[0]);
            $query->addWhere('t.cd_ref IN '.$cds_nom[0]);
            $query->addWhere('cft.supprime = ?', false);    
        }
        // print_r($query);
        if (isset($params['id_role']) && $params['id_role']!='')
            $query->addWhere('cfo.id_role = ?', $params['id_role']);
        if (isset($params['secteur']) && $params['secteur']!='')
            $query->addWhere('com.id_secteur = ?', $params['secteur']);        
        if (isset($params['startdate']) && $params['startdate']!=null && isset($params['enddate']) && $params['enddate']!=null){
            if($params['typeperiode']=='sa'){
                $query->addWhere("periode(dateobs,to_date(?,'Dd Mon DD YYYY'),to_date(?,'Dd Mon DD YYYY'))=?", array($params['startdate'],$params['enddate'],true));
            }
            if($params['typeperiode']=='aa'){
                $query->addWhere("dateobs BETWEEN to_date(?,'Dd Mon DD YYYY') AND to_date(?,'Dd Mon DD YYYY')", array($params['startdate'],$params['enddate']));
            }
        }
        if (isset($params['annee']) && $params['annee']!=null)
            $query->addWhere("DATE_PART('year' ,dateobs)= ?", $params['annee']);
       
            //$query->addWhere("periode(dateobs,?,?)=?", array($params['startdate'],$params['startdate'],true);
    }
    
	/**
	 * Return TZprospection for passed id
	 *
	 * @param integer $id_station
	 * @return TZprospection
	 */
	public static function get($id_station)
	{
		return Doctrine::getTable('TStationsFs')->find((int) $id_station);
	}

    public static function search($params, $validOnly)
    {
        $select = 's.id_station,s.complet_partiel releve,s.dateobs,s.date_insert,s.date_update,s.id_sophie,s.validation statut,'.
            'bs.nom_support,p.nom_programme_fs,su.nom_surface,e.nom_exposition,com.commune_min commune';
        $query = mfQuery::create('the_geom_3857');
        $query 
          ->select($select)
          ->distinct()
          ->from('TStationsFs s')
          ->leftJoin('s.BibSupports bs')
          ->leftJoin('s.BibProgrammesFs p')
          ->leftJoin('s.BibExpositions e')
          ->leftJoin('s.BibSurfaces su')
          ->leftJoin('s.LCommunes com')
          ->leftJoin('s.CorFsTaxon cft')
          ->leftJoin('cft.Taxref t')
          ->innerJoin('s.CorFsObservateur cfo')
          ->where('s.supprime=?', false);
        //on test si on est sur la recherche par défaut de la première page
        if ($params['start']=='no'){
            # Add search criterions
            self::addFilters($query, $params);
            if($validOnly){$query->addWhere('s.validation is true');} 
            $nbresult=count($query);
        }
        //si non on limite aux 50 dernières obs
        else{
            $query->limit(50);
            $nbresult=50;
        }
        // On met une limite pour éviter qu'il n'y ait trop de réponses à charger
        if($nbresult<=1000){
        $lesstations = $query
          ->orderBy('s.dateobs DESC')
          ->fetchArray();
            // Clean up array structure
            $counterTaxon = self::getcounterTaxon();
            $counterObs = self::getCounterObservateurs();
            foreach ($lesstations as $key => &$station)
            {
                $station['nom_programme_fs'] = $station['BibProgrammesFs'][0]['nom_programme_fs'];
                $station['nom_support'] = $station['BibSupports'][0]['nom_support'];
                //remise au format des dates
                $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
                preg_match($pattern, $station['date_update'], $d);
                $station['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
                preg_match($pattern, $station['date_insert'], $d);
                $station['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
                $nb_taxons = $counterTaxon->execute(array($station['id_station']), Doctrine::HYDRATE_ARRAY);
                $nb_obs = $counterObs->execute(array($station['id_station']), Doctrine::HYDRATE_ARRAY);
                $station['nb_taxons'] = $nb_taxons[0]['nb'];
                $station['nb_obs'] = $nb_obs[0]['nb'];
                $station['validated'] = (!$station['statut'])?false:true;
                $station['notvalidated'] = (!$station['statut'])?true:false;
                if($station['releve']=='C'){$station['releve']='Complet';}
                if($station['releve']=='P'){$station['releve']='Partiel';}
                unset($station['BibSupports'], $station['BibProgrammesFs']);
            }
        return $lesstations;
        }
        else{
            return 'trop';
        }
        
    }
    
    public static function findOne($id_station, $format = null)
    {
        $srid_local_export = sfGeonatureConfig::$srid_local;
        $fields = 's.id_station,s.complet_partiel releve,s.dateobs,s.date_insert,s.date_update,s.validation,s.id_sophie,'.
                  's.info_acces,s.meso_longitudinal,s.meso_lateral,s.canopee,'.
                  's.ligneux_hauts,s.ligneux_bas,s.ligneux_tbas,s.herbaces,s.mousses,s.litiere,s.altitude_retenue altitude,s.remarques,s.pdop,'.
                  'st_x(s.the_geom_'.$srid_local_export.') x_local, st_y(s.the_geom_'.$srid_local_export.') y_local,  st_x(ST_Transform(s.the_geom_3857,4326)) x_utm,  st_y(ST_Transform(s.the_geom_3857,4326)) y_utm,'.
                  'bs.nom_support, p.nom_programme_fs, e.nom_exposition, h.nom_homogene,su.nom_surface,'.
                  'bs.id_support, p.id_programme_fs, e.id_exposition, h.id_homogene,su.id_surface,com.commune_min commune';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $station = $query
              ->select($fields)
              ->from('TStationsFs s')
              ->leftJoin('s.BibSupports bs')
              ->leftJoin('s.BibProgrammesFs p')
              ->leftJoin('s.BibExpositions e')
              ->leftJoin('s.BibHomogenes h')
              ->leftJoin('s.LCommunes com')
              ->leftJoin('s.BibSurfaces su')
              ->where('id_station=?', $id_station)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($station['id_station']) && $station['id_station']=='')
          return false;

        // Format array
        
        if($station['releve']=='C'){$station['fullreleve']='Complet';}
        if($station['releve']=='P'){$station['fullreleve']='Partiel';}
        $station['nom_programme_fs'] = $station['BibProgrammesFs']['nom_programme_fs'];
        $station['nom_support'] = $station['BibSupports']['nom_support'];
        $station['nom_exposition'] = $station['BibExpositions']['nom_exposition'];
        $station['nom_homogene'] = $station['BibHomogenes']['nom_homogene'];
        $station['nom_surface'] = $station['BibSurfaces']['nom_surface'];
        $station['id_programme_fs'] = $station['BibProgrammesFs']['id_programme_fs'];
        $station['id_support'] = $station['BibSupports']['id_support'];
        $station['id_exposition'] = $station['BibExpositions']['id_exposition'];
        $station['id_homogene'] = $station['BibHomogenes']['id_homogene'];
        $station['id_surface'] = $station['BibSurfaces']['id_surface'];
        unset($station['BibSupports'], $station['BibProgrammesFs'], $station['BibExpositions'], $station['BibHomogenes'], $station['BibSurfaces']);
        //remise au format des dates
        $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
        preg_match($pattern, $station['date_update'], $d);
        $station['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $station['date_insert'], $d);
        $station['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $station['dateobs'], $d);
        $station['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        //$station['secteurs'] = self::listSecteurs($id_station);
        // la sation est tjs validable car la fonction isValidable a été modifiée pour tjs renvoyer true
        $station['validable'] = true;
        $counterTaxon = self::getcounterTaxon();
        $nb_taxons = $counterTaxon->execute(array($station['id_station']), Doctrine::HYDRATE_ARRAY);
        $station['lesobservateurs']= self::listIdsObservateurs($id_station);
        $station['ids_observateurs']= $station['lesobservateurs'];
        $delphines = self::listDelphines($id_station);
        if(ISSET($delphines[0])){$station['id_delphine1']= $delphines[0]['id_delphine'];}
        if(ISSET($delphines[1])){$station['id_delphine2']= $delphines[1]['id_delphine'];}
        $microreliefs = self::listMicroreliefsForForm($id_station);
        if(ISSET($microreliefs[0]['id_microrelief'])){$station['id_microrelief1']= $microreliefs[0]['id_microrelief'];}
        if(ISSET($microreliefs[1]['id_microrelief'])){$station['id_microrelief2']= $microreliefs[1]['id_microrelief'];}
        if(ISSET($microreliefs[2]['id_microrelief'])){$station['id_microrelief3']= $microreliefs[2]['id_microrelief'];}
        
        $station['nb_taxons'] = $nb_taxons[0]['nb'];
        $station['microreliefs'] = self::listMicroreliefs($id_station);
        $station['observateurs'] = self::listObservateurs($id_station);
        $station['x_utm'] = number_format($station['x_utm'],6);
        $station['y_utm'] = number_format($station['y_utm'],6);
        $station['x_local'] = sprintf("%.0f",$station['x_local']);
        $station['y_local'] = sprintf("%.0f",$station['y_local']);
        sfContext::getInstance()->getConfiguration()->loadHelpers('Url');
        $station['URI'] = url_for('@homepage', true).'/fs?id_station='.$station['id_station'];

        return $station;
    }
    
    public static function listSophie()
    {
        $statement = Doctrine_Manager::getInstance()->connection();
            $results = $statement->execute("SELECT DISTINCT id_sophie FROM florestation.t_stations_fs WHERE supprime = false AND id_sophie <> '0'");
            $sophie = $results->fetchAll();
        return $sophie;
    }
    public static function getMaxIdStation()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_station) as maxid' )
        ->from('TStationsFs')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
}