<?php


class BibProgrammesFsTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibProgrammesFs');
    }
    public static function listProgrammeFs()
    {
        $query = Doctrine_Query::create()
          ->select('id_programme_fs, nom_programme_fs')
          ->from('BibProgrammesFs')
          ->fetchArray();
        return $query;
    }
}