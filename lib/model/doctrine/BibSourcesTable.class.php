<?php


class BibSourcesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('BibSources');
    }
    public static function listSourcesGroupes()
    {
        
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "(SELECT DISTINCT groupe FROM synthese.bib_sources WHERE actif = true)";
        $query = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
        return $query;
    }
    public static function listActiveSources()
    {
        $query= Doctrine_Query::create()
            ->select('id_source, nom_source, url, target, picto, groupe, actif' )
            ->from('BibSources')
            ->where('actif = true')
            ->orderBy('groupe')
            ->fetchArray();
        return $query;
    }
}