<?php


class TApresenceTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TApresence');
    }
    public static function get($indexap)
	{
		return Doctrine::getTable('TApresence')->find((int) $indexap);
	}
    private static function getGeomCommuneCbna($insee)
    {
        $geom = Doctrine_Query::create()
          ->select('the_geom')
          ->from('LCommunesCbna')
          ->where('inseecom=?', $insee)
          ->fetchArray();
        return $geom[0]['the_geom'];
    }
    private static function getGeomSecteurCbna($id_secteur)
    {
        $geom = Doctrine_Query::create()
          ->select('the_geom')
          ->from('LSecteursCbna')
          ->where('id_secteur_cbna=?', $id_secteur)
          ->fetchArray();
        return $geom[0]['the_geom'];
    }
    private static function getGeomTerritoire($id_territoire)
    {
        $geom = Doctrine_Query::create()
          ->select('the_geom')
          ->from('LTerritoires')
          ->where('id_territoire=?', $id_territoire)
          ->fetchArray();
        return $geom[0]['the_geom'];
    }
    public static function getMaxIndexAp()
    {
        $ids= Doctrine_Query::create()
        ->select('max(indexap) as maxid' )
        ->from('TApresence')
        ->where('indexap < ?',1000000)
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
    private static function addwhere($request)
    {
        $addwhere = "";
        if ($request->getParameter('startdate')!='' && $request->getParameter('startdate')!=null && $request->getParameter('enddate')!='' && $request->getParameter('enddate')!=null){
            if($request->getParameter('typeperiode')=='sa'){
                $addwhere = $addWhere." and periode(zp.dateobs,to_date('".$request->getParameter('startdate')."','Dd Mon DD YYYY'),to_date('".$request->getParameter('enddate')."','Dd Mon DD YYYY'))=true";
            }
            if($request->getParameter('typeperiode')=='aa'){
                $addwhere = $addWhere." and zp.dateobs BETWEEN to_date('".$request->getParameter('startdate')."','Dd Mon DD YYYY') AND to_date('".$request->getParameter('enddate')."','Dd Mon DD YYYY')";
            }
        }
        if ($request->getParameter('annee')!=''&& $request->getParameter('annee')!=null){
            $addwhere = $addwhere." and DATE_PART('year' ,zp.dateobs)=".$request->getParameter('annee');
        }
        if ($request->getParameter('observateur')!=''&& $request->getParameter('observateur')!=null){
            $addwhere = $addwhere." and co.codeobs=".$request->getParameter('observateur');
        }
        //ici c'est un choix de l'utilisateur de filtrer par organisme
        if ($request->getParameter('organisme')!=''&& $request->getParameter('organisme')!=null){
            $addwhere = $addwhere." and zp.id_organisme=".$request->getParameter('organisme');
        }
        //ici c'est une contrainte de l'application qui limite l'export xls aux données de la personne loguée (sauf si elle est cbna)
        if ($request->getParameter('id_organisme')!=''&& $request->getParameter('id_organisme')!=null){
            if ($request->getParameter('id_organisme')!=1){
                $addwhere = $addwhere." and zp.id_organisme=".$request->getParameter('id_organisme');
            }
        }
        if ($request->getParameter('taxon')!=''&& $request->getParameter('taxon')!=null){
            $addwhere = $addwhere." and zp.cd_nom=".$request->getParameter('taxon');
        }
        if ($request->getParameter('secteur')!=''&& $request->getParameter('secteur')!=null){
            $addwhere = $addwhere." and zp.id_secteur_fp=".$request->getParameter('secteur');
        }
        if ($request->getParameter('topologie')!=''&& $request->getParameter('topologie')!=null){
            if($request->getParameter('topologie')=='o'){$topo = 'true';}
            if($request->getParameter('topologie')=='n'){$topo = 'false';}
            $addwhere = $addwhere." and zp.topo_valid=$topo";
        }
        if ($request->getParameter('relecture')!=''&& $request->getParameter('relecture')!=null){
            if($request->getParameter('relecture')=='o'){$r = 'true';}
            if($request->getParameter('relecture')=='n'){$r = 'false';}
            $addwhere = $addwhere." and zp.validation=$r";
        }
        if ($request->getParameter('commune')!=''&& $request->getParameter('commune')!=null){
            $geomcommune=self::getGeomCommuneCbna($request->getParameter('commune'));
            $addwhere = $addwhere." and st_intersects('$geomcommune',zp.the_geom_local)=true";
        }
        if ($request->getParameter('secteur')!=''&& $request->getParameter('secteur')!=null){
            $geomsecteur=self::getGeomSecteurCbna($request->getParameter('secteur'));
            $addwhere = $addwhere." and st_intersects('$geomsecteur',zp.the_geom_local)=true";
        }
        if ($request->getParameter('territoire')!=''&& $request->getParameter('territoire')!=null){
            $geomterritoire=self::getGeomTerritoire($request->getParameter('territoire'));
            $addwhere = $addwhere." and st_intersects('$geomterritoire',zp.the_geom_local)=true";
        }
        if ($request->getParameter('box')!=''&& $request->getParameter('box')!=null){
            $box=$request->getParameter('box');
            $bbox = explode(',',$box);
            $xmin = $bbox[0]; $ymin = $bbox[1]; $xmax = $bbox[2]; $ymax = $bbox[3];
            $addwhere = $addwhere." and ST_intersects(ST_setsrid(ST_Envelope('LINESTRING($xmin $ymin, $xmax $ymax)'::geometry),3857),zp.the_geom_3857) = true";
        }
        return $addwhere;
    }
    
    public static function listXls($request)
    {
        sfContext::getInstance()->getConfiguration()->loadHelpers('Date');
        $addwhere = self::addwhere($request);
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        if($request->getParameter('start')=="no"){$from = "  FROM florepatri.t_zprospection zp ";}
        else{$from = " FROM (SELECT * FROM florepatri.t_zprospection WHERE supprime = false ORDER BY dateobs DESC limit 50) zp ";}
        // print_r($request);
        $sql = "SELECT DISTINCT zp.indexzp, ap.indexap, s.nom_secteur_cbna AS secteur, org.nom_organisme AS organisme, zp.dateobs, t.latin AS taxon, o.observateurs, p.pheno AS phenologie, ap.frequenceap,
            ap.surfaceap, compt.nom_comptage_methodo, ob.denombrement, per.perturbations, phy.milieux, f.nom_frequence_methodo_new as frequence_methodo, ap.altitude_retenue AS altitude, ap.the_geom, ap.remarques,
            ap.topo_valid AS ap_topo_valid, zp.topo_valid AS zp_topo_valid, 
            ap.ap_pdop as pdop, zp.validation AS relue,comap.nomcom AS communeap, comzp.nomcom AS communezp, 
            CAST(st_x(layers.f_return_centroid(ap.the_geom_local)) AS int) AS x_local, CAST(st_y(layers.f_return_centroid(ap.the_geom_local)) AS int) AS y_local, 
            st_x(layers.f_return_centroid(st_transform(ap.the_geom_3857,4326))) AS x_wgs84, st_y(layers.f_return_centroid(st_transform(ap.the_geom_3857,4326))) AS y_wgs84"
            .$from.
            "LEFT JOIN florepatri.t_apresence ap ON ap.indexzp = zp.indexzp
            LEFT JOIN florepatri.cor_zp_obs co ON zp.indexzp = co.indexzp
            LEFT JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
            LEFT JOIN layers.l_secteurs_cbna s ON s.id_secteur_cbna = zp.id_secteur_fp
            LEFT JOIN layers.l_communes_cbna comap ON comap.inseecom = ap.insee
            LEFT JOIN layers.l_communes_cbna comzp ON comzp.inseecom = zp.insee
            LEFT JOIN florepatri.bib_phenologies p ON p.codepheno = ap.codepheno
            LEFT JOIN florepatri.bib_frequences_methodo_new f ON f.id_frequence_methodo_new = ap.id_frequence_methodo_new
            LEFT JOIN florepatri.bib_comptages_methodo compt ON compt.id_comptage_methodo = ap.id_comptage_methodo
            LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme = zp.id_organisme
            LEFT JOIN (
                select indexzp, array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') as observateurs from florepatri.cor_zp_obs c
                join utilisateurs.t_roles r ON r.id_role = c.codeobs
                GROUP BY indexzp
            ) o ON o.indexzp = zp.indexzp
            LEFT JOIN (
                select indexap, array_to_string(array_agg(c.nombre || ' ' || o.nomobjet), ', ') as denombrement from florepatri.cor_ap_objet c
                join florepatri.bib_objets o ON o.codeobjet = c.codeobjet
                GROUP BY indexap
            ) ob ON ob.indexap = ap.indexap
            LEFT JOIN (
                select indexap, array_to_string(array_agg(per.description || ' (' || per.classification || ')'), ', ') AS perturbations from florepatri.cor_ap_perturb c
                join florepatri.bib_perturbations per ON per.codeper = c.codeper
                GROUP BY indexap
            ) per ON per.indexap = ap.indexap
            LEFT JOIN ( SELECT c.indexap, array_to_string(array_agg((phy.groupe_physionomie::text || ' - '::text) || phy.nom_physionomie::text), ', '::text) AS milieux
               FROM florepatri.cor_ap_physionomie c
               JOIN florepatri.bib_physionomies phy ON phy.id_physionomie = c.id_physionomie
               GROUP BY c.indexap) phy ON phy.indexap = ap.indexap
            WHERE zp.supprime = false".$addwhere." ORDER BY s.nom_secteur_cbna, zp.indexzp";
            if($request->getParameter('usage')=="demo"){$sql .= " LIMIT 100 ";}
            $aps = $dbh->query($sql);
            // print_r($ap);
        return $aps;
    }
	
  /**
   * LIst of aps for passed zp
   *
   * @param integer $indexzp
   * @param array $filter
   * 
   * @return array
   */
  public static function listFor($indexzp, sfUser $user)
  {
  	sfContext::getInstance()->getConfiguration()->loadHelpers('Date');
  	//$filter = $user->getAttribute('categories');
    // Base query
    $query = mfQuery::create('the_geom_3857')
      ->select("ap.indexap,ap.codepheno,ap.indexzp,ap.surfaceap surface, ap.date_update, ap.date_insert,ap.ap_pdop pdop, ap.altitude_retenue altitude,ap.topo_valid, p.pheno phenologie,ap.remarques,".
        "  fm.nom_frequence_methodo_new frequencemethodo,ap.nb_transects_frequence,ap.nb_points_frequence,ap.nb_contacts_frequence,ap.frequenceap,".
        " ap.id_comptage_methodo,ap.nb_placettes_comptage,ap.surface_placette_comptage,cm.nom_comptage_methodo comptagemethodo,".
        " zp.dateobs, t.latin taxon")
      ->from('TApresence AS ap')
      ->leftJoin('ap.BibPhenologies p')
      ->leftJoin('ap.CorApObjet co')
      ->leftJoin('ap.CorApPerturb cp')
      ->leftJoin('ap.BibFrequencesMethodoNew fm')
      ->leftJoin('ap.BibComptagesMethodo cm')
      ->leftJoin('ap.TZprospection zp')
      ->leftJoin('zp.BibTaxonsFp t')
      ->where('ap.indexzp=?', $indexzp)
      ->addWhere('ap.supprime is not true')
      ->addWhere('ap.the_geom is not null');

    $aps = $query
      ->orderBy('area(the_geom) DESC')
      ->fetchArray();
    
    
    foreach ($aps as &$ap)
    {
    	// Clean up array structure
        $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
    	preg_match($pattern, $ap['date_update'], $d);
        $ap['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]); 
        preg_match($pattern, $ap['date_insert'], $d);
        $ap['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
        $ap['frequencemethodo'] = $ap['BibFrequencesMethodoNew']['frequencemethodo'];
        $ap['comptagemethodo'] = $ap['BibComptagesMethodo']['comptagemethodo'];        
        $indexap = $ap['indexap'];
        $ap['perturbations'] = self::listPerturbations($indexap);
        $ap['physionomies'] = self::listPhysionomies($indexap);
        $ap['objets'] = self::listObjets($indexap);
        $ap['observateurs'] = self::listObservateurs($ap['indexzp']);
        if ($ap['pdop']==-1){$ap['pdop'] = 'non précisé';}
        if ($ap['nb_transects_frequence']==0){$ap['nb_transects_frequence'] = null;}
        if ($ap['nb_points_frequence']==0){$ap['nb_points_frequence'] = null;}
        if ($ap['nb_contacts_frequence']==0){$ap['nb_contacts_frequence'] = null;}
        if ($ap['nb_placettes_comptage']==0){$ap['nb_placettes_comptage'] = null;}
        if ($ap['surface_placette_comptage']==0){$ap['surface_placette_comptage'] = null;}

      unset($ap['BibPhenologies'],$ap['CorApObjet'],$ap['CorApPerturb'],$ap['BibFrequencesMethodoNew'],$ap['TZprospection'],$ap['BibTaxonsFp'],$ap['BibComptagesMethodo']);
    }
    return $aps;
  }
  
    public static function findOne($indexap, $format = null)
    {
        sfContext::getInstance()->getConfiguration()->loadHelpers('Date');
        $fields = "ap.indexap, ap.codepheno, ap.indexzp, ap.surfaceap surface, ap.date_insert, ap.ap_pdop pdop, ap.altitude_retenue altitude,ap.topo_valid, p.pheno as pheno,ap.remarques,".
            " ap.date_update, ap.id_frequence_methodo_new,fm.nom_frequence_methodo_new frequencemethodo,ap.nb_transects_frequence,ap.nb_points_frequence,ap.nb_contacts_frequence,ap.frequenceap,".
            " ap.id_comptage_methodo,ap.nb_placettes_comptage,ap.surface_placette_comptage,cm.nom_comptage_methodo comptagemethodo,".
            " zp.dateobs, t.latin taxon, t.cd_nom";
        if ( !is_null($format) && $format==='geoJSON' ){
            $query = mfQuery::create('the_geom_3857');
                $query->select($fields);
            }
        else{
            $query = Doctrine_Query::create();
                $query->select($fields);
            }
                $ap = $query
                   // ->select($fields)
                    ->from('TApresence AS ap')
                    ->leftJoin('ap.BibPhenologies p')
                    ->leftJoin('ap.CorApObjet co')
                    ->leftJoin('ap.CorApPerturb cp')
                    ->leftJoin('ap.BibFrequencesMethodoNew fm')
                    ->leftJoin('ap.BibComptagesMethodo cm')
                    ->leftJoin('ap.TZprospection zp')
                    ->leftJoin('zp.BibTaxonsFp t')
                    ->where('ap.indexap=?', $indexap)
                    ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
            if (!isset($ap['indexap']) && $ap['indexap']==''){return false;}

            // Format array
            $ap['taxon'] = $ap['TZprospection']['BibTaxonsFp']['taxon'];
            $ap['cd_nom'] = $ap['TZprospection']['BibTaxonsFp']['cd_nom'];
            $ap['dateobs'] = $ap['TZprospection']['dateobs'];
            $ap['frequencemethodo'] = $ap['BibFrequencesMethodoNew']['frequencemethodo'];
            $ap['comptagemethodo'] = $ap['BibComptagesMethodo']['comptagemethodo'];
            //Clean up array structure
            unset($ap['BibTaxonsfp'],$ap['BibPhenologies'],$ap['BibFrequencesMethodoNew'],$ap['BibComptagesMethodo'],$ap['TZprospection']);
            //remise au format des dates
            $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
            preg_match($pattern, $ap['date_update'], $d);
            $ap['date_update'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]); 
            preg_match($pattern, $ap['date_insert'], $d);
            $ap['date_insert'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
            preg_match($pattern, $ap['dateobs'], $d);
            $ap['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);
            if ($ap['pdop']==-1){$ap['pdop'] = 'non précisé';}
            if ($ap['nb_transects_frequence']==0){$ap['nb_transects_frequence'] = null;}
            if ($ap['nb_points_frequence']==0){$ap['nb_points_frequence'] = null;}
            if ($ap['nb_contacts_frequence']==0){$ap['nb_contacts_frequence'] = null;}
            if ($ap['nb_placettes_comptage']==0){$ap['nb_placettes_comptage'] = null;}
            if ($ap['surface_placette_comptage']==0){$ap['surface_placette_comptage'] = null;}
            $ap['indexap']= $indexap;
            $ap['perturbations'] = self::arrayPerturbations($indexap);
            $ap['physionomies'] = self::arrayPhysionomies($indexap);
            $ap['objets'] = self::listObjets($indexap);
            $ap['observateurs'] = self::listObservateurs($ap['indexzp']);
            $ap['objets_a_compter']= self::listTaxonObjets($ap['cd_nom']);
            $obj = self::getObjets($indexap);
            $ap['effectif_placettes_comptage_fertile'] = $obj[0];
            $ap['nbfertile'] = $obj[1];
            $ap['effectif_placettes_comptage_sterile'] = $obj[2];
            $ap['nbsterile'] = $obj[3];
            $ap['codesper'] = array();
            foreach($ap['perturbations'] as $perturb)
            {
                array_push($ap['codesper'],$perturb['codeper']);
            }
            $ap['ids_physionomie'] = array();
            foreach($ap['physionomies'] as $physionomie)
            {
                array_push($ap['ids_physionomie'],$physionomie['id_physionomie']);
            }
            //$ap['codesper'] = self::getCodeper($indexap);
                //unset($ap['BibTaxonsfp'], $ap['BibPhenologies'], $ap['CorApObjet'], $ap['CorApPerturb'], $ap['BibFrequencesMethodo'], $ap['TZprospection']);
        return $ap;
    }
 /**
   * returns list of observateurs for passed ap
   *
   * @param integer $indexap
   * @return array
   */
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
  /**
   * returns list of perturbations for passed ap
   *
   * @param integer $indexap
   * @return array
   */
    private static function listPerturbations($indexap)
    {
        $perturbations = Doctrine_Query::create()
          ->select("p.codeper, concat(p.description, ' : ', lower(p.classification)) perturbation")
          ->distinct()
          ->from('BibPerturbations p')
          ->innerJoin('p.CorApPerturb cp')
          ->innerJoin('cp.TApresence ap')
          ->where('cp.indexap=?', $indexap)
          ->addWhere('ap.supprime is not true')
          ->fetchArray();
          $pers = array();
        foreach ($perturbations as &$perturbation)
        {
          $perturbation['perturbation'] = str_replace(array('[', ']'), array('(', ')'), $perturbation['perturbation']);
          $p = $perturbation['perturbation'];
          array_push($pers,$p);
        }
        return implode(', ',$pers);
    }
  /**
   * returns list of physionomies for passed ap
   *
   * @param integer $indexap
   * @return array
   */
    private static function listPhysionomies($indexap)
    {
        $physionomies = Doctrine_Query::create()
          ->select("p.id_physionomie, concat(p.nom_physionomie, ' : strate ', lower(p.groupe_physionomie)) physionomie")
          ->distinct()
          ->from('BibPhysionomies p')
          ->innerJoin('p.CorApPhysionomie cp')
          ->innerJoin('cp.TApresence ap')
          ->where('cp.indexap=?', $indexap)
          ->addWhere('ap.supprime is not true')
          ->fetchArray();
          $phys = array();
        foreach ($physionomies as &$physionomie)
        {
          $physionomie['physionomie'] = str_replace(array('[', ']'), array('(', ')'), $physionomie['physionomie']);
          $p = $physionomie['physionomie'];
          array_push($phys,$p);
        }
        return implode(', ',$phys);
    }
    
    private static function arrayPerturbations($indexap)
    {
        $perturbations = Doctrine_Query::create()
          ->select("p.codeper, concat(p.description, ' [', p.classification, ']') perturbation")
          ->distinct()
          ->from('BibPerturbations p')
          ->innerJoin('p.CorApPerturb cp')
          ->innerJoin('cp.TApresence ap')
          ->where('cp.indexap=?', $indexap)
          ->addWhere('ap.supprime is not true')
          ->fetchArray();
          $pers = array();
        foreach ($perturbations as &$perturbation)
        {
          $perturbation['perturbation'] = str_replace(array('[', ']'), array('(', ')'), $perturbation['perturbation']);
        }
        return $perturbations;
    }
    
    private static function arrayPhysionomies($indexap)
    {
        $physionomies = Doctrine_Query::create()
          ->select("p.id_physionomie, concat(p.nom_physionomie, ' [', p.groupe_physionomie, ']') physionomie")
          ->distinct()
          ->from('BibPhysionomies p')
          ->innerJoin('p.CorApPhysionomie cp')
          ->innerJoin('cp.TApresence ap')
          ->where('cp.indexap=?', $indexap)
          ->addWhere('ap.supprime is not true')
          ->fetchArray();
          $pers = array();
        foreach ($physionomies as &$physionomie)
        {
          $physionomie['physionomie'] = str_replace(array('[', ']'), array('(', ')'), $physionomie['physionomie']);
        }
        return $physionomies;
    }
   /**
   * returns list of objets for passed ap
   *
   * @param integer $indexap
   * @return array
   */ 
    private static function listObjets($indexap)
    {
        $objets = Doctrine_Query::create()
          ->select("o.id_objet_new, concat(co.nombre, ' ', o.nom_objet_new) objet")
          ->from('BibObjetsNew o')
          ->leftJoin('o.CorApObjet co')
          ->where('co.indexap=?', $indexap)
          ->fetchArray();
          $objs = array();
        foreach ($objets as &$objet)
        {
          $o = $objet['objet'];
          array_push($objs,$o);
        }
        return implode(', ',$objs);
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
    
    public static function getCodeper($indexap)
    {
        $perturbations = CorApPerturbTable::getPerturbationsAp($indexap);
        $codesper=array();
        if(count($perturbations)>0){;
            foreach ($perturbations as $perturbation)
            {
                array_push($codesper,$perturbation['codeper']);
            }
        }
        return $codesper;
    }
    
    public static function getObjets($indexap)
    {
        $objets = CorApObjetTable::getObjetsAp($indexap);
        $obj=array();
        $nbfertile = null;
        $nbsterile = null;
        $effplacettesfertile = null;
        $effplacettessterile = null;

        foreach ($objets as $objet)
        {
            if($objet['id_objet_new']=='EF'){
                $nbfertile = $objet['nombre'];
                $effplacettesfertile = $objet['effectif_placettes_comptage'];
            }
            if($objet['id_objet_new']=='ES'){
                $nbsterile = $objet['nombre'];
                $effplacettessterile = $objet['effectif_placettes_comptage'];   
            }
        }
        array_push($obj,$effplacettesfertile,$nbfertile,$effplacettessterile,$nbsterile);
        return $obj;
        //return $this->renderText("{success: true, typesterile:".$typesterile.", nbsterile:".$nbsterile.", typefertile:".$typefertile.", nbfertile:".$nbfertile."}");
    }
}