<?php


class BibPhenologiesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibPhenologies');
    }
    public static function listAll()
    {
        $phenos = Doctrine_Query::create()
          ->select('codepheno, pheno')
          ->from('BibPhenologies')
          ->fetchArray();
        return $phenos;
    }
}