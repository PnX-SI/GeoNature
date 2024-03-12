describe('Tests gn_synthese', () => {
  beforeEach(() => {
    cy.geonatureLogin();
    cy.visit("/#/synthese")
  });

  afterEach(() => {
    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.get('[data-qa="synthese-refresh-btn"]').click();
  });

  it('Should search by taxa name', function () {

    // objectifs : pouvoir rentrer un nom d'espèce dans le filtre, que cela affiche le ou les observations sur la liste correspondant à ce nom
    cy.get('#taxonInput').clear();
    cy.get('#taxonInput').type('lynx');
    cy.get('ngb-typeahead-window button').first().click({ force: true });

    cy.get('[data-qa="synthese-search-btn"]').click();

    cy.wait(500);
    const cells = cy.get('.synthese-list-col-nom_vern_or_lb_nom');
    cells.then((d) => {
      expect(d.length).to.greaterThan(0);
    });
    cells.each(($el, index, $list) => {
      cy.wrap($el).contains('Lynx');
    });
  });

  it('Should search by date', function () {
    // objectifs : pouvoir changer les dates des filtres, que cela affiche le ou les obs dans la liste d'observations dans la plage de dates donnée


    cy.intercept(Cypress.env('apiEndpoint') + 'synthese/for_web?**', (req => {
      if (req.body.hasOwnProperty('date_min')) {
        req.alias = 'filteredByDate'
      }
    }))

    // select datemin
    cy.get('[data-qa="synthese-form-date-min"]').click();
    cy.get('[aria-label="Select year"]').select('2016');
    cy.get('[aria-label="Select month"]').select('Dec');
    cy.get('[aria-label="Saturday, December 24, 2016"]').click();
    // select datemax
    cy.get('[data-qa="synthese-form-date-max"]').click();
    cy.get('[aria-label="Select year"]').select('2017');
    cy.get('[aria-label="Select month"]').select('Jan');
    cy.get('[aria-label="Monday, January 2, 2017"]').click();

    // search
    cy.get('[data-qa="synthese-search-btn"]').click();

    cy.wait('@filteredByDate').then(() => {
      // get datatable cells containing the observater info
      const cells = cy.get('.synthese-list-col-date_min');
      cells.then((d) => {
        expect(d.length).to.greaterThan(0);
      });
      cells.each(($el, index, $list) => {
        var [day, month, year] = $el.text().split("-");
        const date = new Date(year, month -1, day);
        expect(date).to.be.greaterThan(new Date('2016-12-24'));
        expect(date).to.be.lessThan(new Date('2017-01-02'));
      });
    })
  });

  it('Should search by observer', function () {
    //objectifs : pouvoir entrer un nom d'observateur (ici Admin);
    // cliquer sur rechercher et vérifier que les observations retournées ont bien pour observateur des personnes contenant 'Admin'
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').clear();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').type('Admin');
    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.wait(500);
    // get datatable cells containing the observater info
    const cells = cy.get('.synthese-list-col-observers');
    cells.then((d) => {
      expect(d.length).to.greaterThan(0);
    });
    cells.each(($el, index, $list) => {
      cy.wrap($el).contains('Administrateur test');
    });
  });

  it('Should search with a new filter', function () {
    //objectifs : pouvoir ajouter un nouveau filtre, (assert que nouveau filtre est bon)
    // pouvoir sélectionner une valeur dans ce nouveau champ
    // pouvoir afficher les observations comportant la valeur du champ sélectionné. ici le sexe (femelle) qu'on selectionne à partir du cd_nomenclature (2)
    cy.get('pnx-dynamic-form-generator > :nth-child(1) > .input-group > .form-control').select(
      'Sexe'
    );
    cy.get(
      '.ng-star-inserted > .auto > .ng-select-container > .ng-value-container > .ng-input > input'
    ).click();
    // get element from its cd_nomenclature (2)
    cy.get('[data-qa="2"]').click();
    cy.get('[data-qa="synthese-search-btn"]').click();

    cy.get('[data-qa="synthese-info-btn"').first().click();
    cy.get('[data-qa="synthese-info-obs-sexe-value"]').contains('Femelle');
    cy.get('[data-qa="synthese-info-obs-close-btn"]').click();
  });

  it('Should search by acquisition framework and dataset', () => {
    
    // ce test permet de faire une suite d'actions basées sur la sélection des CA et des JDD
    // vérifie que la sélection d'un cadre d'acquisition filtre bien les jeux de données
    // objectifs : pouvoir sélectionnner un jeu de données dans la liste déroulante,
    cy.get('[data-qa="synthese-form-ca"] ng-select').click();
    // Intercept request to datasets which must have a parameter to "id_acquisition_framework"
    cy.intercept(Cypress.env('apiEndpoint') + 'meta/datasets?**', (req => {
      if (req.body.hasOwnProperty('id_acquisition_frameworks')) {
        req.alias = 'filteredDatasets'
      }
    }))
    // select a CA without dataset and check JDD 1 is not in list
    cy.get('[data-qa="CA-2-empty"]').click()
    // wait for the filtered request
    cy.wait('@filteredDatasets')

    // select CA 1 and check JDD-1 is in list
    cy.get('[data-qa="synthese-form-ca"] ng-select').click();
    cy.get('[data-qa="CA-1"]').click();
    cy.get('[data-qa="synthese-form-dataset"] ng-select').click();
    cy.get('[data-qa="JDD-1"]').click();
    cy.get('[data-qa="synthese-search-btn"]')
      .click()
      .wait(1000)
      .then(() => {
        const resultsCells = cy.get('.synthese-list-col-dataset_name');
        resultsCells.then((d) => {
          expect(d.length).to.greaterThan(0);
        });
        resultsCells.each(($el, index, $list) => {
          expect($el.text().trim()).to.be.equal('JDD-1');
        });
      });
  });

  it('Should open the observation details pop-up and check its content', () => {
    //Objectif : que tout ce qui est dans le "i" fonctionne
    // TODO Note : pour moi la 1ere partie de ce test  est un peu "superflu": on récupère les valeurs sur la liste et on vérifie qu'on a les mêmes valeurs sur la page info.
    cy.get('[data-qa="synthese-info-btn"]').first().click();
    // l'observateur est doit être rempli
    cy.get('[data-qa="synthese-info-obs-observateur"]').invoke('text').should('not.equal', '');
    // le date est présente est présent et correspond à celle de l'observation sur la liste
    cy.get('[data-qa="synthese-info-obs-date"]').invoke('text').should('not.equal', '');
    // vérification de la présence de l'onglet metadonnées
    cy.get('.mat-mdc-tab').contains('Métadonnées').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-jdd"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="synthese-obs-detail-ca"]').invoke('text').should('not.equal', '');
    // vérification de la présence de l'onglet taxonomie
    cy.get('.mat-mdc-tab').contains('Taxonomie').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-taxo-familly"]').invoke('text').should('not.equal', '');
    // vérification de la présence de l'onglet zonage
    cy.get('.mat-mdc-tab').contains('Zonage').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-area"]');
    // vérification de la présence de l'onglet validation
    cy.get('.mat-mdc-tab').contains('Validation').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-validation-title"]');

    cy.get('[data-qa="synthese-info-obs-close-btn"]').click();
  });

  // TODO: not working but not prioritary
  // it('Should sort the list by columns', async () => {
  //   // Objectif : vérifier qu'on peut bien trier les données dans chaque colonne
  //   let table = await promisify(cy.get(" pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller"))
  //   const tableDate = []
  //   table[0].childNodes.forEach(e => {
  //     if (e.nodeName === "DATATABLE-ROW-WRAPPER") {
  //       tableDate.push(e.innerText.split("\n")[1])
  //     }
  //   })
  //   cy.get('[title="Taxon"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label').click();
  //   // assert : le tri des taxons s'effectue bien --> marche pas
  //   cy.get('[title="Date obs"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label').click();
  //   table = await promisify(cy.get("[data-qa='pnx-synthese'] > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller"))
  //   const tableDateReorder = []
  //   table[0].childNodes.forEach(e => {
  //     if (e.nodeName === "DATATABLE-ROW-WRAPPER") {
  //       tableDateReorder.push(e.innerText.split("\n")[1])
  //     }
  //   })
  //   expect(JSON.stringify(tableDate) === JSON.stringify(tableDateReorder)).to.equals(false)
  //   // assert : le tri par date s'effectue bien
  //   cy.get('[title="JDD"] > .datatable-header-cell-template-wrap > .datatable-icon-sort-unset').click();
  //   // assert : le tri par jeux de données s'effectue bien --> pas testé
  //   cy.get('[title="observateur"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label').click();
  //   // assert : le tri par observateur s'effectue bien --> pas testé
  // });

  it('Should download data at the csv format', function () {
    cy.intercept('POST', '/synthese/export_observations?export_format=csv**').as('exportCall');

    cy.get('[data-qa="synthese-download-btn"]').click();
    cy.get('[data-qa="download-csv"]').click({
      force: true,
    });
    cy.get('[data-qa="synthese-download-close-btn"]').click();

    cy.wait('@exportCall').then((interception) => {
      expect(interception.response.statusCode).to.be.equal(200);
    });
  });
});
