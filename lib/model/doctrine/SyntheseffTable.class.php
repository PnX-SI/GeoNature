<?php


class SyntheseffTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('Syntheseff');
    }
    public static function listAnnees()
    {
        $annees = Doctrine_Query::create()
          ->select ("DATE_PART('year' ,dateobs) annee")
          ->distinct()
          ->from('Syntheseff')
          //->groupBy('annee')
          ->fetchArray();
        return $annees;
    }
    private static function listReglementations($cd_nom)
    {
        $reglements = Doctrine_Query::create()
          ->select("r.cd_protection,r.url, concat(r.intitule, ' ', r.article, ' - ', r.type_protection) protections")
          ->distinct()
          ->from('TaxrefProtectionArticles r')
          ->innerJoin('r.TaxrefProtectionEspeces tpe')
          ->where('tpe.cd_nom=?', $cd_nom)
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
    private static function listReferences($cd_ref)
    {
        $query = Doctrine_Query::create()
          ->select("t.cd_nom,t.nom_valide,t.famille,t.ordre,t.classe")
          ->distinct()
          ->from('Taxref t')
          ->where('t.cd_nom=?', $cd_ref)
          ->fetchArray();
        return $query;
    }
    
    public static function get($id_cf)
	{
		return Doctrine::getTable('TFichesCf')->find((int) $id_cf);
	}
    private static function addFilters($params)
    {
        $sql = '';
        if (isset($params['fff']) && $params['fff']!='' && $params['fff']!=null && $params['fff']!='all')
            $sql .= " AND txr.regne = '".$params['fff']."'";
        if (isset($params['id_secteur']) && $params['id_secteur']!='')
            $sql .= " AND com.id_secteur = ".$params['id_secteur'];
        if (isset($params['id_n2000']) && $params['id_n2000']!='')
            $sql .= " AND z.id_zone = ".$params['id_n2000']; 
        if (isset($params['id_reserve']) && $params['id_reserve']!='')
            $sql .= " AND z.id_zone = ".$params['id_reserve'];
        if ((isset($params['patrimonial']) && $params['patrimonial']!='') || (isset($params['protection_stricte']) && $params['protection_stricte']!='')) {
            if (($params['patrimonial']=='true') || ($params['protection_stricte']=='true')){
                $sql .= " AND (";
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']!='true')){$sql .= "t.filtre2 = 'oui'";}
                    if(($params['patrimonial']!='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre3 = 'oui'";}
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre2 = 'oui' OR t.filtre3 = 'oui'";}
                $sql .= ")";
            }
        }
        if (isset($params['programmes']) && $params['programmes']!='')
            $sql .= " AND p.id_programme IN(".$params['programmes'].")";
            return $sql;
    }
    private static function addTSyntheseFilters($params)
    {
        //on doit gérer la valeur du emptyText d'extjs qui est transmise pour les champs autre que combobox
        if($params['observateur']=='Observateur'){$params['observateur']=null;}
        if($params['datedebut']=='Date début'){$params['datedebut']=null;}
        if($params['periodedebut']=='Période début'){$params['periodedebut']=null;}
        if($params['datefin']=='Date fin'){$params['datefin']=null;}
        if($params['periodefin']=='Période fin'){$params['periodefin']=null;}
        $sql = '';
        if (isset($params['searchgeom']) && $params['searchgeom']!='')
            $sql .= " AND ST_intersects(synt.the_geom_3857,ST_GeomFromText('".$params['searchgeom']."', 3857))";
        if (isset($params['observateur']) && $params['observateur']!='')
            $sql .= " AND synt.observateurs ILIKE '%".$params['observateur']."%'";
        if (isset($params['taxonfr']) && $params['taxonfr']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonfr'];
        if (isset($params['taxonl']) && $params['taxonl']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonl'];
        if (isset($params['idstaxons']) && $params['idstaxons']!='')
            $sql .= " AND synt.cd_nom IN (".$params['idstaxons'].")";
        if (isset($params['insee']) && $params['insee']!='')
            $sql .= " AND synt.insee = '".$params['insee']."'";
        if (isset($params['id_organisme']) && $params['id_organisme']!='')
            $sql .= " AND synt.id_organisme = ".$params['id_organisme'];            
        if (isset($params['datedebut']) && $params['datedebut']!=null && isset($params['datefin']) && $params['datefin']!=null)
            $sql .= " AND synt.dateobs BETWEEN to_date('".$params['datedebut']."','DD MM YYYY') AND to_date('".$params['datefin']."','DD MM YYYY')";
        if (isset($params['periodedebut']) && $params['periodedebut']!=null && $params['periodedebut']!='Période début' && isset($params['periodefin']) && $params['periodefin']!=null && $params['periodefin']!='Période fin')   
            $sql .= " AND periode(synt.dateobs,to_date('".$params['periodedebut']."','DD MM'),to_date('".$params['periodefin']."','DD MM'))=true ";
        return $sql;
    } 
    private static function addPreFilters($params)
    {
        //on doit gérer la valeur du emptyText d'extjs qui est transmise pour les champs autre que combobox
        if($params['observateur']=='Observateur'){$params['observateur']=null;}
        if($params['datedebut']=='Date début'){$params['datedebut']=null;}
        if($params['periodedebut']=='Période début'){$params['periodedebut']=null;}
        if($params['datefin']=='Date fin'){$params['datefin']=null;}
        if($params['periodefin']=='Période fin'){$params['periodefin']=null;}
        $sql = '';
        if (isset($params['searchgeom']) && $params['searchgeom']!='')
            $sql .= " AND ST_intersects(synt.the_geom_3857,ST_GeomFromText('".$params['searchgeom']."', 3857))";
        if (isset($params['id_n2000']) && $params['id_n2000']!='')
            $sql .= " AND z.id_zone = ".$params['id_n2000']; 
        if (isset($params['id_reserve']) && $params['id_reserve']!='')
            $sql .= " AND z.id_zone = ".$params['id_reserve'];
        if (isset($params['observateur']) && $params['observateur']!='')
            $sql .= " AND synt.observateurs ILIKE '%".$params['observateur']."%'";
        if (isset($params['fff']) && $params['fff']!='' && $params['fff']!=null && $params['fff']!='all')
            $sql .= " AND txr.regne = '".$params['fff']."'";
        if (isset($params['taxonfr']) && $params['taxonfr']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonfr'];
        if (isset($params['taxonl']) && $params['taxonl']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonl'];
        if (isset($params['idstaxons']) && $params['idstaxons']!='')
            $sql .= " AND synt.cd_nom IN (".$params['idstaxons'].")";
        if ((isset($params['patrimonial']) && $params['patrimonial']!='') || (isset($params['protection_stricte']) && $params['protection_stricte']!='')) {
            if (($params['patrimonial']=='true') || ($params['protection_stricte']=='true')){
                $sql .= " AND (";
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']!='true')){$sql .= "t.filtre2 = 'oui'";}
                    if(($params['patrimonial']!='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre3 = 'oui'";}
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre2 = 'oui' OR t.filtre3 = 'oui'";}
                $sql .= ")";
            }
        }   
        if (isset($params['id_secteur']) && $params['id_secteur']!='')
            $sql .= " AND com.id_secteur = ".$params['id_secteur'];
        if (isset($params['insee']) && $params['insee']!='')
            $sql .= " AND synt.insee = '".$params['insee']."'";
        if (isset($params['programmes']) && $params['programmes']!='')
            $sql .= " AND p.id_programme IN(".$params['programmes'].")";
        if (isset($params['id_organisme']) && $params['id_organisme']!='')
            $sql .= " AND synt.id_organisme = ".$params['id_organisme'];            
        if (isset($params['datedebut']) && $params['datedebut']!=null && isset($params['datefin']) && $params['datefin']!=null)
            $sql .= " AND synt.dateobs BETWEEN to_date('".$params['datedebut']."','DD MM YYYY') AND to_date('".$params['datefin']."','DD MM YYYY')";
        if (isset($params['periodedebut']) && $params['periodedebut']!=null && $params['periodedebut']!='Période début' && isset($params['periodefin']) && $params['periodefin']!=null && $params['periodefin']!='Période fin')   
            $sql .= " AND periode(synt.dateobs,to_date('".$params['periodedebut']."','DD MM'),to_date('".$params['periodefin']."','DD MM'))=true ";
        return $sql;
    }
    public static function preSearch($params)
    {
        //si on n'est pas sur la recherche par défaut de la première page, on test le nb de résultats
        if ($params['start']=='no'){
            $addprefilters = self::addPreFilters($params);
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "
                SELECT count(*) AS nb
                FROM synthese.syntheseff synt
                LEFT JOIN taxonomie.taxref txr ON txr.cd_nom = synt.cd_nom 
                LEFT JOIN taxonomie.bib_taxons t ON t.cd_nom = synt.cd_nom
                LEFT JOIN layers.l_communes com ON com.insee = synt.insee
                LEFT JOIN meta.bib_lots l ON l.id_lot = synt.id_lot
                JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
                LEFT JOIN synthese.cor_zonesstatut_synthese z ON z.id_synthese = synt.id_synthese 
                WHERE synt.supprime = false ".$addprefilters;
            $nb = $dbh->query($sql)->fetchAll();
            $nb_res = $nb[0]['nb'];
            return $nb_res;
        }
        //sinon on est sur la première page, on retourne 50 qui le nombre de résultats que l'on va rechercher
        else{return 50;}
    }
    public static function search($params,$nb_res,$userNom,$userPrenom,$statuscode)
    { 
        // On met une limite pour éviter qu'il n'y ait trop de réponses à charger
        if($nb_res<10000){
            $zoom = $params['zoom'];
            if($zoom<12){$geom = 'synt.the_geom_point';}
            else{$geom = 'synt.the_geom_3857';}
            if($params['start']=="no"){
                $addfilters = self::addFilters($params);
                $addTSyntheseFilters = self::addTSyntheseFilters($params);
                $from = " FROM (SELECT * FROM synthese.syntheseff synt WHERE supprime = false ".$addTSyntheseFilters.") synt "; 
            }
            else{
                $from = " FROM (SELECT * FROM synthese.syntheseff WHERE supprime = false ORDER BY dateobs DESC limit 50) synt ";
                $addfilters = '';
            }
            $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
            $sql = "
                SELECT DISTINCT synt.id_synthese, synt.id_source, synt.id_fiche_source, synt.code_fiche_source, synt.id_organisme, id_protocole, synt.id_lot, l.nom_lot, p.nom_programme,
                    synt.insee, synt.dateobs, synt.observateurs, synt.altitude_retenue AS altitude, synt.remarques, synt.cd_nom, synt.effectif_total,
                    txr.lb_nom AS taxon_latin, 
                    CASE
                        WHEN t.nom_francais is null THEN txr.lb_nom
                        WHEN t.nom_francais = '' THEN txr.lb_nom
                        ELSE t.nom_francais
                    END AS taxon_francais,
                    CASE 	
                        WHEN t.filtre2 = 'oui'  THEN true
                        WHEN t.filtre2 = 'non'  THEN false
                        ELSE null
                    END AS patrimonial,
                    CASE 	
                        WHEN t.filtre3 = 'oui'  THEN true
                        WHEN t.filtre3 = 'non'  THEN false
                        ELSE null
                    END AS protection_stricte,
                    txr.cd_ref,
                    com.commune_min AS nomcommune, cri.nom_critere_synthese,
                    ST_ASGEOJSON($geom, 0) AS g"
                .$from.
                "LEFT JOIN taxonomie.bib_taxons t ON t.cd_nom = synt.cd_nom
                LEFT JOIN synthese.bib_criteres_synthese cri ON cri.id_critere_synthese = synt.id_critere_synthese
                LEFT JOIN taxonomie.taxref txr ON txr.cd_nom = synt.cd_nom
                LEFT JOIN layers.l_communes com ON com.insee = synt.insee
                LEFT JOIN meta.bib_lots l ON l.id_lot = synt.id_lot
                JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
                LEFT JOIN synthese.cor_zonesstatut_synthese z ON z.id_synthese = synt.id_synthese 
                WHERE synt.supprime = false ".$addfilters."ORDER BY synt.dateobs DESC";
            
            $lesobs = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
            $geojson = '{"type":"FeatureCollection","features":[';
            // Clean up and complete array structure
            $compt = 0;
            foreach ($lesobs as $key => &$obs)
            {
                $geometry = $obs['g'];
                $obs['patrimonial'] = ($obs['patrimonial']=='t')?true:false;
                $obs['no_patrimonial'] = ($obs['patrimonial']=='t')?false:true;
                $obs['protection_stricte'] = ($obs['protection_stricte']=='t')?true:false;
                $obs['no_protection'] = ($obs['protection_stricte']=='t')?false:true;
                $obs['taxon_francais'] = ($obs['taxon_francais'] == '' || $obs['taxon_francais'] == null )?$obs['taxon_latin']:$obs['taxon_francais'];
               //pour l'affichage ou non du bouton edit; 
               if   (
                        (preg_match("/".$userNom."/i", $obs['observateurs']) 
                            && preg_match("/".$userPrenom."/i", $obs['observateurs'])
                            &&(
                                $obs['id_source']==sfGeonatureConfig::$id_source_cf 
                                || $obs['id_source']==sfGeonatureConfig::$id_source_mortalite 
                                || $obs['id_source']==sfGeonatureConfig::$id_source_inv
                            )
                        )
                        ||
                        ($statuscode==6 
                            && (
                                $obs['id_source']==sfGeonatureConfig::$id_source_cf
                                || $obs['id_source']==sfGeonatureConfig::$id_source_mortalite
                                || $obs['id_source']==sfGeonatureConfig::$id_source_inv
                            )
                        )
                    ) {$obs['edit_ok']='true';}
                else{$obs['edit_ok']='false';}
                if($compt>0){$geojson .= ',';}
                $geojson .= '{"type":"Feature","id":'.$obs['id_synthese'].',"properties":';
                $geojson .= json_encode($lesobs[$compt]);
                $geojson .= ',"geometry":'.$geometry;
                $geojson .= '}';
                unset($lesobs[$compt]);
                $compt = $compt+1; 
            }
            $geojson .= ']}';
            return $geojson;
        }
        else{
            return 'trop';
        }
    }
    private static function addwhere($params)
    {
        //on doit gérer la valeur du emptyText d'extjs qui est transmise pour les champs autre que combobox
        if($params['observateur']=='Observateur'){$params['observateur']=null;}
        if($params['datedebut']=='Date début'){$params['datedebut']=null;}
        if($params['periodedebut']=='Période début'){$params['periodedebut']=null;}
        if($params['datefin']=='Date fin'){$params['datefin']=null;}
        if($params['periodefin']=='Période fin'){$params['periodefin']=null;}
        $sql = '';
        if (isset($params['searchgeom']) && $params['searchgeom']!='')
            $sql .= " AND ST_intersects(synt.the_geom_3857,ST_GeomFromText('".$params['searchgeom']."', 3857))";
        if (isset($params['id_n2000']) && $params['id_n2000']!='')
            $sql .= " AND z.id_zone = ".$params['id_n2000']; 
        if (isset($params['id_reserve']) && $params['id_reserve']!='')
            $sql .= " AND z.id_zone = ".$params['id_reserve'];
        if (isset($params['observateur']) && $params['observateur']!='')
            $sql .= " AND synt.observateurs ILIKE '%".$params['observateur']."%'";
        if (isset($params['id_unite']) && $params['id_unite']!='' && $params['id_unite']==sfGeonatureConfig::$id_unite_fournisseur && isset($params['userName']) && $params['userName']!='' ){
            $sql .= " AND lower(synt.observateurs) ILIKE lower('%".$params['userName']."%')";
        }
        if (isset($params['fff']) && $params['fff']!='' && $params['fff']!=null && $params['fff']!='all')
            $sql .= " AND txr.regne = '".$params['fff']."'";
        if (isset($params['taxonfr']) && $params['taxonfr']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonfr'];
        if (isset($params['taxonl']) && $params['taxonl']!='')
            $sql .= " AND synt.cd_nom = ".$params['taxonl'];
        if (isset($params['idstaxons']) && $params['idstaxons']!='')
            $sql .= " AND synt.cd_nom IN (".$params['idstaxons'].")";
        if ((isset($params['patrimonial']) && $params['patrimonial']!='') || (isset($params['protection_stricte']) && $params['protection_stricte']!='')) {
            if (($params['patrimonial']=='true') || ($params['protection_stricte']=='true')){
                $sql .= " AND (";
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']!='true')){$sql .= "t.filtre2 = 'oui'";}
                    if(($params['patrimonial']!='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre3 = 'oui'";}
                    if(($params['patrimonial']=='true')&&($params['protection_stricte']=='true')){$sql .= "t.filtre2 = 'oui' OR t.filtre3 = 'oui'";}
                $sql .= ")";
            }
        } 
        if (isset($params['id_secteur']) && $params['id_secteur']!='')
            $sql .= " AND com.id_secteur = ".$params['id_secteur'];
        if (isset($params['insee']) && $params['insee']!='')
            $sql .= " AND synt.insee = '".$params['insee']."'";
        if (isset($params['programmes']) && $params['programmes']!='')
            $sql .= " AND p.id_programme IN(".$params['programmes'].")";
        if (isset($params['id_organisme']) && $params['id_organisme']!='')
            $sql .= " AND synt.id_organisme = ".$params['id_organisme'];            
         if (isset($params['datedebut']) && $params['datedebut']!=null && isset($params['datefin']) && $params['datefin']!=null)
            $sql .= " AND synt.dateobs BETWEEN to_date('".$params['datedebut']."','Dy Mon DD YYYY') AND to_date('".$params['datefin']."','Dy Mon DD YYYY')";
        if (isset($params['periodedebut']) && $params['periodedebut']!=null && $params['periodedebut']!='Période début' && isset($params['periodefin']) && $params['periodefin']!=null && $params['periodefin']!='Période fin')   
            $sql .= " AND periode(synt.dateobs,to_date('".$params['periodedebut']."','Dy Mon DD YYYY'),to_date('".$params['periodefin']."','Dy Mon DD YYYY'))=true ";    
        return $sql;
    }
    
    public static function listXlsObs($params)
    {
        $srid_local_export = sfGeonatureConfig::$srid_local;
        $addwhere = self::addwhere($params);
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        if($params['start']=="no"){$from = " FROM synthese.syntheseff synt ";}
        else{$from = " FROM (SELECT * FROM synthese.syntheseff WHERE supprime = false ORDER BY dateobs DESC limit 50) synt ";}
            $sql = "
                SELECT DISTINCT
                sec.nom_secteur AS secteur, com.commune_min AS commune, synt.insee,  synt.dateobs, synt.altitude_retenue AS altitude, synt.observateurs, 
                t.nom_latin AS taxon_latin, t.nom_francais AS taxon_francais,
                CASE 	
                    WHEN t.filtre2 = 'oui'  THEN true
                    WHEN t.filtre2 = 'non'  THEN false
                    ELSE null
                END AS patrimonial,
                CASE 	
                    WHEN t.filtre3 = 'oui'  THEN true
                    WHEN t.filtre3 = 'non'  THEN false
                    ELSE null
                END AS protection_stricte,
                txr.nom_valide, txr.famille, txr.ordre, txr.classe, txr.phylum, txr.regne, synt.cd_nom, txr.cd_ref, 
                c.nom_critere_synthese, synt.effectif_total, synt.remarques, org.nom_organisme AS organisme,
                synt.id_synthese,
                CAST(st_x(st_centroid(synt.the_geom_".$srid_local_export.")) AS int) AS x_srid_local_export, CAST(st_y(st_centroid(synt.the_geom_".$srid_local_export.")) AS int) AS y_srid_local_export,                    
                st_x(st_centroid(st_transform(synt.the_geom_3857,4326))) AS x_wgs84, st_y(st_centroid(st_transform(synt.the_geom_3857,4326))) AS y_wgs84,
                st_geometrytype(synt.the_geom_3857) AS geom_type"
                .$from.
                "LEFT JOIN taxonomie.bib_taxons t ON t.cd_nom = synt.cd_nom
                LEFT JOIN taxonomie.taxref txr ON txr.cd_nom = synt.cd_nom
                LEFT JOIN layers.l_communes com ON com.insee = synt.insee
                LEFT JOIN layers.l_secteurs sec ON sec.id_secteur = com.id_secteur
                LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme = synt.id_organisme
                LEFT JOIN synthese.bib_sources s ON s.id_source = synt.id_source
                LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = synt.id_critere_synthese
                LEFT JOIN meta.bib_lots l ON l.id_lot = synt.id_lot
                LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
                LEFT JOIN synthese.cor_zonesstatut_synthese z ON z.id_synthese = synt.id_synthese 
                WHERE synt.supprime = false"
                .$addwhere.
                "ORDER BY sec.nom_secteur, com.commune_min, t.nom_latin";
                if($params['usage']=="demo"){$sql .= " LIMIT 100 ";}
        $lesobs = $dbh->query($sql);
        return $lesobs;
    }
    
    public static function listXlsStatus($params)
    {
        $addwhere = self::addwhere($params);
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        if($params['start']=="no"){$from = " FROM synthese.syntheseff synt ";}
        else{$from = " FROM (SELECT * FROM synthese.syntheseff WHERE supprime = false ORDER BY dateobs DESC limit 50) synt ";}
            $sql = "
                SELECT DISTINCT t.nom_latin AS taxon_latin, t.nom_francais AS taxon_francais,tpa.type_protection,
                    CASE 	
                        WHEN t.filtre2 = 'oui'  THEN true
                        WHEN t.filtre2 = 'non'  THEN false
                        ELSE null
                    END AS patrimonial,
                    CASE 	
                        WHEN t.filtre3 = 'oui'  THEN true
                        WHEN t.filtre3 = 'non'  THEN false
                        ELSE null
                    END AS protection_stricte,
                    txr.nom_valide, txr.famille, txr.ordre, txr.classe, txr.phylum, txr.regne, synt.cd_nom, txr.cd_ref, 
                    tpa.article, tpa.intitule, tpa.arrete, tpa.date_arrete, tpa.url AS url_texte, tpa.url AS url_taxon"
                .$from.
                "LEFT JOIN taxonomie.bib_taxons t ON t.cd_nom = synt.cd_nom
                LEFT JOIN taxonomie.taxref txr ON txr.cd_nom = synt.cd_nom
                LEFT JOIN taxonomie.taxref_protection_especes tpe ON tpe.cd_nom = t.cd_nom
                JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection = tpe.cd_protection AND tpa.concerne_mon_territoire = true
                LEFT JOIN layers.l_communes com ON com.insee = synt.insee
                LEFT JOIN layers.l_secteurs sec ON sec.id_secteur = com.id_secteur
                LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme = synt.id_organisme
                LEFT JOIN synthese.bib_sources s ON s.id_source = synt.id_source
                LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = synt.id_critere_synthese
                LEFT JOIN meta.bib_lots l ON l.id_lot = synt.id_lot
                LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
                LEFT JOIN synthese.cor_zonesstatut_synthese z ON z.id_synthese = synt.id_synthese 
                WHERE synt.supprime = false"
                .$addwhere.
                " GROUP BY t.nom_latin, t.nom_francais, txr.nom_valide, txr.famille, txr.ordre, txr.classe, txr.phylum, txr.regne, 
                        synt.cd_nom, txr.cd_ref, tpe.precisions, patrimonial, protection_stricte, 
                        tpa.article, tpa.intitule, tpa.arrete, tpa.date_arrete, tpa.url, tpa.url ,tpa.type_protection
                ORDER BY txr.phylum, txr.regne, txr.classe, txr.ordre, txr.famille, t.nom_francais";
        $lesstatuts = $dbh->query($sql);
        return $lesstatuts;
    }
    public static function listShp($params,$typ)
    {
        $srid_local_export = sfGeonatureConfig::$srid_local;
        $addwhere = self::addwhere($params);
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        if($params['start']=="no"){$from = " FROM synthese.syntheseff synt ";}
        else{$from = " FROM (SELECT * FROM synthese.syntheseff WHERE supprime = false ORDER BY dateobs DESC limit 50) synt ";}
            $sql = "SELECT DISTINCT sec.nom_secteur AS secteur, com.commune_min AS commune, synt.insee,  synt.dateobs, synt.altitude_retenue AS altitude, synt.observateurs,"; 
            $sql .= "t.nom_latin AS taxonlatin, t.nom_francais AS taxonfr,";
            $sql .= "CASE 	
                        WHEN t.filtre2 = 'oui'  THEN true
                        WHEN t.filtre2 = 'non'  THEN false
                        ELSE null
                    END AS patrimonial,";
            $sql .= "CASE 	
                        WHEN t.filtre3 = 'oui'  THEN true
                        WHEN t.filtre3 = 'non'  THEN false
                        ELSE null
                    END AS protection_stricte,";
            $sql .= "txr.nom_valide, txr.famille, txr.ordre, txr.classe, synt.cd_nom, txr.cd_ref, synt.effectif_total AS eff_total,synt.id_synthese AS idsynthese,";
            $sql .= "c.nom_critere_synthese AS critere,synt.remarques, org.nom_organisme AS organisme,";
            if($typ=='centroid'){
                $sql .= "ST_transform(synt.the_geom_point,".$srid_local_export.") AS the_geom,
                        CASE st_geometrytype(synt.the_geom_3857) 
                            WHEN 'ST_Point' THEN 'point'
                            WHEN 'ST_Polygon' THEN 'polygone'
                            WHEN 'ST_Line' THEN 'ligne'
                        END AS geom_src ";
            }
            else{$sql .= "synt.the_geom_".$srid_local_export." AS the_geom";}
            $sql .= $from;
            $sql .= "LEFT JOIN taxonomie.bib_taxons t ON t.cd_nom = synt.cd_nom ";
            $sql .= "LEFT JOIN taxonomie.taxref txr ON txr.cd_nom = t.cd_nom ";
            $sql .= "LEFT JOIN layers.l_communes com ON com.insee = synt.insee ";
            $sql .= "LEFT JOIN layers.l_secteurs sec ON sec.id_secteur = com.id_secteur ";
            $sql .= "LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme = synt.id_organisme ";
            $sql .= "LEFT JOIN synthese.bib_sources s ON s.id_source = synt.id_source ";
            $sql .= "LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = synt.id_critere_synthese ";
            $sql .= "LEFT JOIN meta.bib_lots l ON l.id_lot = synt.id_lot ";
            $sql .= "LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme ";
            $sql .= "LEFT JOIN synthese.cor_zonesstatut_synthese z ON z.id_synthese = synt.id_synthese ";
            $sql .= "WHERE synt.supprime = false ";
            if($typ!='centroid'){$sql .= "AND ST_geometrytype(synt.the_geom_".$srid_local_export.") = '".$typ."'::text ";}
            $sql .= $addwhere;
            if($params['usage']=="demo"){$sql .= " LIMIT 100 ";}
            return $sql;
    }
}