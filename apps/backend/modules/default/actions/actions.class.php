<?php
class defaultActions extends sfFauneActions
{
        public function preExecute()
    {
        //sfLoader::loadHelpers('Partial');
    }
    
    public function executeSecure(sfRequest $request)
    {
        //symfony appelle directement cette action s'il y a un pb de credential
        return sfView::SUCCESS; //voir le template secureSuccess du module home
    }
    
        public function executeLogin(sfRequest $request)
    {
        //action executé par defaut par symfony quand les credential ne sont pas bons pour la page index ou indexPda
        $this->redirect('@login');   
    }
}
