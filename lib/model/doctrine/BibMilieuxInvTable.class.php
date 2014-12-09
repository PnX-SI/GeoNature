<?php


class BibMilieuxInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibMilieuxInv');
    }
    public static function listMilieuxInv()
    {
        $query = Doctrine_Query::create()
          ->select('id_milieu_inv, nom_milieu_inv')
          ->from('BibMilieuxInv')         
          ->orderBy('id_milieu_inv ASC');               
        $milieux = $query->fetchArray();
        return $milieux;
    }
}