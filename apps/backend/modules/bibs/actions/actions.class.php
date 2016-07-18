<?php
class bibsActions extends sfGeonatureActions
{
    //----------------TOUT ---------------------------------
    public function executeListCommunesSaisie(sfRequest $request)
    {
        $val = LCommunesTable::listAllSaisie($request->getParameter('secteur', null));
        return $this->renderJSON($val);
    }
    //---------------- SYNTHESE ---------------------------------
    public function executeListAnneesSynthese(sfRequest $request)
    {
        $annees = SyntheseffTable::listAnnees();
        return $this->renderJSON($annees);
    }
    public function executeListTaxonsSyntheseFr(sfRequest $request)
    {
        $val = BibNomsTable::listSyntheseFr($request->getParameter('fff'),$request->getParameter('patri'),$request->getParameter('protege'));
        return $this->renderText($val);
    }
    public function executeListTaxonsSyntheseLatin(sfRequest $request)
    {
        $val = BibNomsTable::listSyntheseLatin($request->getParameter('fff'),$request->getParameter('patri'),$request->getParameter('protege'));
        return $this->renderText($val);
    }
    public function executeListTaxonsTreeSynthese(sfRequest $request)
    {
        $val = BibNomsTable::listTreeSynthese(null,null,null);
        return $this->renderText(json_encode($val));
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
    
    //---------------- FLORE -----------------------------------------
    
    public function executeListObservateursFlore(sfRequest $request)
    {
        $auteurs = TRolesTable::listObservateursFlore();
        return $this->renderText(json_encode($auteurs));
    }
    public function executeListOrganismes(sfRequest $request)
    {
        $o = BibOrganismesTable::listAll();
        return $this->renderJSON($o);
    }
    
    
    //---------------- FLORE STATION ---------------------------------
    
    public function executeFiltreObservateursFs(sfRequest $request)
    {
        $auteurs = TRolesTable::filtreObservateursFs();
        return $this->renderText(json_encode($auteurs));
    }
    public function executeListProgrammeFs(sfRequest $request)
    {
        $programmes = BibProgrammesFsTable::listProgrammeFs();
        return $this->renderText(json_encode($programmes));
    }
    public function executeListSupports(sfRequest $request)
    {
        $query = BibSupportsTable::listSupports();
        return $this->renderText(json_encode($query));
    }
    public function executeListSurfaces(sfRequest $request)
    {
        $query = BibSurfacesTable::listSurfaces();
        return $this->renderText(json_encode($query));
    }
    public function executeListHomogenes(sfRequest $request)
    {
        $query = BibHomogenesTable::listHomogenes();
        return $this->renderText(json_encode($query));
    }
    public function executeListAbondances(sfRequest $request)
    {
        $query = BibAbondancesTable::listAbondances();
        return $this->renderText(json_encode($query));
    }
    public function executeListSophie(sfRequest $request)
    {
        $query = TStationsFsTable::listSophie();
        return $this->renderText(json_encode($query));
    }
    public function executeListMicroreliefs(sfRequest $request)
    {
        $query = BibMicroreliefsTable::listMicroreliefs();
        return $this->renderText(json_encode($query));
    }
    public function executeListExpositions(sfRequest $request)
    {
        $query = BibExpositionsTable::listExpositions();
        return $this->renderText(json_encode($query));
    }
    public function executeFiltreTaxonOrigineFs()
    {
        $taxons = TaxrefTable::filtreTaxonOrigineFs();
        return $this->renderJSON($taxons);
    }
    public function executeFiltreTaxonReferenceFs()
    {
        $taxons = TaxrefTable::filtreTaxonReferenceFs();
        return $this->renderJSON($taxons);
    }
    public function executeListAnneeFs(sfRequest $request)
    {
        $annees = TStationsFsTable::listAnneeFs();
        return $this->renderJSON($annees);
    }
    
    //---------------- FLORE PRIORITAIRE -----------------------------
    
    public function executeFiltreObservateursFp(sfRequest $request)
    {
        $auteurs = TRolesTable::filtreObservateursFp();
        return $this->renderText(json_encode($auteurs));
    }
    public function executeListlfp(sfRequest $request)
    {
        $taxons = BibTaxonsFpTable::listlAll();
        return $this->renderJSON($taxons);
    }
    public function executeListffp(sfRequest $request)
    {
        $taxons = BibTaxonsFpTable::listfAll();
        return $this->renderJSON($taxons);
    }
    public function executeListSecteursFp(sfRequest $request)
    {
        $secteurs = LSecteursTable::listAll();
        return $this->renderJSON($secteurs);
    }
     public function executeListPheno(sfRequest $request)
    {
        $phenos = BibPhenologiesTable::listAll();
        return $this->renderJSON($phenos);
    }
    
    public function executeListFrequenceMethodoNew(sfRequest $request)
    {
        $f = BibFrequencesMethodoNewTable::listAll();
        return $this->renderJSON($f);
    }
    
    public function executeListComptageMethodo(sfRequest $request)
    {
        $c = BibComptagesMethodoTable::listAll();
        return $this->renderJSON($c);
    }
    
    public function executeListPhysionomies(sfRequest $request)
    {
        $physionomies = BibPhysionomiesTable::listAll();
        return $this->renderJSON($physionomies);
    }
    
    public function executeListPerturbations(sfRequest $request)
    {
        $perturbations = BibPerturbationsTable::listAll();
        return $this->renderJSON($perturbations);
    }
    public function executeListAnneeFp(sfRequest $request)
    {
        $annees = TZprospectionTable::listAnnee();
        return $this->renderJSON($annees);
    }
    //---------------- FLORE BRYOPHYTES ------------------------------
        
    public function executeFiltreObservateursBryo(sfRequest $request)
    {
        $auteurs = TRolesTable::filtreObservateursBryo();
        return $this->renderText(json_encode($auteurs));
    }
    public function executeListAbondancesBryo(sfRequest $request)
    {
        $query = BibAbondancesBryoTable::listAbondances();
        return $this->renderText(json_encode($query));
    }
    public function executeListExpositionsBryo(sfRequest $request)
    {
        $query = BibExpositionsBryoTable::listExpositions();
        return $this->renderText(json_encode($query));
    }
    public function executeFiltreTaxonOrigineBryo()
    {
        $taxons = TaxrefTable::filtreTaxonOrigineBryo();
        return $this->renderJSON($taxons);
    }
    public function executeFiltreTaxonReferenceBryo()
    {
        $taxons = TaxrefTable::filtreTaxonReferenceBryo();
        return $this->renderJSON($taxons);
    }
    public function executeListSecteursBryo(sfRequest $request)
    {
        $secteurs = LSecteursTable::listValidBryo();
        return $this->renderJSON($secteurs);
    }
    public function executeListAnneeBryo(sfRequest $request)
    {
        $annees = TStationsBryoTable::listAnneeBryo();
        return $this->renderJSON($annees);
    }
    
    //---------------- CONTACT FLORE ---------------------------------
    public function executeListTaxonsCflore(sfRequest $request)
    {
        $val = BibNomsTable::listCflore();
        return $this->renderText(json_encode($val));
    }

    public function executeListTaxonsCfloreu(sfRequest $request)
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
        $val = BibNomsTable::listCfloreUnite($id_unite_geo);}
        else{$val = BibNomsTable::listCflore();}
        
        return $this->renderText(json_encode($val));
    }
    
    public function executeListAbondancesCflore(sfRequest $request)
    {
        $val = BibAbondancesCfloreTable::listAll();
        return $this->renderText(json_encode($val));
    }
    
    public function executeListPhenologiesCflore(sfRequest $request)
    {
        $val = BibPhenologiesCfloreTable::listAll();
        return $this->renderText(json_encode($val));
    }
    
    //---------------- CONTACT FAUNE ---------------------------------
    public function executeListObservateursCfAdd(sfRequest $request)
    {
        $val = TRolesTable::listObservateursCfAdd();
        return $this->renderText(json_encode($val));
    }
    
    public function executeListTaxonsCf(sfRequest $request)
    {
        $val = BibNomsTable::listCf();
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
        $val = BibNomsTable::listCfUnite($id_unite_geo);}
        else{$val = BibNomsTable::listCf();}
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
        $val = BibNomsTable::listInv();
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
        $val = BibNomsTable::listInvUnite($id_unite_geo);}
        else{$val = BibNomsTable::listInv();}
        // print_r(json_encode($val));
        return $this->renderText(json_encode($val));
    }

    public function executeListCritereInv(sfRequest $request)
    {
        $val = BibCriteresInvTable::listAll();
        return $this->renderText(json_encode($val));
    }
}
