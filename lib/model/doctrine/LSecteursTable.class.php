<?php


class LSecteursTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('LSecteurs');
    }
    public static function listAll()
    {
        $secteurs = Doctrine_Query::create()
          ->select('id_secteur, nom_secteur, box2d(the_geom) extent')
          ->from('LSecteurs')
          ->execute(array(), Doctrine::HYDRATE_ARRAY);
        foreach ($secteurs as &$secteur)
        {
          preg_match_all('/(\d+)(?:\.\d+)?/', $secteur['extent'], $extent);
          $secteur['extent'] = implode(',', $extent[1]);
        }    
        return $secteurs;
    }
}