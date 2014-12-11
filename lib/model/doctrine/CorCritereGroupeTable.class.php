<?php


class CorCritereGroupeTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('CorCritereGroupe');
    }
}