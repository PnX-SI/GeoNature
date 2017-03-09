<?php


class TStationsBryoTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TStationsBryo');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_station, dateobs')
          ->from('TStationsBryo')
          ->where('supprime=?', false)
          ->fetchArray();
        return $query;
    }
    
    public static function listAnneeBryo()
    {
        $query = Doctrine_Query::create()
          ->select ("DATE_PART('year' ,dateobs) annee")
          ->distinct()
          ->from('TStationsBryo')
          ->where('supprime=?', false)
          ->fetchArray();
        return $query;
    }
    
    private static function getcounterTaxon()
    {
        $query = Doctrine_Query::create()
          ->select('count(cft.id_station) nb')
          ->from('CorBryoTaxon cft')
          ->innerJoin('cft.TStationsBryo t')
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
          ->innerJoin('o.CorBryoObservateur cfo')
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
          ->from('CorBryoObservateur')
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
    
    private static function getCounterObservateurs()
    {
        $o = Doctrine_Query::create()
          ->select('count(id_role) nb')
          ->from('CorBryoObservateur cfo')
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
    private static function makePolygonBBox(array $box)
    {
        $box = array_map('floatval', $box);

        $A = $box[0].' '.$box[1];
        $B = $box[0].' '.$box[3];
        $C = $box[2].' '.$box[3];
        $D = $box[2].' '.$box[1];
        
        $polygon_box = "POLYGON(($A, $B, $C, $D, $A))";

        return $polygon_box;
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
        }    
        // if (isset($params['box']) && count(explode(',',$params['box']))==4)
            // $query->inBBox(explode(',',$params['box']));
        if (isset($params['bbox'])){$bbox = $params['bbox'];}
        if (isset($params['box'])){$bbox = $params['box'];}
        if ((isset($params['bbox']) && count(explode(',',$params['bbox']))==4)||(isset($params['box']) && count(explode(',',$params['box']))==4))
            $query->addWhere("s.the_geom_3857 && ST_GeomFromText(?, 3857)",self::makePolygonBBox(explode(',',$bbox)));
        if (isset($params['releve']) && $params['releve']!='')
            $query->addWhere('s.complet_partiel = ?', $params['releve']);
        if (isset($params['by_id_station']) && $params['by_id_station']!='')
            $query->addWhere('s.id_station = ?', $params['by_id_station']);
        if (isset($params['exposition']) && $params['exposition']!='')
            $query->addWhere('s.id_exposition = ?', $params['exposition']);
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
            $query->addWhere('t.cd_ref IN '.$cds_nom[0]);
            $query->addWhere('cft.supprime = ?', false);    
        }
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
    }
    
	/**
	 * Return TZprospection for passed id
	 *
	 * @param integer $id_station
	 * @return TZprospection
	 */
	public static function get($id_station)
	{
		return Doctrine::getTable('TStationsBryo')->find((int) $id_station);
	}

    public static function search($params)
    {
        $select = 's.id_station,s.complet_partiel releve,s.dateobs,s.date_insert,s.date_update,'.
            'bs.nom_support,e.nom_exposition,com.commune_min commune';
        $query = mfQuery::create('the_geom_3857');
        $query 
          ->select($select)
          ->distinct()
          ->from('TStationsBryo s')
          ->leftJoin('s.BibSupports bs')
          ->leftJoin('s.BibExpositionsBryo e')
          ->leftJoin('s.LCommunes com')
          ->leftJoin('s.CorBryoTaxon cft')
          ->leftJoin('cft.Taxref t')
          ->innerJoin('s.CorBryoObservateur cfo')
          ->where('s.supprime=?', false);
        //on test si on est sur la recherche par défaut de la première page
        if ($params['start']=='no'){
            # Add search criterions
            self::addFilters($query, $params);
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
                $station['nom_support'] = $station['BibSupports']['nom_support'];
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
                if($station['releve']=='C'){$station['releve']='Complet';}
                if($station['releve']=='P'){$station['releve']='Partiel';}
                unset($station['BibSupports']);
            }
        return $lesstations;
        }
        else{
            return 'trop';
        }
        
    }
    
    public static function findOne($id_station, $format = null)
    {
        $fields = 's.id_station,s.complet_partiel releve,s.dateobs,s.surface,s.date_insert,s.date_update,s.info_acces,'.
                  's.altitude_retenue altitude,s.remarques,s.pdop,'.
                  'st_x(s.the_geom_local) x_local, st_y(s.the_geom_local) y_local,  st_x(ST_Transform(s.the_geom_local,4326)) x_utm,  st_y(ST_Transform(s.the_geom_local,4326)) y_utm,'.
                  'bs.nom_support, e.nom_exposition,'.
                  'bs.id_support, e.id_exposition, com.commune_min commune';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $station = $query
              ->select($fields)
              ->from('TStationsBryo s')
              ->leftJoin('s.BibSupports bs')
              ->leftJoin('s.BibExpositionsBryo e')
              ->leftJoin('s.LCommunes com')
              ->where('id_station=?', $id_station)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($station['id_station']) && $station['id_station']=='')
          return false;

        // Format array
        
        if($station['releve']=='C'){$station['fullreleve']='Complet';}
        if($station['releve']=='P'){$station['fullreleve']='Partiel';}
        $station['nom_support'] = $station['BibSupports']['nom_support'];
        $station['nom_exposition'] = $station['BibExpositionsBryo']['nom_exposition'];
        $station['id_support'] = $station['BibSupports']['id_support'];
        $station['id_exposition'] = $station['BibExpositionsBryo']['id_exposition'];
        unset($station['BibSupports'],  $station['BibExpositionsBryo']);
        //remise au format des dates
        $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
        preg_match($pattern, $station['date_update'], $d);
        $station['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $station['date_insert'], $d);
        $station['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $station['dateobs'], $d);
        $station['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        //$station['secteurs'] = self::listSecteurs($id_station);
        $counterTaxon = self::getcounterTaxon();
        $nb_taxons = $counterTaxon->execute(array($station['id_station']), Doctrine::HYDRATE_ARRAY);
        $station['lesobservateurs']= self::listIdsObservateurs($id_station);
        $station['ids_observateurs']= $station['lesobservateurs'];  
        $station['nb_taxons'] = $nb_taxons[0]['nb'];
        $station['observateurs'] = self::listObservateurs($id_station);
        $station['x_utm'] = number_format($station['x_utm'],6);
        $station['y_utm'] = number_format($station['y_utm'],6);
        $station['x_local'] = sprintf("%.0f",$station['x_local']);
        $station['y_local'] = sprintf("%.0f",$station['y_local']);
        sfContext::getInstance()->getConfiguration()->loadHelpers('Url');
        $station['URI'] = url_for('@homepage', true).'/bryo?id_station='.$station['id_station'];

        return $station;
    }
    
    public static function getMaxIdStation()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_station) as maxid' )
        ->from('TStationsBryo')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
}