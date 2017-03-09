<?php


class TZprospectionTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TZprospection');
    }
    public static function listAll()
    {
        $leszps = Doctrine_Query::create()
          ->select('indexzp, dateobs')
          ->from('TZprospection')
          ->where('zp.supprime=?', false)
          ->fetchArray();

        return $leszps;
    }
    
    public static function listAnnee()
    {
        $annees = Doctrine_Query::create()
          ->select ("DATE_PART('year' ,dateobs) annee")
          ->distinct()
          ->from('TZprospection')
          ->where('supprime=?', false)
          //->groupBy('annee')
          ->fetchArray();

        return $annees;
    }
    
    private static function getCounterAp()
    {
        $q = Doctrine_Query::create()
          ->select('count(indexap) nb')
          ->from('TApresence ap')
          ->where('ap.indexzp=?')
          ->addWhere('ap.supprime is not true');
        //pas de relecture des ap donc le consultant peut voir toutes les zap s'il peut voir un zp
        /*if (sfContext::getInstance()->getUser()->getAttribute('statuscode')==1)
        {
          $q->addWhere('ap.validation is true');
        }*/
        return $q;
    }

    private static function listObservateurs($indexzp)
    {
        $observateurs = Doctrine_Query::create()
          ->select("o.id_role, concat(o.prenom_role, ' ', o.nom_role) observateur")
          ->distinct()
          ->from('TRoles o')
          ->innerJoin('o.CorZpObs zo')
          ->where('zo.indexzp=?', $indexzp)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['observateur'];
          array_push($obs,$o);
        }
        return implode(', ',$obs);
    }
    
    private static function listIdsObservateurs($indexzp)
    {
        $observateurs = Doctrine_Query::create()
          ->select("codeobs")
          ->distinct()
          ->from('CorZpObs')
          ->where('indexzp=?', $indexzp)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['codeobs'];
          array_push($obs,$o);
        }
        return implode(',',$obs);
    }
 
    private static function getCounterObservateurs()
    {
        $o = Doctrine_Query::create()
          ->select('count(codeobs) nb')
          ->from('CorZpObs c')
          ->where('c.indexzp=?');
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

    private static function getGeomSecteur($id)
    {
        $geom = Doctrine_Query::create()
          ->select('the_geom')
          ->from('LSecteurs')
          ->where('id_secteur=?', $id)
          ->fetchArray();
        return $geom[0]['the_geom'];
    } 
    
     /**
   * returns list of objets that must bee count for passed cd_nom
   *
   * @param integer $cd_nom
   * @return array
   */ 
    private static function listTaxonObjets($cd_nom)
    {
        $objets = Doctrine_Query::create()
          ->select("id_objet_new")
          ->from('CorTaxonObjet')
          ->where('cd_nom=?', $cd_nom)
          ->fetchArray();
          $objs = array();
        foreach ($objets as &$objet)
        {
          $o = $objet['id_objet_new'];
          array_push($objs,$o);
        }
        return implode(', ',$objs);
    }
    
    public static function getMaxIndexZp()
    {
        $ids= Doctrine_Query::create()
        ->select('max(indexzp) as maxid' )
        ->from('TZprospection')
        ->where('indexzp < ?',1000000)
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
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
        if (isset($params['bbox'])){$bbox = $params['bbox'];}
        if (isset($params['box'])){$bbox = $params['box'];}
        if ((isset($params['bbox']) && count(explode(',',$params['bbox']))==4)||(isset($params['box']) && count(explode(',',$params['box']))==4))
            $query->addWhere("zp.the_geom_3857 && ST_GeomFromText(?, 3857)",self::makePolygonBBox(explode(',',$bbox)));
        //if (isset($params['taxonf']) && $params['taxonf']!='')
            //$query->addWhere('t.francais ILIKE ?', '%'.$params['taxonf'].'%');
        if (isset($params['lcd_nom']) && $params['lcd_nom']!='')
            $query->addWhere('zp.cd_nom = ?', $params['lcd_nom']);
        if (isset($params['fcd_nom']) && $params['fcd_nom']!='')
            $query->addWhere('zp.cd_nom = ?', $params['fcd_nom']);    
        if (isset($params['id_role']) && $params['id_role']!='')
            $query->addWhere('o.codeobs = ?', $params['id_role']);
        if (isset($params['commune']) && $params['commune']!=''){
            $geomcommune=self::getGeomCommune($params['commune']);
            $query->addWhere("st_intersects(?,zp.the_geom_local)=?",array($geomcommune,true));
        }
        if (isset($params['secteur']) && $params['secteur']!=''){
            $geomsecteur=self::getGeomSecteur($params['secteur']);
            $query->addWhere("st_intersects(?,zp.the_geom_local)=?",array($geomsecteur,true));
        }
        if (isset($params['id_organisme']) && $params['id_organisme']!='')
            $query->addWhere('zp.id_organisme= ?', $params['id_organisme']);
        if (isset($params['relecture']) && $params['relecture']!=null)
        {
            if($params['relecture']=='o'){$relecture = true;}
            if($params['relecture']=='n'){$relecture = false;}
            $query->addWhere('zp.validation= ?', $relecture);
        }
        if (isset($params['topologie']) && $params['topologie']!=null)
        {
            if($params['topologie']=='o'){$topologie = true;}
            if($params['topologie']=='n'){$topologie = false;}
            $query->addWhere('zp.topo_valid= ?', $topologie);
        }
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
	 * @param integer $indexzp
	 * @return TZprospection
	 */
	public static function get($indexzp)
	{
		return Doctrine::getTable('TZprospection')->find((int) $indexzp);
	}
    
    public static function search($params, $validOnly)
    {
        $zoom = $params['zoom'];
        $select = 'zp.indexzp, t.latin taxon_latin, zp.cd_nom, t.francais taxon_francais, zp.validation statut,'.
            'zp.dateobs,zp.date_insert, zp.date_update, zp.topo_valid topo,area(zp.the_geom_3857)';
        if($zoom<5){$query = mfQuery::create('geom_point_3857');}
        elseif($zoom<7 && $zoom>=5){$query = mfQuery::create('geom_mixte_3857');}
        else{$query = mfQuery::create('the_geom_3857');}
        $query 
          ->select($select)
          ->distinct()
          ->from('TZprospection zp')
          ->innerJoin('zp.BibTaxonsFp t')
          //->leftJoin('zp.TApresence ap')
          ->leftJoin('zp.CorZpObs o')
          ->where('zp.supprime=?', false);
        //on test si on est sur la recherche par défaut de la première page
        if ($params['start']=='no'){
            # Add search criterions
            self::addFilters($query, $params);
            if($validOnly){$query->addWhere('zp.validation is true');} 
            $query->orderBy('area(zp.the_geom_3857) DESC');
            $nbresult=count($query);
        }
        //si non on limite aux 50 dernières obs
        else{
            $query->orderBy('zp.dateobs DESC')
              ->limit(50);
            $nbresult=50;
        }
        // On met une limite pour éviter qu'il n'y ait trop de réponses à charger
        if($nbresult<=1000){
            $leszps = $query->fetchArray();
            // Clean up array structure
            $counterAp = self::getCounterAp();
            $counterObs = self::getCounterObservateurs();
            foreach ($leszps as $key => &$zp)
            {
              //$zp['taxon_latin'] = $zp['BibTaxonsFp']['latin'];
              //remise au format des dates
              $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
              preg_match($pattern, $zp['date_update'], $d);
              $zp['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
              preg_match($pattern, $zp['date_insert'], $d);
              $zp['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
              preg_match($pattern, $zp['dateobs'], $d);
              $zp['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
              $nb_ap = $counterAp->execute(array($zp['indexzp']), Doctrine::HYDRATE_ARRAY);
              $nb_obs = $counterObs->execute(array($zp['indexzp']), Doctrine::HYDRATE_ARRAY);
              $zp['nb_ap'] = $nb_ap[0]['nb'];
              $zp['nb_obs'] = $nb_obs[0]['nb'];
              $zp['validated'] = (!$zp['statut'])?false:true;
              $zp['notvalidated'] = (!$zp['statut'])?true:false;
              $zp['topovalidated'] = (!$zp['topo'])?false:true;
              $zp['toponotvalidated'] = (!$zp['topo'])?true:false;
              $zp['objets_a_compter']= self::listTaxonObjets($zp['cd_nom']);
              $zp['observateurs']= self::listObservateurs($zp['indexzp']);
              unset($zp['BibTaxonsFp'], $zp['TApresence']);
            }
            return $leszps;
        }
        else{
            return 'trop';
        }
    }
    
    public static function findOne($indexzp, $format = null)
    {
        $fields = 'zp.indexzp, zp.id_organisme, zp.cd_nom, zp.dateobs, zp.validation, zp.id_secteur_fp, zp.topo_valid,'.
                  ' t.latin taxon_latin, t.francais taxon_francais, sfp.nom_secteur_fp, zp.date_insert, zp.date_update,com.commune_min communezp,org.nom_organisme';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $zp = $query
              ->select($fields)
              ->from('TZprospection zp')
              ->leftJoin('zp.BibTaxonsFp t')
              ->leftJoin('zp.LSecteursFp sfp')
              ->leftJoin('zp.LCommunes com')
              ->leftJoin('zp.BibOrganismes org')
              ->where('indexzp=?', $indexzp)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($zp['indexzp']) && $zp['indexzp']=='')
          return false;

        // Format array
        $zp['ids_observateurs'] = self::listIdsObservateurs($indexzp);
        $zp['lesobservateurs'] = $zp['ids_observateurs'];//pour le chargement auto du combobox multiselect dans extjs
        $zp['communezp'] = $zp['LCommunes']['communezp'];
        $zp['nom_organisme'] = $zp['BibOrganismes']['nom_organisme'];
        unset($zp['BibTaxonsfp'], $zp['LSecteursFp'], $zp['LCommunes'], $zp['BibOrganismes']);
        //remise au format des dates
        $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
        preg_match($pattern, $zp['date_update'], $d);
        $zp['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $zp['date_insert'], $d);
        $zp['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        preg_match($pattern, $zp['dateobs'], $d);
        $zp['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        $zp['objets_a_compter']= self::listTaxonObjets($zp['cd_nom']);
        $zp['observateurs']= self::listObservateurs($indexzp);
        // la zp est tjs validable car la fonction isValidable a été modifiée pour tjs renvoyer true
        $zp['validable'] = true;
        $counterAp = self::getCounterAp();
        $nb_ap = $counterAp->execute(array($zp['indexzp']), Doctrine::HYDRATE_ARRAY);
        $zp['nb_ap'] = $nb_ap[0]['nb'];
        // sfLoader::loadHelpers('Url');
        $zp['URI'] = url_for('@homepage', true).'/pda?indexzp='.$zp['indexzp'];

        return $zp;
    }
}