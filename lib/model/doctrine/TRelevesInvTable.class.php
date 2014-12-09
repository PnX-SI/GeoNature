<?php


class TRelevesInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRelevesInv');
    }
    public static function getListRelevesInv($id_inv)
    {
        $select = 'r.id_releve_inv, r.id_inv, r.id_taxon, r.id_critere_inv, r.am, r.af, r.ai, r.na, r.nom_taxon_saisi, r.commentaire,'.
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
}