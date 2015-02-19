<?php


class BibMicroreliefsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibMicroreliefs');
    }
    public static function listMicroreliefs()
    {
        $query = Doctrine_Query::create()
          ->select('id_microrelief, concat(id_microrelief, \' - \',nom_microrelief) nom_microrelief')
          ->from('BibMicroreliefs')
          ->fetchArray();
        return $query;
    }
}