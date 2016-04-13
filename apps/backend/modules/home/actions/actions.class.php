<?php
class homeActions extends sfGeonatureActions
{
    public function preExecute()
    {
        sfContext::getInstance()->getConfiguration()->loadHelpers('Partial');
    }
  
    public function executeLogin(sfRequest $request)
    {
        slot('title', sfGeonatureConfig::$appname_main);
        //affichage du formulaire
        $this->form = new LoginForm();
        
        if ($request->isMethod('post')) //sinon (premier accès à la page) tout ce bloc n'est pas executé et on  ne fait que affiché le formulaire
        {
            $this->form->bind($request->getParameter('login'));
            if ($this->form->isValid())
            {
                //traitement du formulaire --> récupération des valeurs concernant l'utilisateur, disponible dans toute l'application
                $params = $request->getParameter('login');
                $u = fauneUsers::retrieve($params['login']);
                foreach ($u as $key => &$val){
                    $nom = $val['nom_role'];
                    $prenom = $val['prenom_role'];
                    $id_role = $val['id_role'];
                    $id_secteur = $val['id_unite'];
                    $id_organisme = $val['id_organisme'];
                    $nom_secteur = $val['nom_unite'];
                    $email = $val['email'];
                }
                
                $user = $this->getUser();
                $user->setAuthenticated(true);
                $id_droit_user = fauneUsers::getDroitsUser($id_role);
                $user->addCredential(fauneUsers::$status[$id_droit_user]);
                $user->setAttribute('statuscode', $id_droit_user);
                $user->setAttribute('nom', $nom .' '.$prenom);
                $user->setAttribute('userPrenom', $prenom);
                $user->setAttribute('userNom', $nom);
                $user->setAttribute('id', $id_role);
                $user->setAttribute('id_secteur', $id_secteur);
                $user->setAttribute('id_organisme', $id_organisme);
                $user->setAttribute('nom_secteur', $nom_secteur);
                $user->setAttribute('email', $email);
                $user->setAttribute('identifiant',$params['login']);
                $user->setAttribute('pass',$params['password']);
                //traitement des modules d'export
                $user->setAttribute('can_export',false);
                $exports = [];//liste des vues des modules d'export à afficher
                foreach (sfGeonatureConfig::$exports_config as $export)
                {
                    if(in_array($id_role,$export['authorized_roles_ids'])){
                        $user->setAttribute('can_export',true);
                        array_push($exports,$export);
                    }
                    $user->setAttribute('user_exports',$exports);
                }
                $this->redirect('@homepage');
            }
        }
    }
    
    public function executeLogout()
    {
      	$user = $this->getUser();
      	$user->setAuthenticated(false);
      	$user->clearCredentials();
      	$user->setAttribute('statuscode', 0);
        $user->setAttribute('can_export',false);
        $this->redirect('@login');
    }
    
    public function executeIndex(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_main);
            // construction dynamique de la liste des liens vers les formulaires
            $groupes = BibSourcesTable::listSourcesGroupes();
            $sources = BibSourcesTable::listActiveSources();
            $this->statuscode = $this->getUser()->getAttribute('statuscode');
            $this->lien_saisie = '';
            $this->actives_sources = [];
            foreach ($groupes as $groupe)
            {  
                $group = $groupe['groupe'];
                $this->liens_saisie .= '<div class="groupe"><h3 class="panel-title">'.$group.'</h3>';
                foreach ($sources as $source)
                {  
                    $source_group = $source['groupe'];
                    $url = $source['url'];
                    $target = $source['target'];
                    $picto = $source['picto'];
                    $nom_source = $source['nom_source'];
                    array_push($this->actives_sources, $source['id_source']);
                    if($source_group == $group)
                    {
                        $this->lien_saisie = '';
                        $this->lien_saisie .= '<p class="ligne_lien"><a class="btn btn-default" href="'.$url.'" target="'.$target.'" ><img src="'.$picto.'" border="0"> '.$nom_source.'</a></p>';
                        $this->liens_saisie .= $this->lien_saisie;
                    }
                }
                $this->liens_saisie .= '</div>';
            }
            //construction dynamique des liens d'export des données pour les id_roles présent dans la configuration lib/sfGeonatureConif.php
            //pour que ces liens s'affichent, l'id-role de l'utilisateur logué doit être présent dans au moins un des tableaux 'authorized_roles_ids' de la variable $exports_config
            if($this->getUser()->getAttribute('can_export')){
                $this->lien_export = '<h2>EXPORTS</h2>';
                $this->lien_export .= '<p>Permet d\'accéder aux pages offrant des liens d\'export prédéfinis des données de la synthèse.</p>';
                $userexports = $this->getUser()->getAttribute('user_exports');
                foreach ($userexports as $userexport)
                {
                    $serializeuserexport = serialize($userexport);
                    $this->lien_export .= '<p class="ligne_lien"><a class="btn btn-default" href="export/'.urlencode($serializeuserexport).'" target="_blank" ><img src="images/exporter.png" border="0"> '.$userexport['exportname'].'</a></p>';
                }
            }
        }
        else{
           $this->redirect('@login');
       }
    }
    
    public function executeIndexSynthese(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_synthese);
        }
        else{
           $this->redirect('@login');
        }
    }
    
    public function executeIndexExport(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $unserializeviewparams = unserialize($request->getParameter('exportparams'));
            $this->title = $unserializeviewparams['exportname'].' - '.sfGeonatureConfig::$appname_export;
            slot('title', $this->title);
            $this->lienscsv = '';
            $views = $unserializeviewparams['views'];
            foreach($views as $view)
            {
                $pgview = $view['pgschema'].'.'.$view['pgview'];
                $rows = SyntheseffTable::exportsCountRowsView($pgview);
                $nb = $rows[0]['nb'];
                $this->lienscsv .= '<p class="ligne_lien"><a href="../export/exportview?pgschema='.$view['pgschema'].'&pgview='.$view['pgview'].'&fileformat='.$view['fileformat'].'" class="btn btn-default"><img src="../images/exporter.png">'.$view['buttonviewtitle'].' ('.$nb.')</a> '.$view['viewdesc'].'</p>';
            }
        }
        else{
           $this->redirect('@login');
        }
    }
    
    public function executeIndexCf(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_cf);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexCflore(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_cflore);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexMortalite(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_mortalite);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexInvertebre(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_inv);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexFs(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_florestation);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexBryo(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_bryo);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexFp(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_florepatri);
        }
        else{
            $this->redirect('@login');
        }
    }
    
    public function executeIndexReseau(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $this->identifiant = $this->getUser()->getAttribute('identifiant');
            $this->pass = $this->getUser()->getAttribute('pass');
        }
        else{
            $this->redirect('@login');
        }
    }
        
    public function executeGetStatus(sfRequest $request)
    {
      	$credentials = $this->getUser()->getCredentials();
      	return $this->renderJSON(array(
          	 'status' => array_shift($credentials),
          	 'statuscode' => $this->getUser()->getAttribute('statuscode'),
          	 'id_role' => $this->getUser()->getAttribute('id'),
             'id_utilisateur' => $this->getUser()->getAttribute('id'),
          	 'nom' => $this->getUser()->getAttribute('nom'),
          	 'userPrenom' => $this->getUser()->getAttribute('userPrenom'),
          	 'userNom' => $this->getUser()->getAttribute('userNom'),
             'email' => $this->getUser()->getAttribute('email'),
             'id_secteur' => $this->getUser()->getAttribute('id_secteur'),
             'id_organisme' => $this->getUser()->getAttribute('id_organisme'),
             'nom_secteur' => $this->getUser()->getAttribute('nom_secteur'),
             'indexzp' => $this->getUser()->getAttribute('indexzp'),
             'id_station' => $this->getUser()->getAttribute('id_station')
      	));
    }
    
    //-----------STAT FAUNE FLORE-----------------

    public function executeDatasNbObsKd(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsKd();  
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxKd(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxKd();  
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsCl(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsCl();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxCl(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxCl();  
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsGp1(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsGp1();
            
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxGp1(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxGp1();
            
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsGp2(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsGp2();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxGp2(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxGp2();
            return $this->renderJSON($datas);
        }
    }
    
    public function executeDatasNbObsOrganisme(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsOrganisme();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsYear(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsYear();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxYear(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxYear();
            return $this->renderJSON($datas);
        }
    }
    
    public function executeDatasNbObsProgramme(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsProgramme();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbTxProgramme(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbTxProgramme();
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsCf(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsCf();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsMortalite(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsMortalite();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsInv(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsInv();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsCflore(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsCflore();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsFs(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsFs();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsFp(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsFp();
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsBryo(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  SyntheseffTable::getDatasNbObsBryo();
            return $this->renderJSON($datas_tout);
        }
    }

}
