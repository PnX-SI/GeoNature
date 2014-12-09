<?php


class BibProgrammesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibProgrammes');
    }
    public static function listProgrammes()
    {
        $query = Doctrine_Query::create()
          ->select('id_programme, nom_programme, desc_programme')
          ->from('BibProgrammes')                  
          ->orderBy('nom_programme ASC');               
        $programmes = $query->fetchArray();
        return $programmes;
    }
}