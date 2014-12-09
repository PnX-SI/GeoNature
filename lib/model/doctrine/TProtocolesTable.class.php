<?php


class TProtocolesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TProtocoles');
    }
    public static function listAll()
    {
        $query= Doctrine_Query::create()
            ->select('p.id_protocole, p.nom_protocole' )
            ->from('TProtocoles p')
            ->orderBy('p.nom_protocole')
            ->fetchArray();
        return $query;
    }
}