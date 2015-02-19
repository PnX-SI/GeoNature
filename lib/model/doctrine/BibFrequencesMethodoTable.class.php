<?php


class BibFrequencesMethodoTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibFrequencesMethodo');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_frequence_methodo, nom_frequence_methodo')
          ->from('BibFrequencesMethodo')
          ->fetchArray();
        return $query;
    }
}