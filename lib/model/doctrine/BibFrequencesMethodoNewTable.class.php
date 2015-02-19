<?php


class BibFrequencesMethodoNewTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibFrequencesMethodoNew');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('id_frequence_methodo_new, nom_frequence_methodo_new')
          ->from('BibFrequencesMethodoNew')
          ->fetchArray();
        return $query;
    }
}