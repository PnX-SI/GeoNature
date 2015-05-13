<?php


class BibCriteresCfTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibCriteresCf');
    }

    public static function listAll($liste = null)
    {
        $query = Doctrine_Query::create()
          ->select('c.id_critere_cf, c.nom_critere_cf, c.tri_cf')
          ->from('BibCriteresCf c')
          ->innerJoin('c.CorCritereListe ccl') 
          ->orderBy('c.tri_cf ASC'); 
        if (!is_null($liste)){$query->addWhere('ccl.id_liste = ?', $liste);}
                
        $criteres = $query->fetchArray();
       
        return $criteres;
    }
}