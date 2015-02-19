<?php


class BibComptagesMethodoTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibComptagesMethodo');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_comptage_methodo, nom_comptage_methodo')
          ->from('BibComptagesMethodo')
          ->fetchArray();
        return $query;
    }
}