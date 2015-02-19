<?php


class BibTaxonsFpTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibTaxonsFp');
    }
    public static function listlAll()
    {
        $taxons = Doctrine_Query::create()
          ->select('cd_nom, latin')
          ->from('BibTaxonsFp')
          ->fetchArray();
        return $taxons;
    }
    public static function listfAll()
    {
        $taxons = Doctrine_Query::create()
          ->select('cd_nom, francais')
          ->from('BibTaxonsFp')
          ->fetchArray();
        return $taxons;
    }
}