<?php


class BibSupportsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibSupports');
    }
    public static function listSupports()
    {
        $query = Doctrine_Query::create()
          ->select('id_support, nom_support')
          ->from('BibSupports')
          ->whereIn('id_support', array(1,2,3,999))
          ->fetchArray();
        return $query;
    }
}