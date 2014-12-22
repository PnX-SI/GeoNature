<?php
class bibsActions extends sfFauneActions
{

    //---------------- SYNTHESE ---------------------------------
    public function executeListAnneesSynthese(sfRequest $request)
    {
        $annees = SynthesefauneTable::listAnnees();
        return $this->renderJSON($annees);
    }
    public function executeListTaxonsSynthese(sfRequest $request)
    {
        $val = BibTaxonsFaunePnTable::listSynthese();
        return $this->renderText($val);
    }
    public function executeListTaxonsTreeSynthese(sfRequest $request)
    {
        $val = BibTaxonsFaunePnTable::listTreeSynthese();
        return $this->renderText(json_encode($val));
    }
    public function executeListCommunes(sfRequest $request)
    {
        $val = LCommunesTable::listAll($request->getParameter('secteur', null));
        return $this->renderJSON($val);
    }
    public function executeListSecteurs(sfRequest $request)
    {
        $val = LSecteursTable::listAll();
        return $this->renderJSON($val);
    }
    public function executeListProtocoles(sfRequest $request)
    {
        $val = TProtocolesTable::listAll();
        return $this->renderJSON($val);
    }
    public function executeListProgrammes(sfRequest $request)
    {
        $val = BibProgrammesTable::listProgrammes();
        return $this->renderJSON($val);
    }
    public function executeListReserves(sfRequest $request)
    {
        $val = LZonesstatutTable::listReserves();
        return $this->renderJSON($val);
    }
    public function executeListN2000(sfRequest $request)
    {
        $val = LZonesstatutTable::listN2000();
        return $this->renderJSON($val);
    }
    
    //---------------- CONTACT FAUNE ---------------------------------
    public function executeListObservateursCfAdd(sfRequest $request)
    {
        $val = TRolesTable::listObservateursCfAdd();
        return $this->renderText(json_encode($val));
    }
    
    public function executeListTaxonsCf(sfRequest $request)
    {
        $val = BibTaxonsFaunePnTable::listCf();
        return $this->renderText(json_encode($val));
    }

    public function executeListTaxonsCfu(sfRequest $request)
    {
        $srid_loc = sfGeonatureConfig::$srid_local;
        $point = $request->getParameter('point');
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT DISTINCT id_unite_geo
                FROM layers.l_unites_geo
                WHERE ST_intersects(the_geom,ST_transform(st_setsrid(ST_GeomFromText('$point',3857),3857),".$srid_loc."))";
        $array_unite = $dbh->query($sql);
        foreach($array_unite as $val){
            $id_unite_geo = $val['id_unite_geo'];
        }
        if($id_unite_geo!=null){
        $val = BibTaxonsFaunePnTable::listCfUnite($id_unite_geo);}
        else{$val = BibTaxonsFaunePnTable::listCf();}
        // print_r(json_encode($val));
        return $this->renderText(json_encode($val));
    }
    
    public function executeListCritereCf(sfRequest $request)
    {
        $val = BibCriteresCfTable::listAll($request->getParameter('id_classe'));
        return $this->renderText(json_encode($val));
    }
   
    
    //---------------- CONTACT INVERTEBRE ---------------------------------
    public function executeListObservateursInvAdd(sfRequest $request)
    {
        $val = TRolesTable::listObservateursInvAdd();
        return $this->renderText(json_encode($val));
    }
    public function executeListMilieuxInv(sfRequest $request)
    {
        $val = BibMilieuxInvTable::listMilieuxInv();
        return $this->renderText(json_encode($val));
    }
    
    public function executeListTaxonsInv(sfRequest $request)
    {
        $val = BibTaxonsFaunePnTable::listInv();
        return $this->renderText(json_encode($val));
    }

    public function executeListTaxonsInvu(sfRequest $request)
    {
        $srid_loc = sfGeonatureConfig::$srid_local;
        $point = $request->getParameter('point');
        $dbh = Doctrine_Manager::getInstance()->getCurrentConnection()->getDbh();
        $sql = "SELECT DISTINCT id_unite_geo
                FROM layers.l_unites_geo
                WHERE ST_intersects(the_geom,ST_transform(st_setsrid(ST_GeomFromText('$point',3857),3857),".$srid_loc."))";
        $array_unite = $dbh->query($sql);
        foreach($array_unite as $val){
            $id_unite_geo = $val['id_unite_geo'];
        }
        if($id_unite_geo!=null){
        $val = BibTaxonsFaunePnTable::listInvUnite($id_unite_geo);}
        else{$val = BibTaxonsFaunePnTable::listInv();}
        // print_r(json_encode($val));
        return $this->renderText(json_encode($val));
    }

    public function executeListCritereInv(sfRequest $request)
    {
        $val = BibCriteresInvTable::listAll();
        return $this->renderText(json_encode($val));
    }
}
