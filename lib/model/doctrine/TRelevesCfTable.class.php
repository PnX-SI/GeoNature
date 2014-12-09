<?php


class TRelevesCfTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRelevesCf');
    }
    public static function getListRelevesCf($id_cf)
    {
        $select = 'r.id_releve_cf, r.id_cf, r.id_taxon, r.id_critere_cf, r.am, r.af, r.ai, r.na, r.jeune, r.yearling, r.sai, r.nom_taxon_saisi, r.prelevement, r.commentaire,'.
            'v.cd_ref, r.cd_ref_origine,v.nom_francais,v.nom_latin, v.patrimonial, v.id_classe, v.denombrement,v.message';
        $releves = Doctrine_Query::create()
          ->select($select)
          ->from('TRelevesCf r')
          ->leftJoin('r.VNomadeTaxonsFaune v')
          ->where('r.supprime=?', false)
          ->addWhere('r.id_cf=?', $id_cf)
          ->fetchArray();
          // print_r($releves);
            foreach ($releves as $key => &$releve)
            {
              if($releve['id_critere_cf']==2){
                if($releve['am']==1){$releve['sexeage']='am';$releve['sexeageinfo']='Ad mâle';}
                if($releve['af']==1){$releve['sexeage']='af';$releve['sexeageinfo']='Ad femelle';}
                if($releve['ai']==1){$releve['sexeage']='ai';$releve['sexeageinfo']='Ad indéterminé';}
                if($releve['na']==1){$releve['sexeage']='na';$releve['sexeageinfo']='Non adulte';}
                if($releve['jeune']==1){$releve['sexeage']='jeune';$releve['sexeageinfo']='Jeune';}
                if($releve['yearling']==1){$releve['sexeage']='yearling';$releve['sexeageinfo']='Yearling';}
                if($releve['sai']==1){$releve['sexeage']='sai';$releve['sexeageinfo']='Sexe et âge indéterminé';}
              }
              $releve['cd_ref'] = $releve['VNomadeTaxonsFaune'][0]['cd_ref'];
              $releve['nom_francais'] = $releve['VNomadeTaxonsFaune'][0]['nom_francais'];
              $releve['nom_latin'] = $releve['VNomadeTaxonsFaune'][0]['nom_latin'];
              $releve['patrimonial'] = (!$releve['VNomadeTaxonsFaune'][0]['patrimonial'])?true:false;
              $releve['id_classe'] = $releve['VNomadeTaxonsFaune'][0]['id_classe'];
              $releve['denombrement'] = $releve['VNomadeTaxonsFaune'][0]['denombrement'];
              $releve['message'] = $releve['VNomadeTaxonsFaune'][0]['message'];
              unset($releve['VNomadeTaxonsFaune']);
            }
        return $releves;
    }
    public static function getMaxIdReleve()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_releve_cf) as maxid' )
        ->from('TRelevesCf')
        ->where('id_releve_cf<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
    public static function getDatasNbObsCf()
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        //définition du tableau à renvoyer en json
        $datas_tout = array();
        
        //total des données
        $sql = "SELECT a.date_insert AS d,count(*) AS nb FROM 
                (SELECT id_releve_cf ,TO_CHAR(date_insert, 'DD-MM-YYYY') AS date_insert FROM contactfaune.t_releves_cf r
                JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
                WHERE date_insert >= '2012-11-05') a
                GROUP BY a.date_insert
                ORDER BY TO_DATE(a.date_insert, 'DD-MM-YYYY')";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);
        
         //données web
        $sql = "SELECT a.date_insert AS d,count(*) AS nb FROM 
                (SELECT id_releve_cf ,TO_CHAR(date_insert, 'DD-MM-YYYY') AS date_insert FROM contactfaune.t_releves_cf r
                JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
                WHERE id_releve_cf < 1000000
                AND date_insert >= '2012-11-05') a
                GROUP BY a.date_insert
                ORDER BY TO_DATE(a.date_insert, 'DD-MM-YYYY')";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);

    //données nomade
    $sql = "SELECT TO_CHAR(a.dateobs, 'DD-MM-YYYY') AS d,count(*) AS nb FROM 
            (SELECT id_releve_cf ,dateobs FROM contactfaune.t_releves_cf r
            JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
            WHERE id_releve_cf > 1000000
            AND dateobs >= '2012-11-05') a
            GROUP BY a.dateobs
            ORDER BY a.dateobs";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);

        return $datas_tout;
    }
    
    public static function getDatasNbObsInv()
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        //définition du tableau à renvoyer en json
        $datas_tout = array();
        
        //total des données
        $sql = "SELECT a.date_insert AS d,count(*) AS nb FROM 
                (SELECT id_releve_inv ,TO_CHAR(date_insert, 'DD-MM-YYYY') AS date_insert FROM contactinv.t_releves_inv r
                JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
                WHERE date_insert >= '2012-11-05') a
                GROUP BY a.date_insert
                ORDER BY TO_DATE(a.date_insert, 'DD-MM-YYYY')";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);
        
         //données web
        $sql = "SELECT a.date_insert AS d,count(*) AS nb FROM 
                (SELECT id_releve_inv ,TO_CHAR(date_insert, 'DD-MM-YYYY') AS date_insert FROM contactinv.t_releves_inv r
                JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
                WHERE id_releve_inv < 1000000
                AND date_insert >= '2012-11-05') a
                GROUP BY a.date_insert
                ORDER BY TO_DATE(a.date_insert, 'DD-MM-YYYY')";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);

    //données nomade
    $sql = "SELECT TO_CHAR(a.dateobs, 'DD-MM-YYYY') AS d,count(*) AS nb FROM 
            (SELECT id_releve_inv ,dateobs FROM contactinv.t_releves_inv r
            JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
            WHERE id_releve_inv > 1000000
            AND dateobs >= '2012-11-05') a
            GROUP BY a.dateobs
            ORDER BY a.dateobs";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);       
        $nb = count($result);
        $datas = array();
        $somme = 0;
        for ($i = 0; $i < $nb; $i++) { 
            $data = array();
            $somme =  $somme +(int) $result[$i]['nb'];
            array_push($data, (strtotime($result[$i]['d'])) * 1000, $somme);
            array_push($datas, $data);  
        }
        array_push($datas_tout,$datas);

        return $datas_tout;
    }
    
    public static function getDatasColorsCf()
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        //définition du tableau à renvoyer en json
    $datas_tout = array();
    
    //requête et construction du tableau des jaunes
    //recherche du max
    $sql = "SELECT max(nbtaxons) FROM contactfaune.log_colors_day WHERE couleur = 'jaune'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $max = $result[0]['max'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $max AS nbtaxons FROM contactfaune.log_colors_day WHERE couleur = 'jaune' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    // $jours = pg_fetch_all_columns($result,0);
    // $nbtaxons = pg_fetch_all_columns($result,1);
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);
    
    //requête et construction du tableau des rouges
    //recherche du max
    $sql = "SELECT max(nbtaxons) FROM contactfaune.log_colors_day WHERE couleur = 'red'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $max = $result[0]['max'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $max AS nbtaxons FROM contactfaune.log_colors_day WHERE couleur = 'red' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);
    
    //requête et construction du tableau des gris
    //recherche du min
    $sql = "SELECT min(nbtaxons) FROM contactfaune.log_colors_day WHERE couleur = 'gray'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $min = $result[0]['min'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $min AS nbtaxons FROM contactfaune.log_colors_day WHERE couleur = 'gray' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);

        return $datas_tout;
    }
    
    
    public static function getDatasColorsInv()
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        //définition du tableau à renvoyer en json
    $datas_tout = array();
    
    //requête et construction du tableau des jaunes
    //recherche du max
    $sql = "SELECT max(nbtaxons) FROM contactinv.log_colors_day WHERE couleur = 'jaune'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $max = $result[0]['max'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $max AS nbtaxons FROM contactinv.log_colors_day WHERE couleur = 'jaune' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    // $jours = pg_fetch_all_columns($result,0);
    // $nbtaxons = pg_fetch_all_columns($result,1);
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);
    
    //requête et construction du tableau des rouges
    //recherche du max
    $sql = "SELECT max(nbtaxons) FROM contactinv.log_colors_day WHERE couleur = 'red'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $max = $result[0]['max'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $max AS nbtaxons FROM contactinv.log_colors_day WHERE couleur = 'red' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);
    
    //requête et construction du tableau des gris
    //recherche du min
    $sql = "SELECT min(nbtaxons) FROM contactinv.log_colors_day WHERE couleur = 'gray'";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $min = $result[0]['min'];
    //valeurs pour les jaunes
    $sql = "SELECT TO_CHAR(jour, 'DD-MM-YYYY') AS dateobs, nbtaxons - $min AS nbtaxons FROM contactinv.log_colors_day WHERE couleur = 'gray' ORDER BY jour";
    $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    //Compter le nombre d'enregistrements renvoyés par la requete
	$nb = count($result);
    $datas_jaune = array();
    for ($i = 1; $i < $nb; $i++) { 
        $data = array();
        array_push($data, (strtotime($result[$i]['dateobs'])) * 1000, (int) $result[$i]['nbtaxons']);
        array_push($datas_jaune, $data);  
    }
    array_push($datas_tout,$datas_jaune);

        return $datas_tout;
    }
}