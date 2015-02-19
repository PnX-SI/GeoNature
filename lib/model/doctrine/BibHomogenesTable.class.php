<?php


class BibHomogenesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibHomogenes');
    }
    public static function listHomogenes()
    {
        $query = Doctrine_Query::create()
          ->select('id_homogene, nom_homogene')
          ->from('BibHomogenes')
          ->fetchArray();
        return $query;
    }
}