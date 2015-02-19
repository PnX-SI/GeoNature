<?php


class BibPhysionomiesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibPhysionomies');
    }
    public static function listAll()
    {
        $physionomies = Doctrine_Query::create()
          ->select('id_physionomie, groupe_physionomie, nom_physionomie')
          ->from('BibPhysionomies')
          ->fetchArray();
        return $physionomies;
    }
}