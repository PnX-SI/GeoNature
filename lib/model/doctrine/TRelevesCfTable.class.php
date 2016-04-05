<?php


class TRelevesCfTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRelevesCf');
    }
    public static function getListRelevesCf($id_cf)
    {
        $select = 'r.id_releve_cf, r.id_cf, r.id_taxon, r.id_critere_cf, r.am, r.af, r.ai, r.na, r.jeune, r.yearling, r.sai, r.nom_taxon_saisi, r.prelevement, r.commentaire, r.determinateur,'.
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
       //total des données
        $sql = "SELECT 
                    DISTINCT TO_CHAR(f.dateobs, 'YYYY-MM') AS d, 
                    w.nb AS web, 
                    n.nb AS nomade
                FROM contactfaune.t_fiches_cf f
                LEFT JOIN
                (
                    SELECT dateobs AS d, count(r.*) AS nb 
                    FROM  contactfaune.t_releves_cf r
                    JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf AND f.saisie_initiale = 'web'
                    WHERE f.dateobs >= '".sfGeonatureConfig::$init_date_statistiques."'
                    AND r.supprime = false
                    GROUP BY dateobs
                    ORDER BY dateobs
                ) w ON w.d = f.dateobs
                LEFT JOIN 
                (
                    SELECT dateobs AS d, count(*) AS nb 
                    FROM  contactfaune.t_releves_cf r
                    JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf AND f.saisie_initiale = 'nomade'
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
