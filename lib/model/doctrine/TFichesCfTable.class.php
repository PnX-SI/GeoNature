<?php


class TFichesCfTable extends Doctrine_Table
{
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TFichesCf');
    }
    public static function listAll()
    {
        $list = Doctrine_Query::create()
          ->select('id_cf, dateobs')
          ->from('TFichesCf')
          ->where('supprime=?', false)
          ->fetchArray();
        return $list;
    }
    //methode pour l'alimentation du formulaire de saisie
    //on passe l'altitude retenue avec le nom altitude _saisie pour l'enregistrement de retour du formulaire
    public static function findOne($id_cf, $format = null)
    {
        $fields = 'f.id_cf,  f.dateobs,f.altitude_retenue altitude_saisie,com.commune_min commune';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $fiche = $query
              ->select($fields)
              ->from('TFichesCf f')
              ->leftJoin('f.LCommunes com')
              ->where('id_cf=?', $id_cf)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($fiche['id_cf']) && $fiche['id_cf']=='')
          return false;

        // Format array
        $fiche['ids_observateurs'] = self::listIdsObservateurs($id_cf);
        $fiche['lesobservateurs'] = $fiche['ids_observateurs'];//pour le chargement auto du combobox multiselect dans extjs

        //remise au format des dates
        $d = array(); $pattern = '/^(\d{4})-(\d{2})-(\d{2})/';
        preg_match($pattern, $fiche['dateobs'], $d);
        $fiche['dateobs'] = sprintf('%s/%s/%s', $d[3],$d[2],$d[1]);

        return $fiche;
    }
    public static function getMaxIdFiche()
    {
        $ids= Doctrine_Query::create()
        ->select('max(id_cf) as maxid' )
        ->from('TFichesCf')
        ->where('id_cf<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }

    // private static function getCounterReleveCf($id_cf)
    // {
        // $q = Doctrine_Query::create()
          // ->select('count(id_releve_cf) nb')
          // ->from('TRelevesCf r')
          // ->where('r.id_cf=?',$id_cf)
          // ->addWhere('r.supprime is not true');
        // return $q;
    // }
    private static function listObservateurs($id_cf)
    {
        $observateurs = Doctrine_Query::create()
          ->select("o.id_role, concat(o.prenom_role, ' ', o.nom_role) observateur")
          ->distinct()
          ->from('TRoles o')
          ->innerJoin('o.CorRoleFicheCf crfc')
          ->where('crfc.id_cf=?', $id_cf)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['observateur'];
          array_push($obs,$o);
        }
        return implode(', ',$obs);
    }
    
    private static function listIdsObservateurs($id_cf)
    {
        $observateurs = Doctrine_Query::create()
          ->select("id_role")
          ->distinct()
          ->from('CorRoleFicheCf')
          ->where('id_cf=?', $id_cf)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['id_role'];
          array_push($obs,$o);
        }
        return implode(',',$obs);
    }
}