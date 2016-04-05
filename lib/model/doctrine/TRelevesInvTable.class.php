<?php


class TRelevesInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRelevesInv');
    }
    public static function getListRelevesInv($id_inv)
    {
        $select = 'r.id_releve_inv, r.id_inv, r.id_taxon, r.id_critere_inv, r.am, r.af, r.ai, r.na, r.nom_taxon_saisi, r.commentaire, r.determinateur,'.
            'v.cd_ref, r.cd_ref_origine,v.nom_francais,v.nom_latin, v.patrimonial, v.id_classe, v.message';
        $releves = Doctrine_Query::create()
          ->select($select)
          ->from('TRelevesInv r')
          ->leftJoin('r.VNomadeTaxonsInv v')
          ->where('r.supprime=?', false)
          ->addWhere('r.id_inv=?', $id_inv)
          ->fetchArray();
          // print_r($releves);
            foreach ($releves as $key => &$releve)
            {
              $releve['cd_ref'] = $releve['VNomadeTaxonsInv'][0]['cd_ref'];
              $releve['nom_francais'] = $releve['VNomadeTaxonsInv'][0]['nom_francais'];
              $releve['nom_latin'] = $releve['VNomadeTaxonsInv'][0]['nom_latin'];
              $releve['patrimonial'] = (!$releve['VNomadeTaxonsInv'][0]['patrimonial'])?true:false;
              $releve['id_classe'] = $releve['VNomadeTaxonsInv'][0]['id_classe'];
              $releve['message'] = $releve['VNomadeTaxonsInv'][0]['message'];
              unset($releve['VNomadeTaxonsInv']);
            }
        return $releves;
    }
    public static function getMaxIdReleve()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_releve_inv) as maxid' )
        ->from('TRelevesInv')
        ->where('id_releve_inv<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
        
    public static function getDatasNbObsInv()
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
       //total des données
        $sql = "SELECT 
                    DISTINCT TO_CHAR(f.dateobs, 'YYYY-MM') AS d, 
                    w.nb AS web, 
                    n.nb AS nomade
                FROM contactinv.t_fiches_inv f
                LEFT JOIN
                (
                    SELECT dateobs AS d, count(r.*) AS nb 
                    FROM  contactinv.t_releves_inv r
                    JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv AND f.saisie_initiale = 'web'
                    WHERE f.dateobs >= '".sfGeonatureConfig::$init_date_statistiques."'
                    AND r.supprime = false
                    GROUP BY dateobs
                    ORDER BY dateobs
                ) w ON w.d = f.dateobs
                LEFT JOIN 
                (
                    SELECT dateobs AS d, count(*) AS nb 
                    FROM  contactinv.t_releves_inv r
                    JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv AND f.saisie_initiale = 'nomade'
                    WHERE f.dateobs >= '".sfGeonatureConfig::$init_date_statistiques."'
                    AND r.supprime = false
                    GROUP BY dateobs
                    ORDER BY dateobs
                ) n ON n.d = f.dateobs
                ORDER BY TO_CHAR(f.dateobs, 'YYYY-MM')";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
        $datas = array();
        $somme_web = 0;
        $somme_nomade = 0;
        $somme_total = 0;
        foreach ($result as &$row) {
            $data = array();
            $somme_web =  $somme_web +(int) $row['web'];
            $somme_nomade =  $somme_nomade +(int) $row['nomade'];
            $somme_total =  $somme_nomade +$somme_web;
            $data = ['d'=>$row['d'], 'web'=>$somme_web, 'nomade'=>$somme_nomade, 'total'=>$somme_total];
            array_push($datas, $data);
        } 
        return $datas;
    }
}