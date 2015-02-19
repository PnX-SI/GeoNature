<?php


class BibSurfacesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibSurfaces');
    }
    public static function listSurfaces()
    {
        $query = Doctrine_Query::create()
          ->select('id_surface, nom_surface')
          ->from('BibSurfaces')
          // ->where('id_surface<=?',2)
          ->fetchArray();
        return $query;
    }
}