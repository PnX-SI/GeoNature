<?php


class TFichesInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TFichesInv');
    }
    public static function listAll()
    {
        $list = Doctrine_Query::create()
          ->select('id_inv, dateobs')
          ->from('TFichesInv')
          ->where('supprime=?', false)
          ->fetchArray();
        return $list;
    }
    //methode pour l'alimentation du formulaire de saisie
    //on passe l'altitude retenue avec le nom altitude _saisie pour l'enregistrement de retour du formulaire
    public static function findOne($id_inv, $format = null)
    {
        $fields = 'f.id_inv, f.dateobs, f.altitude_retenue altitude_saisie, f.heure, f.id_milieu_inv, com.commune_min commune';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $fiche = $query
              ->select($fields)
              ->from('TFichesInv f')
              ->leftJoin('f.LCommunes com')
              ->where('id_inv=?', $id_inv)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($fiche['id_inv']) && $fiche['id_inv']=='')
          return false;

        // Format array
        $fiche['ids_observateurs'] = self::listIdsObservateurs($id_inv);
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
        ->select('max(id_inv) as maxid' )
        ->from('TFichesInv')
        ->where('id_inv<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }

    // private static function getCounterReleveInv($id_inv)
    // {
        // $q = Doctrine_Query::create()
          // ->select('count(id_releve_inv) nb')
          // ->from('TRelevesInv r')
          // ->where('r.id_inv=?',$id_inv)
          // ->addWhere('r.supprime is not true');
        // return $q;
    // }
    private static function listObservateurs($id_inv)
    {
        $observateurs = Doctrine_Query::create()
          ->select("o.id_role, concat(o.prenom_role, ' ', o.nom_role) observateur")
          ->distinct()
          ->from('TRoles o')
          ->innerJoin('o.CorRoleFicheInv crfc')
          ->where('crfc.id_inv=?', $id_inv)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['observateur'];
          array_push($obs,$o);
        }
        return implode(', ',$obs);
    }
    
    private static function listIdsObservateurs($id_inv)
    {
        $observateurs = Doctrine_Query::create()
          ->select("id_role")
          ->distinct()
          ->from('CorRoleFicheInv')
          ->where('id_inv=?', $id_inv)
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