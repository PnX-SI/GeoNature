<?php
class fauneUsers extends sfGeonatureActions
{
    public static  $status = array(
        0 => 'aucun droit',
        1 => 'utilisateur',
        2 => 'redacteur',
        3 => 'referent',
        6 => 'administrateur' 
    );
    
    public static function identify($login, $pass)
    {
        $nb_role=Doctrine_Query::create()
            ->from('TRoles')
            ->where('identifiant=? AND pass=?', array($login, $pass))
            ->count(); 
        if ($nb_role>0) {return true;}
        return false; //la fonction s'arrete au premier return rencontré
    }
    
    public static function getIdentity($id)
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT prenom_role || ' ' || nom_role as user FROM utilisateurs.t_roles WHERE id_role =".$id;
        $result = $dbh->query($sql);
        foreach ($result as $val){
            $nom_user = $val['user'];
        }
        return $nom_user;
    }
    
    public static function retrieve($login)
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT r.*, u.nom_unite FROM utilisateurs.t_roles r ".
                "LEFT JOIN utilisateurs.bib_unites u ON u.id_unite = r.id_unite ".
                "WHERE identifiant = '$login' LIMIT 1";
        $result = $dbh->query($sql)->fetchAll(PDO::FETCH_ASSOC);
        return $result;
    }
    
    public static function getDroitsUser($id_role)
    {
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT COALESCE(max(a.id_droit),0) as id_droit
                FROM (
                    (SELECT c.id_droit
                    FROM utilisateurs.t_roles u
                    JOIN utilisateurs.cor_role_droit_application c ON c.id_role = u.id_role
                    WHERE u.id_role = $id_role AND c.id_application = ".sfGeonatureConfig::$id_application.")
                    union
                    (SELECT c.id_droit
                    FROM utilisateurs.t_roles u
                    JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
                    JOIN utilisateurs.cor_role_droit_application c ON c.id_role = g.id_role_groupe
                    WHERE u.id_role = $id_role AND c.id_application = ".sfGeonatureConfig::$id_application.")
                ) as a";
        $array_droit = $dbh->query($sql);
        foreach($array_droit as $val){
            $id_droit = $val['id_droit'];
        }
        return $id_droit;
    }
    
    
    /**
    * Retourne le chemin de stockage des images
    */
    public function getImagesDir()
    {
      // return sfConfig::get('sf_web_dir')."/images";
      return sfConfig::get('sf_web_dir')."/images";
    }
      
    /**
    * Retourne le chemin de stockage des fichiers
    */
    public function getFilesDir()
    {
      return sfConfig::get('sf_web_dir')."/fichiers";
    }
}