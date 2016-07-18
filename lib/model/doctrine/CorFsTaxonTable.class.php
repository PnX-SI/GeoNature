<?php


class CorFsTaxonTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('CorFsTaxon');
    }
    public static function listTaxons($id_station, sfUser $user)
   {
  	//$filter = $user->getAttribute('categories');
    // Base query
    $taxons = mfQuery::create('the_geom_3857')
    // $taxons = Doctrine_Query::create()
      ->select("cft.id_station,cft.cd_nom, cft.herb, cft.inf_1m, cft.de_1_4m, cft.sup_4m, cft.taxon_saisi,".
        "t.nom_complet, t.nom_vern,t.cd_ref,".
        "a.nom_abondance abond_herb, b.nom_abondance abond_inf1m, c.nom_abondance abond_1_4m, d.nom_abondance abond_sup4m")
      ->from('Taxref t')
      ->innerJoin('t.CorFsTaxon cft')
      ->innerJoin('cft.TStationsFs s')
      ->leftJoin('cft.BibAbondancesHerb a')
      ->leftJoin('cft.BibAbondancesInf1m b')
      ->leftJoin('cft.BibAbondancesDe14m c')
      ->leftJoin('cft.BibAbondancesSup4m d')
      ->where('cft.id_station=?', $id_station)
      ->addWhere('cft.supprime=?', false)
      ->addWhere('s.the_geom_3857 is not null')
      ->fetchArray();
    // Clean up array structure
    foreach ($taxons as &$taxon)
    {
        $taxon['url_texte'] = $taxon['CorProtectionEspecesTaxref']['TReglementationTaxref']['url'];
        // $taxon['url_inpn'] = htmlentities('<a href="http://inpn.mnhn.fr/isb/espece/cd_nom/'.$taxon['CorFsTaxon']['cd_nom'].'">'.$taxon['nom_complet'].'</a>');
        $taxon['protections'] = self::listReglementations($taxon['cd_ref']);
        if(count($taxon['protections'])==0){$taxon['no_protection']=true;$taxon['protection']='non';}else{$taxon['no_protection']=false;$taxon['protection']='oui';}
        $references = self::listReferences($taxon['cd_ref']);
        foreach ($references as $r)
        {
          $taxon['nom_valide']=$r['nom_valide'];
          $taxon['nom_valide_complet']=$r['nom_complet'];
          $taxon['famille']=$r['famille'];
        }
        $taxon['id_station'] = $taxon['CorFsTaxon'][0]['id_station'];
        $taxon['cd_nom'] = $taxon["CorFsTaxon"][0]["cd_nom"];        
        $taxon['herb'] = $taxon['CorFsTaxon'][0]['herb'];
        $taxon['inf_1m'] = $taxon['CorFsTaxon'][0]['inf_1m'];
        $taxon['de_1_4m'] = $taxon['CorFsTaxon'][0]['de_1_4m'];
        $taxon['sup_4m'] = $taxon['CorFsTaxon'][0]['sup_4m'];
        $taxon['taxon_saisi'] = $taxon['CorFsTaxon'][0]['taxon_saisi'];
        $taxon['abond_herb'] = $taxon['CorFsTaxon'][0]['BibAbondancesHerb']['abond_herb'];
        $taxon['abond_inf1m'] = $taxon['CorFsTaxon'][0]['BibAbondancesInf1m']['abond_inf1m'];
        $taxon['abond_1_4m'] = $taxon['CorFsTaxon'][0]['BibAbondancesDe14m']['abond_1_4m'];
        $taxon['abond_sup4m'] = $taxon['CorFsTaxon'][0]['BibAbondancesSup4m']['abond_sup4m'];
        // $cd_nom = $taxon['cd_nom'];
        // $taxon['perturbations'] = self::listPerturbations($indextaxon);
      unset($taxon['CorFsTaxon'],$taxon['BibAbondancesHerb'],$taxon['BibAbondancesInf1m'],$taxon['BibAbondancesDe14m'],$taxon['BibAbondancesSup4m'],$taxon['TStationsFs']);
    }  
    return $taxons;
  }
  
    public static function listOneReleveTaxons($id_station){
    // Base query
    $taxons = Doctrine_Query::create()
      ->select("cft.id_station,t.cd_nom, cft.herb, cft.inf_1m, cft.de_1_4m, cft.sup_4m,cft.taxon_saisi,".
        "t.nom_complet,a.nom_abondance abond_herb, b.nom_abondance abond_inf1m, c.nom_abondance abond_1_4m, d.nom_abondance abond_sup4m")
      ->from('Taxref t')
      ->innerJoin('t.CorFsTaxon cft')
      ->leftJoin('cft.BibAbondancesHerb a')
      ->leftJoin('cft.BibAbondancesInf1m b')
      ->leftJoin('cft.BibAbondancesDe14m c')
      ->leftJoin('cft.BibAbondancesSup4m d')
      ->where('cft.id_station=?', $id_station)
      ->addWhere('cft.supprime=?', false)
      ->fetchArray();
    // Clean up array structure
    foreach ($taxons as &$taxon)
    {
        // $taxon['cd_nom'] = $taxon['CorFsTaxon']['cd_nom'];
        $taxon['herb'] = $taxon['CorFsTaxon'][0]['herb'];
        $taxon['inf_1m'] = $taxon['CorFsTaxon'][0]['inf_1m'];
        $taxon['de_1_4m'] = $taxon['CorFsTaxon'][0]['de_1_4m'];
        $taxon['sup_4m'] = $taxon['CorFsTaxon'][0]['sup_4m'];
        $taxon['taxon_saisi'] = $taxon['CorFsTaxon'][0]['taxon_saisi'];
        $taxon['abond_herb'] = $taxon['CorFsTaxon'][0]['BibAbondancesHerb']['abond_herb'];
        $taxon['abond_inf1m'] = $taxon['CorFsTaxon'][0]['BibAbondancesInf1m']['abond_inf1m'];
        $taxon['abond_1_4m'] = $taxon['CorFsTaxon'][0]['BibAbondancesDe14m']['abond_1_4m'];
        $taxon['abond_sup4m'] = $taxon['CorFsTaxon'][0]['BibAbondancesSup4m']['abond_sup4m'];
      unset($taxon['CorFsTaxon'],$taxon['BibAbondancesHerb'],$taxon['BibAbondancesInf1m'],$taxon['BibAbondancesDe14m'],$taxon['BibAbondancesSup4m']);
    }  
    return $taxons;
  }
  
  private static function listReferences($cd_ref)
    {
        $query = Doctrine_Query::create()
          ->select("t.cd_nom,t.nom_complet,t.famille")
          ->distinct()
          ->from('Taxref t')
          ->where('t.cd_nom=?', $cd_ref)
          ->fetchArray();
        return $query;
    }
  
  private static function listReglementations($cd_ref)
    {
        $reglements = Doctrine_Query::create()
          ->select("r.cd_protection,r.url, concat(r.intitule, ' ', r.article) protections")
          ->distinct()
          ->from('TaxrefProtectionArticles r')
          ->innerJoin('r.TaxrefProtectionEspeces cpet')
          ->where('cpet.cd_nom=?', $cd_ref)
          ->addWhere('r.concerne_mon_territoire=?', true)
          ->fetchArray();
          $reglementations = array();
          foreach ($reglements as $r)
        {
          $couple = array();
          $couple['texte']=$r['protections'];
          $couple['url']=$r['url'];
          array_push($reglementations,$couple);
        }
        return $reglementations;
    }
    
  private static function listUrlReglementations($cd_ref)
    {
        $reglements = Doctrine_Query::create()
          ->select("r.cd_protection, concat(r.intitule, ' ', r.article) protections")
          ->distinct()
          ->from('TaxrefProtectionArticles r')
          ->innerJoin('r.TaxrefProtectionEspeces cpet')
          ->where('cpet.cd_nom=?', $cd_ref)
          ->addWhere('r.concerne_mon_territoire=?', true)
          // ->orWhereIn('r.cd_protection',array('RV93','DV05','DV38'))
          ->fetchArray();
          $reglementations = array();
        foreach ($reglements as $r)
        {
          $a = $r['protections'];
          array_push($reglementations,$a);
        }
        return implode(' --- ',$reglementations);

    }
    
    private static function addwhere($request)
    {
        $addwhere = "";
        if ($request->getParameter('startdate')!='' && $request->getParameter('startdate')!=null && $request->getParameter('enddate')!='' && $request->getParameter('enddate')!=null){
            if($request->getParameter('typeperiode')=='sa'){
                $addwhere .= " and periode(s.dateobs,to_date('".$request->getParameter('startdate')."','Dd Mon DD YYYY'),to_date('".$request->getParameter('enddate')."','Dd Mon DD YYYY'))=true";
            }
            if($request->getParameter('typeperiode')=='aa'){
                $addwhere .= " and s.dateobs BETWEEN to_date('".$request->getParameter('startdate')."','Dd Mon DD YYYY') AND to_date('".$request->getParameter('enddate')."','Dd Mon DD YYYY')";
            }
        }
        if ($request->getParameter('annee')!=''&& $request->getParameter('annee')!=null){
            $addwhere .= " and DATE_PART('year' ,s.dateobs)=".$request->getParameter('annee');
        }
        if ($request->getParameter['relecture']!='' && $request->getParameter['relecture']!=null){
            if($request->getParameter['relecture']=='o'){$addwhere .= " and s.validation='t'";}
            if($request->getParameter['relecture']=='n'){$addwhere .= " and s.validation='f'";}
        } 
        if ($request->getParameter('observateur')!=''&& $request->getParameter('observateur')!=null){
            $addwhere .= " and cfo.id_role=".$request->getParameter('observateur');
        }
        if ($request->getParameter('releve')!=''&& $request->getParameter('releve')!=null){
            $addwhere .= " and s.complet_partiel='".$request->getParameter('releve')."'";
        }
        if ($request->getParameter('programme')!=''&& $request->getParameter('programme')!=null){
            $addwhere .= " and s.id_programme_fs=".$request->getParameter('programme');
        }
        if ($request->getParameter('exposition')!=''&& $request->getParameter('exposition')!=null){
            $addwhere .= " and s.id_exposition='".$request->getParameter('exposition')."'";
        }
        if ($request->getParameter('sophie')!=''&& $request->getParameter('sophie')!=null){
            $addwhere .= " and s.id_sophie='".$request->getParameter('sophie')."'";
        }
        if ($request->getParameter('surface')!=''&& $request->getParameter('surface')!=null){
            $addwhere .= " and s.id_surface=".$request->getParameter('surface');
        }
        if ($request->getParameter('rtaxon')!=''&& $request->getParameter('rtaxon')!=null){
            $addwhere .= " AND s.id_station IN (select distinct s.id_station FROM florestation.t_stations_fs s
                                  LEFT JOIN florestation.cor_fs_taxon cft ON cft.id_station = s.id_station 
                                  LEFT JOIN taxonomie.taxref t ON t.cd_nom = cft.cd_nom 
                                  WHERE t.cd_ref =" .$request->getParameter('rtaxon').")";
        }
        if ($request->getParameter('otaxon')!=''&& $request->getParameter('otaxon')!=null){
            $addwhere .= " AND s.id_station IN (select distinct s.id_station FROM florestation.t_stations_fs s
                                  LEFT JOIN florestation.cor_fs_taxon cft ON cft.id_station = s.id_station 
                                  LEFT JOIN taxonomie.taxref t ON t.cd_nom = cft.cd_nom 
                                  WHERE t.cd_nom =" .$request->getParameter('otaxon').")";
        }
        // if ($request->getParameter('topologie')!=''&& $request->getParameter('topologie')!=null){
            // if($request->getParameter('topologie')=='o'){$topo = 'true';}
            // if($request->getParameter('topologie')=='n'){$topo = 'false';}
            // $addwhere = $addwhere." and s.topo_valid=$topo";
        // }
        if ($request->getParameter('commune')!=''&& $request->getParameter('commune')!=null){
            $addwhere .= " and s.insee='".$request->getParameter('commune')."'";
        }
        if ($request->getParameter('secteur')!=''&& $request->getParameter('secteur')!=null){
            $addwhere .= " and com.id_secteur=".$request->getParameter('secteur');
        }
        if ($request->getParameter('box')!=''&& $request->getParameter('box')!=null){
            $box=$request->getParameter('box');
            $bbox = explode(',',$box);
            $xmin = $bbox[0]; $ymin = $bbox[1]; $xmax = $bbox[2]; $ymax = $bbox[3];
            $addwhere .= " and ST_intersects(ST_setsrid(ST_Envelope('LINESTRING($xmin $ymin, $xmax $ymax)'::geometry),3857),s.the_geom_3857) = true";
        }
        return $addwhere;
    }
    
    public static function listXls($request)
    {
        sfContext::getInstance()->getConfiguration()->loadHelpers('Date');
        $srid_local_export = sfGeonatureConfig::$srid_local;
        $addwhere = self::addwhere($request);
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        if($request->getParameter('start')=="no"){$from = "  FROM florestation.t_stations_fs s ";}
        else{$from = " FROM (SELECT * FROM florestation.t_stations_fs WHERE supprime = false ORDER BY dateobs DESC limit 50) s ";}
        $sql = "SELECT DISTINCT s.id_station, s.id_sophie, s.dateobs, s.info_acces, s.complet_partiel, s.meso_longitudinal, s.meso_lateral, 
            s.canopee,s.ligneux_hauts,s.ligneux_bas,s.ligneux_tbas,s.herbaces,s.mousses,s.litiere,s.remarques,
            s.altitude_retenue AS altitude, s.the_geom_3857, s.pdop as pdop, s.validation AS relue,
            t.nom_complet AS taxon, o.observateurs, p.nom_programme_fs, mr.microreliefs, d.delphines,
            e.nom_exposition, su.nom_support, h.nom_homogene, g.nom_surface,com.commune_min as nomcommune, se.nom_secteur,
            cft.herb,cft.inf_1m,cft.de_1_4m,cft.sup_4m,cft.taxon_saisi, z.nom_complet AS taxon_ref, z.nom_complet AS taxon_complet,
            st_x(s.the_geom_".$srid_local_export.") as x_local, st_y(s.the_geom_".$srid_local_export.") as y_local"
            .$from.
            "LEFT JOIN florestation.cor_fs_taxon cft ON cft.id_station = s.id_station
            LEFT JOIN taxonomie.taxref t ON t.cd_nom = cft.cd_nom
            LEFT JOIN (SELECT cd_nom, nom_complet FROM taxonomie.taxref WHERE cd_nom IN (SELECT DISTINCT t.cd_ref FROM taxonomie.taxref t JOIN florestation.cor_fs_taxon c ON c.cd_nom = t.cd_nom)) z ON z.cd_nom = t.cd_ref
            LEFT JOIN florestation.cor_fs_observateur cfo ON s.id_station = cfo.id_station
            LEFT JOIN florestation.bib_programmes_fs p ON p.id_programme_fs = s.id_programme_fs
            LEFT JOIN florestation.bib_expositions e ON e.id_exposition = s.id_exposition
            LEFT JOIN meta.bib_supports su ON su.id_support = s.id_support
            LEFT JOIN florestation.bib_homogenes h ON h.id_homogene = s.id_homogene
            LEFT JOIN florestation.bib_surfaces g ON g.id_surface = s.id_surface
            LEFT JOIN layers.l_communes com ON com.insee = s.insee
            LEFT JOIN layers.l_secteurs se ON se.id_secteur = com.id_secteur
            LEFT JOIN (
                select id_station, array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') as observateurs from florestation.cor_fs_observateur c
                join utilisateurs.t_roles r ON r.id_role = c.id_role
                group by id_station
            ) o ON o.id_station = s.id_station
            LEFT JOIN (
                select id_station, array_to_string(array_agg(c.id_microrelief || ' ' || m.nom_microrelief), ', ') as microreliefs from florestation.cor_fs_microrelief c
                join florestation.bib_microreliefs m ON m.id_microrelief = c.id_microrelief
                group by id_station
            ) mr ON mr.id_station = s.id_station
            LEFT JOIN (
                select id_station, array_to_string(array_agg(c.id_delphine), ', ') as delphines from florestation.cor_fs_delphine c
                group by id_station
            ) d ON d.id_station = s.id_station
            WHERE s.supprime = false AND cft.supprime=false".$addwhere." ORDER BY s.dateobs DESC";
            if($request->getParameter('usage')=="demo"){$sql .= " LIMIT 100 ";}
        $aps = $dbh->query($sql);
        return $aps;
    }
}