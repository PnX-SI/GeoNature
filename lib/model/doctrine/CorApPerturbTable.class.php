<?php


class CorApPerturbTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('CorApPerturb');
    }
    public function getPerturbationsAp($indexap)
    {
        $perturbations = Doctrine_Query::create()
          ->select('codeper')
          ->from('CorApPerturb')
          ->where('indexap=?', $indexap)
          ->fetchArray();
        return $perturbations;
    }
}