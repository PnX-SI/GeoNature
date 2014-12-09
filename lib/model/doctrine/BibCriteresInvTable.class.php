<?php


class BibCriteresInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibCriteresInv');
    }
    public static function listAll()
    {
        $query = Doctrine_Query::create()
          ->select('c.id_critere_inv, c.nom_critere_inv, c.tri_inv')
          ->from('BibCriteresInv c')
          ->orderBy('c.tri_inv ASC');  
        $criteres = $query->fetchArray();
        return $criteres;
    }
}