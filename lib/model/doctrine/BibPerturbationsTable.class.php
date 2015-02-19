<?php


class BibPerturbationsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibPerturbations');
    }
    public static function listAll()
    {
        $perturbations = Doctrine_Query::create()
          ->select('codeper, classification, description')
          ->from('BibPerturbations')
          ->fetchArray();
        return $perturbations;
    }
}