<?php


class BibExpositionsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibExpositions');
    }
    public static function listExpositions()
    {
        $query = Doctrine_Query::create()
          ->select('id_exposition, nom_exposition')
          ->from('BibExpositions')
          ->orderBy('tri_exposition')
          ->fetchArray();
        return $query;
    }
}