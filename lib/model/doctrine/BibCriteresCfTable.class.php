<?php


class BibCriteresCfTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibCriteresCf');
    }

    public static function listAll($groupe = null)
    {
        $query = Doctrine_Query::create()
          ->select('c.id_critere_cf, c.nom_critere_cf, c.tri_cf')
          ->from('BibCriteresCf c')
          ->innerJoin('c.CorCritereGroupe ccg') 
          ->orderBy('c.tri_cf ASC'); 
        if (!is_null($groupe)){$query->addWhere('ccg.id_groupe = ?', $groupe);}
                
        $criteres = $query->fetchArray();
       
        return $criteres;
    }
}