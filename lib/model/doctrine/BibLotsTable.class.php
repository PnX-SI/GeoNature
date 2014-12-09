<?php


class BibLotsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibLots');
    }

    public static function listLots()
    {
        $query = Doctrine_Query::create()
          ->select('id_lot, nom_lot')
          ->from('BibLots')         
          ->orderBy('id_lot ASC');               
        $lots = $query->fetchArray();
        return $lots;
    }
}