<?php


class BibExpositionsBryoTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibExpositionsBryo');
    }
    public static function listExpositions()
    {
        $query = Doctrine_Query::create()
          ->select('id_exposition, nom_exposition')
          ->from('BibExpositionsBryo')
          ->orderBy('tri_exposition')
          ->fetchArray();
        return $query;
    }
}