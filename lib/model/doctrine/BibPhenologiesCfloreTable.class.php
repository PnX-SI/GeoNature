<?php


class BibPhenologiesCfloreTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibPhenologiesCflore');
    }
    public static function listAll()
    {
        $phenos = Doctrine_Query::create()
          ->select('id_phenologie_cflore, nom_phenologie_cflore')
          ->from('BibPhenologiesCflore')
          ->fetchArray();
        return $phenos;
    }
}