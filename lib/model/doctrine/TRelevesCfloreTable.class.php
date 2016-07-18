<?php


class TRelevesCfloreTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRelevesCflore');
    }
    
    public static function getListRelevesCflore($id_cflore)
    {
        $select = 'r.id_releve_cflore, r.id_cflore, r.id_nom, r.nom_taxon_saisi, r.id_abondance_cflore, r.id_phenologie_cflore, r.validite_cflore, r.herbier, r.commentaire, r.determinateur,'.
            'v.cd_ref, r.cd_ref_origine,v.nom_francais,v.nom_latin, v.patrimonial, v.id_classe, v.message';
        $releves = Doctrine_Query::create()
          ->select($select)
          ->from('TRelevesCflore r')
          ->leftJoin('r.VNomadeTaxonsFlore v')
          ->where('r.supprime=?', false)
          ->addWhere('r.id_cflore=?', $id_cflore)
          ->fetchArray();
          // print_r($releves);
            foreach ($releves as $key => &$releve)
            {
              $releve['cd_ref'] = $releve['VNomadeTaxonsFlore'][0]['cd_ref'];
              $releve['nom_francais'] = $releve['VNomadeTaxonsFlore'][0]['nom_francais'];
              $releve['nom_latin'] = $releve['VNomadeTaxonsFlore'][0]['nom_latin'];
              $releve['patrimonial'] = (!$releve['VNomadeTaxonsFlore'][0]['patrimonial'])?true:false;
              $releve['id_classe'] = $releve['VNomadeTaxonsFlore'][0]['id_classe'];
              $releve['message'] = $releve['VNomadeTaxonsFlore'][0]['message'];
              unset($releve['VNomadeTaxonsFlore']);
            }
        return $releves;
    }
    public static function getMaxIdReleve()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_releve_cflore) as maxid' )
        ->from('TRelevesCflore')
        ->where('id_releve_cflore<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }
}