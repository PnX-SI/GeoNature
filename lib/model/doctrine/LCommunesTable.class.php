<?php


class LCommunesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('LCommunes');
    }
    // public static function listAllSynthese($secteur = null)
    // {
        // $query = Doctrine_Query::create()
          // ->select('insee, commune_min nomcommune, box2d(the_geom) extent')   
          // ->from('LCommunes');
          // ->where('saisie=true');
        // if (!is_null($secteur)){
            // $query->addWhere('id_secteur=?',$secteur);
        // }
        // $communes = $query->fetchArray();       
        // foreach ($communes as &$commune)
        // {
          // preg_match_all('/(\d+)(?:\.\d+)?/', $commune['extent'], $extent);
          // $commune['extent'] = implode(',', $extent[1]);
        // }
        // return $communes;
    // }
    // public static function listAllCf($secteur = null)
    // {
        // $query = Doctrine_Query::create()
          // ->select('insee, commune_min nomcommune, box2d(the_geom) extent')   
          // ->from('LCommunes')
          // ->where('saisie=true');
        // if (!is_null($secteur)){
            // $query->addWhere('id_secteur=?',$secteur);
        // }
        // $communes = $query->fetchArray();       
        // foreach ($communes as &$commune)
        // {
          // preg_match_all('/(\d+)(?:\.\d+)?/', $commune['extent'], $extent);
          // $commune['extent'] = implode(',', $extent[1]);
        // }
        // return $communes;
    // }
    
    // public static function listAllFp($secteur = null)
    // {
        // $query = Doctrine_Query::create()
          // ->select('insee, commune_min nomcommune, box2d(st_transform(the_geom,3857)) extent')
          // ->from('LCommunes')
          // ->where('saisie=true'); 
        // if (!is_null($secteur))
          // $query->addWhere('id_secteur = ?', $secteur);   
        // $communes = $query->fetchArray();       
        // foreach ($communes as &$commune)
        // {
          // preg_match_all('/(\d+)(?:\.\d+)?/', $commune['extent'], $extent);
          // $commune['extent'] = implode(',', $extent[1]);
        // }
        // return $communes;
    // }
    public static function listAllSaisie($secteur = null)
    {
        $query = Doctrine_Query::create()
          ->select('insee, commune_min nomcommune, box2d(st_transform(the_geom,3857)) extent')
          ->from('LCommunes')
          ->where('saisie=true'); 
        if (!is_null($secteur))
          $query->addWhere('id_secteur = ?', $secteur);   
        $communes = $query->fetchArray();       
        foreach ($communes as &$commune)
        {
          preg_match_all('/(\d+)(?:\.\d+)?/', $commune['extent'], $extent);
          $commune['extent'] = implode(',', $extent[1]);
        }
        return $communes;
    }
}