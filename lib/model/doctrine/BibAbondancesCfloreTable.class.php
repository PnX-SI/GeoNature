<?php


class BibAbondancesCfloreTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibAbondancesCflore');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_abondance_cflore, nom_abondance_cflore')
          ->from('BibAbondancesCflore')
          ->fetchArray();
        return $query;
    }
}