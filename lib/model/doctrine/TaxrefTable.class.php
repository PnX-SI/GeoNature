<?php


class TaxrefTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('Taxref');
    }
    public static function filtreTaxonOrigineFs()
    {
       $taxons = Doctrine_Query::create()
          ->select('cd_nom, lb_nom')
          ->from('Taxref t')
          ->innerJoin('t.CorFsTaxon czt')
          ->fetchArray();
        return $taxons; 
    }

    public static function colorMatch($string,$array_lb_nom)
    {
        //isoler le texte recherché dans le taxref
        $pattern = '/'.$array_lb_nom[0].'/i';
        preg_match($pattern,$string,$txt_taxref_recherche);
        if(isset($txt_taxref_recherche[0])){
            //tester s'il comporte une majuscule
            // preg_match('#^[^A-Z]*([A-Z])#',$txt_taxref_recherche[0],$result);
            preg_match('#^([A-Z])#',$txt_taxref_recherche[0],$result);
                //si oui remplacer par ucfirst avec la couleur en orange
                if(isset($result[1])){$string = str_ireplace($array_lb_nom[0],'<SPAN STYLE="COLOR:ORANGE">'.ucfirst($array_lb_nom[0]).'</SPAN>',$string);}
                //si non remplacer par minuscule avec la couleur en orange
                else{$string = str_ireplace($array_lb_nom[0],'<SPAN STYLE="COLOR:ORANGE">'.strtolower($array_lb_nom[0]).'</SPAN>',$string);}
        }
        if(isset($array_lb_nom[1])){$string = str_replace(' '.$array_lb_nom[1],'<span style="color:red"> '.$array_lb_nom[1].'</span>',$string);}
        $string = str_ireplace("'","\'",$string);
        return $string; 
    }

    public static function getTaxonRefence($lb_nom,$cd_nom)
    {
        $statement = Doctrine_Manager::getInstance()->connection();
        $array_lb_nom = explode(" ",$lb_nom);
        $sql = "SELECT cd_nom, cd_ref, lb_nom,nom_complet, nom_vern FROM taxonomie.taxref 
                WHERE cd_ref IN(
                    SELECT distinct cd_ref FROM taxonomie.taxref";
                    // if ($lb_nom != null || $lb_nom != ''){$sql .= " WHERE lb_nom ILIKE ('%$lb_nom%') OR nom_vern ILIKE ('%$lb_nom%')";}
                    if ($lb_nom != null || $lb_nom != ''){
                        if(!isset($array_lb_nom[1])){$sql .= " WHERE lb_nom ~* '([A-Z]( ".str_replace("'","''",$array_lb_nom[0]).")[A-Z]?)' OR nom_vern ~* '([A-Z]( ".str_replace("'","''",$array_lb_nom[0]).")[A-Z]?)'";}
                        if(isset($array_lb_nom[1])){$sql .= " WHERE (lb_nom ~* '^(".str_replace("'","''",$array_lb_nom[0]).")' AND lb_nom ~* '([A-Z]( ".str_replace("'","''",$array_lb_nom[1]).")[A-Z]?)') OR (nom_vern ~* '^(".str_replace("'","''",$array_lb_nom[0]).")' AND nom_vern ~* '([A-Z]( ".str_replace("'","''",$array_lb_nom[1]).")[A-Z]?)')";}
                    }
                    if ($cd_nom != null || $cd_nom != ''){$sql .= " WHERE cd_nom = $cd_nom";}
                    $sql .=")";
        $sql .=" ORDER BY cd_ref";

        $results = $statement->execute($sql);
        $liste = $results->fetchAll(PDO::FETCH_ASSOC);
        $taxons = count($liste)>1?count($liste).' résultat(s) : <br><br>':count($liste).' résultat : <br><br>';
        $taxons_synonyme = '';
        $taxons_ref = '';
        $previous_ref = 0;
        $change_ref = false;
        foreach ($liste as $key => &$l){
            if($l['cd_ref']==$previous_ref || $previous_ref == 0){
                if($l['cd_nom']==$l['cd_ref']){$taxons_ref = '<span style="font-weight:bold">'.self::colorMatch($l['nom_complet'],$array_lb_nom).' ['.$l['cd_nom'].'] - '.self::colorMatch($l['nom_vern'],$array_lb_nom).'</span><br>Synonyme(s) :<br>';}
                else{$taxons_synonyme .= '<span style="margin-left:10px">'.self::colorMatch($l['nom_complet'],$array_lb_nom).' ['.$l['cd_nom'].'] - <span style="font-weight:bold">['.$l['cd_ref'].'] </span> </span> <br>';}
            }
            else{
                $taxons .= $taxons_ref.$taxons_synonyme;
                $taxons_synonyme = '';
                $taxons_ref = '';
                $change_ref = true;
                if($l['cd_nom']==$l['cd_ref']){$taxons_ref = '<span style="font-weight:bold">'.self::colorMatch($l['nom_complet'],$array_lb_nom).' ['.$l['cd_nom'].'] - '.self::colorMatch($l['nom_vern'],$array_lb_nom).'</span><br>Synonyme(s) :<br>';}
                else{$taxons_synonyme .= '<span style="margin-left:10px">'.self::colorMatch($l['nom_complet'],$array_lb_nom).' ['.$l['cd_nom'].'] - <span style="font-weight:bold">['.$l['cd_ref'].'] </span> </span> <br>';}
            }
            if(count($liste)==$key+1 && $change_ref == false ){
                $taxons .= $taxons_ref.$taxons_synonyme;
                $taxons_synonyme = '';
                $taxons_ref = '';
            }
            $previous_ref = $l['cd_ref'];
        }
        return $taxons;
    }


    public static function filtreTaxonOrigineBryo() 
    {
        $statement = Doctrine_Manager::getInstance()->connection();
        // $sql = "select t.cd_nom, t.nom_complet FROM taxonomie.taxref t
                // JOIN (
                // select distinct t.cd_ref FROM taxonomie.taxref t
                // JOIN bryophytes.cor_bryo_taxon c ON c.cd_nom = t.cd_nom 
                // right JOIN bryophytes.t_stations_bryo s ON s.id_station = c.id_station WHERE s.supprime = false AND c.supprime=false
                // ) a ON a.cd_ref = t.cd_nom";
        $sql = "select t.cd_nom, t.lb_nom FROM taxonomie.taxref t
                JOIN (
                        select distinct t.cd_ref FROM taxonomie.taxref t
                        JOIN bryophytes.cor_bryo_taxon c ON c.cd_nom = t.cd_nom 
                        right JOIN bryophytes.t_stations_bryo s ON s.id_station = c.id_station WHERE s.supprime = false AND c.supprime=false
                    ) a ON a.cd_ref = t.cd_nom
                WHERE t.ordre IN(
                    'Buxbaumiales'
                    ,'Diphysciales'
                    ,'Timmiales'
                    ,'Encalyptales','Funariales','Gigaspermales'
                    ,'Archidiales','Bryoxiphiales','Grimmiales','Pottiales','Scouleriales'
                    ,'Bartramiales','Bryales','Hedwigiales','Orthotrichales','Rhizogoniales','Splachnales'
                    ,'Hookeriales','Hypnales','Hypnodendrales','Ptychomniales'
                    ,'Marchantiales','Monocleales','Ricciales','Sphaerocarpales'
                    ,'Metzgeriales','Jungermanniales','Takakiales','Calobryales'
                )";
        $results = $statement->execute($sql);
        $liste = $results->fetchAll();
        foreach ($liste as $key => &$l){unset($l['0'],$l['1']);}
        return $liste;
    }

    public static function filtreTaxonReferenceFs()
    {
        $statement = Doctrine_Manager::getInstance()->connection();
        $sql = "select * FROM florestation.v_taxons_fs";
        $results = $statement->execute($sql);
        $liste = $results->fetchAll(PDO::FETCH_ASSOC);
        // foreach ($liste as $key => &$l){unset($l['0'],$l['1']);}
        return $liste;
    }
    
    public static function filtreTaxonReferenceBryo() {
        $statement = Doctrine_Manager::getInstance()->connection();
        // $sql = "select t.cd_nom, t.nom_complet FROM taxonomie.taxref t
                // JOIN (
                // select distinct t.cd_ref FROM taxonomie.taxref t
                // JOIN bryophytes.cor_bryo_taxon c ON c.cd_nom = t.cd_nom 
                // right JOIN bryophytes.t_stations_bryo s ON s.id_station = c.id_station WHERE s.supprime = false AND c.supprime=false
                // ) a ON a.cd_ref = t.cd_nom";
        $sql = "select t.cd_nom, t.nom_complet FROM taxonomie.taxref t
                WHERE ordre IN(
                    'Buxbaumiales'
                    ,'Diphysciales'
                    ,'Timmiales'
                    ,'Encalyptales','Funariales','Gigaspermales'
                    ,'Archidiales','Bryoxiphiales','Grimmiales','Pottiales','Scouleriales'
                    ,'Bartramiales','Bryales','Hedwigiales','Orthotrichales','Rhizogoniales','Splachnales'
                    ,'Hookeriales','Hypnales','Hypnodendrales','Ptychomniales'
                    ,'Marchantiales','Monocleales','Ricciales','Sphaerocarpales'
                )";
        $results = $statement->execute($sql);
        $liste = $results->fetchAll();
        foreach ($liste as $key => &$l){unset($l['0'],$l['1']);}
        return $liste;
    }
    
    public static function TaxonBryo()
    {
        $statement = Doctrine_Manager::getInstance()->connection();
        $sql = "select t.cd_nom, t.nom_complet FROM taxonomie.taxref t
                WHERE ordre IN(
                    'Buxbaumiales'
                    ,'Diphysciales'
                    ,'Timmiales'
                    ,'Encalyptales','Funariales','Gigaspermales'
                    ,'Archidiales','Bryoxiphiales','Grimmiales','Pottiales','Scouleriales'
                    ,'Bartramiales','Bryales','Hedwigiales','Orthotrichales','Rhizogoniales','Splachnales'
                    ,'Hookeriales','Hypnales','Hypnodendrales','Ptychomniales'
                )";
        $results = $statement->execute($sql);
        $liste = $results->fetchAll();
        foreach ($liste as $key => &$l){unset($l['0'],$l['1']);}
        return $liste;
    }
}