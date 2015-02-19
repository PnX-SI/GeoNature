<?php


class BibAbondancesBryoTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibAbondancesBryo');
    }
    public static function listAbondances()
    {
        $query = Doctrine_Query::create()
          ->select('id_abondance, nom_abondance')
          ->from('BibAbondancesBryo')
          ->fetchArray();
        return $query;
    }
}