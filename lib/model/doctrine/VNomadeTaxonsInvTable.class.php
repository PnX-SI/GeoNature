<?php


class VNomadeTaxonsInvTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('VNomadeTaxonsInv');
    }
}