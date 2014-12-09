<?php


class LCommunesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('LCommunes');
    }
    public static function listAll($secteur = null)
    {
        $query = Doctrine_Query::create()
          ->select('insee, commune_min nom_commune, box2d(the_geom) extent')   
          ->from('LCommunes')
          ->where('saisie_fv=true');
        if (!is_null($secteur)){
            $query->addWhere('id_secteur=?',$secteur);
        }
        $communes = $query->fetchArray();       
        foreach ($communes as &$commune)
        {
          preg_match_all('/(\d+)(?:\.\d+)?/', $commune['extent'], $extent);
          $commune['extent'] = implode(',', $extent[1]);
        }
        return $communes;
    }
}