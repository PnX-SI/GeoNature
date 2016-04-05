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
                $this->redirect('@homepage');
                // $this->form = new LoginForm();
            }
        }
    }
    
    public function executeLogout()
    {
      	$user = $this->getUser();
      	$user->setAuthenticated(false);
      	$user->clearCredentials();
      	$user->setAttribute('statuscode', 0);
        $this->redirect('@login');
    }
    
    public function executeIndex(sfRequest $request)
    {
      
        if($this->getUser()->isAuthenticated()){
            slot('title', sfGeonatureConfig::$appname_main);
            // construction dynamique de la liste des liens vers les formulaires
            $groupes = BibSourcesTable::listSourcesGroupes();
            $sources = BibSourcesTable::listActiveSources();
            $this->lien_saisie = '';
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
                    if($source_group == $group)
                    {
                        $this->lien_saisie = '';
                        $this->lien_saisie .= '<p class="ligne_lien"><a class="btn btn-default" href="'.$url.'" target="'.$target.'" ><img src="'.$picto.'" border="0"> '.$nom_source.'</a></p>';
                        $this->liens_saisie .= $this->lien_saisie;
                    }
                }
                $this->liens_saisie .= '</div>';
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
            $datas =  SyntheseffTable::getDatasNbObsKd() ;
            
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsCl(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsCl() ;
            
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsYear(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas =  SyntheseffTable::getDatasNbObsYear() ;
            
            return $this->renderJSON($datas);
        }
    }
    public function executeDatasNbObsCf(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  TRelevesCfTable::getDatasNbObsCf() ;
            
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsInv(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  TRelevesInvTable::getDatasNbObsInv() ;
            
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsCflore(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  TRelevesCfloreTable::getDatasNbObsCflore() ;
            
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsFs(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  CorFsTaxonTable::getDatasNbObsFs() ;
            
            return $this->renderJSON($datas_tout);
        }
    }
    public function executeDatasNbObsFp(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $datas_tout =  TApresenceTable::getDatasNbObsFp() ;
            
            return $this->renderJSON($datas_tout);
        }
    }

}
