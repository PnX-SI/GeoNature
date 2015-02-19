<?php


class BibAbondancesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibAbondances');
    }
    public static function listAbondances()
    {
        $query = Doctrine_Query::create()
          ->select('id_abondance, nom_abondance')
          ->from('BibAbondances')
          ->fetchArray();
        return $query;
    }
}