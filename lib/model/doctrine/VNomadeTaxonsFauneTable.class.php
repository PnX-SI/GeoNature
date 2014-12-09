<?php


class VNomadeTaxonsFauneTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('VNomadeTaxonsFaune');
    }
}