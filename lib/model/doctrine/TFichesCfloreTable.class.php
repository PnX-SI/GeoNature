<?php


class TFichesCfloreTable extends Doctrine_Table
{
   public static function getInstance()
    {
        return Doctrine_Core::getTable('TFichesCflore');
    }
    public static function listAll()
    {
        $list = Doctrine_Query::create()
          ->select('id_cflore, dateobs')
          ->from('TFichesCflore')
          ->where('supprime=?', false)
          ->fetchArray();
        return $list;
    }
    //methode pour l'alimentation du formulaire de saisie
    //on passe l'altitude retenue avec le nom altitude _saisie pour l'enregistrement de retour du formulaire
    public static function findOne($id_cflore, $format = null)
    {
        $fields = 'f.id_cflore, f.dateobs,f.altitude_retenue altitude_saisie,com.commune_min commune';
        if ( !is_null($format) && $format==='geoJSON' )
            $query = mfQuery::create('the_geom_3857');  
        else 
            $query = Doctrine_Query::create(); 
            $fiche = $query
              ->select($fields)
              ->from('TFichesCflore f')
              ->leftJoin('f.LCommunes com')
              ->where('id_cflore=?', $id_cflore)
              ->fetchOne(array(), Doctrine::HYDRATE_ARRAY);

        if (!isset($fiche['id_cflore']) && $fiche['id_cflore']=='')
          return false;

        // Format array
        $fiche['ids_observateurs'] = self::listIdsObservateurs($id_cflore);
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
        ->select('max(id_cflore) as maxid' )
        ->from('TFichesCflore')
        ->where('id_cflore<10000000')
        ->fetchArray();
        foreach ($ids as $key => &$id)
        {
           $maxid = $id['maxid'];
        }
        return $maxid;
    }

    private static function listObservateurs($id_cflore)
    {
        $observateurs = Doctrine_Query::create()
          ->select("o.id_role, concat(o.prenom_role, ' ', o.nom_role) observateur")
          ->distinct()
          ->from('TRoles o')
          ->innerJoin('o.CorRoleFicheCflore crfc')
          ->where('crfc.id_cflore=?', $id_cflore)
          ->fetchArray();
          $obs = array();
        foreach ($observateurs as $observateur)
        {
          $o = $observateur['observateur'];
          array_push($obs,$o);
        }
        return implode(', ',$obs);
    }
    
    private static function listIdsObservateurs($id_cflore)
    {
        $observateurs = Doctrine_Query::create()
          ->select("id_role")
          ->distinct()
          ->from('CorRoleFicheCflore')
          ->where('id_cflore=?', $id_cflore)
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