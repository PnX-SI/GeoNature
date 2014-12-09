<?php


class CorReleveTaxonTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('CorReleveTaxon');
    }
}