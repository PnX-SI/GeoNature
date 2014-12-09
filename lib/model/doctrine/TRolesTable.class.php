<?php


class TRolesTable extends Doctrine_Table
{
    
    public static function getInstance()
    {
        return Doctrine_Core::getTable('TRoles');
    }
       
        public static function listObservateursCfAdd()
        {
            $query_utilisateur= Doctrine_Query::create()
            ->select('r.id_role, concat(r.nom_role, \' \',r.prenom_role) auteur' )
            ->from('TRoles r')
            ->innerJoin('r.CorRoleMenu crm ON crm.id_menu = 9 AND r.id_role=crm.id_role')
            ->where('r.groupe = false')
            ->orderBy('auteur')
            ->fetchArray();
             $query_groupe= Doctrine_Query::create()
            ->select('r.id_role, concat(r.nom_role, \' \',r.prenom_role) auteur' )
            ->from('TRoles r')
            ->innerJoin('r.CorRoles cr ON cr.id_role_utilisateur = r.id_role')
            ->innerJoin('cr.CorRoleMenu crmg ON crmg.id_menu = 9 AND cr.id_role_groupe=crmg.id_role')
            ->orderBy('auteur')
            ->fetchArray();
            $query=array_merge($query_utilisateur, $query_groupe);
            return $query;
        }
        
        public static function listObservateursInvAdd()
        {
            $query_utilisateur= Doctrine_Query::create()
            ->select('r.id_role, concat(r.nom_role, \' \',r.prenom_role) auteur' )
            ->from('TRoles r')
            ->innerJoin('r.CorRoleMenu crm ON crm.id_menu = 9 AND r.id_role=crm.id_role')
            ->where('r.groupe = false')
            ->orderBy('auteur')
            ->fetchArray();
             $query_groupe= Doctrine_Query::create()
            ->select('r.id_role, concat(r.nom_role, \' \',r.prenom_role) auteur' )
            ->from('TRoles r')
            ->innerJoin('r.CorRoles cr ON cr.id_role_utilisateur = r.id_role')
            ->innerJoin('cr.CorRoleMenu crmg ON crmg.id_menu = 9 AND cr.id_role_groupe=crmg.id_role')
            ->orderBy('auteur')
            ->fetchArray();
            $query=array_merge($query_utilisateur, $query_groupe);
            return $query;
        }
}