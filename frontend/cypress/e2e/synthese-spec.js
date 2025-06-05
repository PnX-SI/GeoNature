describe('Tests gn_synthese', () => {
  beforeEach(() => {
    cy.geonatureLogin();
    cy.visit('/#/synthese');
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
    cy.get('.synthese-list-col-nom_vern_or_lb_nom').as('cells');
    cy.get('@cells').then((d) => {
      expect(d.length).to.greaterThan(0);
    });
    cy.get('@cells').each(($el, index, $list) => {
      cy.wrap($el).contains('Lynx');
    });
  });

  it('Should search by date', function () {
    // objectifs : pouvoir changer les dates des filtres, que cela affiche le ou les obs dans la liste d'observations dans la plage de dates donnée

    cy.intercept(Cypress.env('apiEndpoint') + 'synthese/for_web?**', (req) => {
      if (req.body.hasOwnProperty('date_min')) {
        cy.get('.synthese-list-col-date_min').as('cells');
        cy.get('@cells').then((d) => {
          expect(d.length).to.greaterThan(0);
        });
        cy.get('@cells').each(($el, index, $list) => {
          var [day, month, year] = $el.text().split('-');
          const date = new Date(year, month - 1, day);
          expect(date).to.be.greaterThan(new Date('2016-12-24'));
          expect(date).to.be.lessThan(new Date('2017-01-02'));
        });
      }
    });

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
  });

  it('Should search by observer', function () {
    //objectifs : pouvoir entrer un nom d'observateur (ici Admin);
    // cliquer sur rechercher et vérifier que les observations retournées ont bien pour observateur des personnes contenant 'Admin'
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').clear();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').type('Admin');
    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.wait(500);
    // get datatable cells containing the observater info
    cy.get('.synthese-list-col-observers').as('cells');
    cy.get('@cells').then((d) => {
      expect(d.length).to.greaterThan(0);
    });
    cy.get('@cells').each(($el, index, $list) => {
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

    // --- Open CA Menu, select CA 1 and check JDD-1 is in list ---
    cy.get('[data-qa="synthese-form-ca"] ng-select').click();
    cy.get('[data-qa="CA-1"]').click();
    cy.get('[data-qa="synthese-form-dataset"] ng-select').click();
    cy.get('[data-qa="JDD-1"]').click();
    cy.get('[data-qa="synthese-search-btn"]')
      .click()
      .wait(500)
      .then(() => {
        const resultsCells = cy.get('.synthese-list-col-dataset_name');
        resultsCells.then((d) => {
          expect(d.length).to.greaterThan(0);
        });
        resultsCells.each(($el, index, $list) => {
          expect($el.text().trim()).to.be.equal('JDD-1');
        });
      });
    // --- Select a CA without dataset and check JDD 1 is not in list ---
    // Reset filters
    cy.get('[data-qa="synthese-form-ca"] ng-select .ng-clear-wrapper').click();
    cy.get('[data-qa="synthese-form-dataset"] ng-select .ng-clear-wrapper').click();
    // Select CA 2
    cy.get('[data-qa="synthese-form-ca"] ng-select').click();
    cy.get('[data-qa="CA-2-empty"]').click();
    cy.get('[data-qa="synthese-form-dataset"] ng-select').click();
    const options = cy.get(
      '[data-qa="synthese-form-dataset"] ng-select ng-dropdown-panel .ng-option'
    );
    // Ensure there is not dataset with CA 2 Empty
    options.then((d) => {
      expect(d.length).to.be.equal(1);
      expect(d[0].textContent).to.be.equal('No items found');
    });
    cy.get('[data-qa="synthese-search-btn"]')
      .click()
      .wait(500)
      .then(() => {
        const result = cy.get('datatable-selection');
        result.then((d) => {
          expect(d[0].children.length).to.equal(1);
          expect(d[0].children[0].textContent).to.be.equal('No data to display');
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
    cy.get('[data-qa="taxonomy-detail-taxo-classe"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-ordre"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-famille"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-cd_nom"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-lb_nom"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-cd_ref"]').invoke('text').should('not.equal', '');
    cy.get('[data-qa="taxonomy-detail-taxo-nom_cite"]').invoke('text').should('not.equal', '');

    // vérification de la présence de l'onglet zonage
    cy.get('.mat-mdc-tab').contains('Zonage').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-area"]');
    // vérification de la présence de l'onglet validation
    cy.get('.mat-mdc-tab').contains('Validation').click({ force: true });
    cy.get('[data-qa="synthese-obs-detail-validation-title"]');

    cy.get('[data-qa="synthese-info-obs-close-btn"]').click();
  });

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

  it('Should display the mesh mode and its selection should spotlight multiple results in list', function () {
    // Togle mesh view
    cy.get('.custom-control-label').click();
    // Leaflet mesh legend should exists
    cy.get('.info.legend.leaflet-control strong')
      .should('exist')
      .should('contains.text', 'observations');

    // Ensure mesh view on map is working as well as the popup
    cy.get('.leaflet-overlay-pane > .leaflet-zoom-animated').click();
    // Popup should contains 4 observations
    cy.get('.leaflet-popup-content-wrapper .leaflet-popup-content').should(
      'contains.text',
      'observation(s)'
    );
    // When popup is opened, the list should spotlight the observations
    cy.get('.datatable-body-row').each(($el) => {
      cy.wrap($el).should('have.attr', 'ng-reflect-is-selected', 'true');
    });
    // When popup is closed, the list should continue to spotlight the observations
    cy.get('.leaflet-popup-close-button').click();
    cy.get('.leaflet-popup-content-wrapper .leaflet-popup-content').should('not.exist');
    cy.get('.datatable-body-row').each(($el) => {
      cy.wrap($el).should('have.attr', 'ng-reflect-is-selected', 'true');
    });
  });

  it('Should refresh the search when mesh mode is toggled', function () {
    // Ensure there is ocntent display on start
    cy.get('.datatable-body-cell-label').should('have.length.greaterThan', 2);
    // Select filter that has no result associated
    cy.get('[data-qa="synthese-form-ca"] ng-select').click();
    cy.get('[data-qa="CA-2-empty"]').click();
    // Togle mesh view
    cy.get('.custom-control-label').click();
    // Check if the table is empty
    cy.get('.datatable-body-cell-label').should('have.length', 0);
  });

  it('Should sort the list by columns', function () {
    // Clicking on the column "Name" should sort the list by name/ Last element is now 'Lynx boréal'
    cy.get(
      '[title="Taxon"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      ':nth-child(1) > .clickable > .datatable-row-center > .synthese-list-col-nom_vern_or_lb_nom > .datatable-body-cell-label > span.ng-star-inserted > div.ng-star-inserted > .mat-mdc-tooltip-trigger'
    ).should('have.text', 'Ablette');
    // Clicking again on the column "Name" should sort the list by name in reverse order/ Last element is now 'Ablette'
    cy.get(
      '.sort-active > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      ':nth-child(4) > .clickable > .datatable-row-center > .synthese-list-col-nom_vern_or_lb_nom > .datatable-body-cell-label > span.ng-star-inserted > div.ng-star-inserted > .mat-mdc-tooltip-trigger'
    ).should('have.text', 'Lynx boréal');
    // When clicking on the column "Date obs", the first element should be '01-01-2017'
    cy.get(
      ':nth-child(1) > .clickable > .datatable-row-center > .synthese-list-col-date_min > .datatable-body-cell-label > span.ng-star-inserted > .ng-star-inserted'
    ).should('have.text', ' 01-01-2017 ');
    cy.get(
      '[title="Date obs"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      '.datatable-header-cell.sort-asc > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      '[title="Date obs"] > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      ':nth-child(1) > .clickable > .datatable-row-center > .synthese-list-col-date_min > .datatable-body-cell-label > span.ng-star-inserted > .ng-star-inserted'
    ).should('have.text', ' 08-01-2017 ');
    // The column JDD should also be able to be sorted
    cy.get(
      '[title="JDD"] > .datatable-header-cell-template-wrap > .datatable-icon-sort-unset'
    ).click();
    cy.get(
      ':nth-child(1) > .clickable > .datatable-row-center > .synthese-list-col-dataset_name'
    ).should('have.text', 'JDD-1');
    cy.get(
      '.sort-active > .datatable-header-cell-template-wrap > .datatable-header-cell-wrapper > .datatable-header-cell-label'
    ).click();
    cy.get(
      ':nth-child(1) > .clickable > .datatable-row-center > .synthese-list-col-dataset_name'
    ).should('have.text', 'JDD-Occtax-ds');
  });

  it('Should be able to hide popup when entering <esc> key', function () {
    // Open the observation details popup
    cy.get('[data-qa="synthese-info-btn"]').first().click();
    cy.get('.my-3').should('have.text', " Information sur l'observation ");
    // Press escape key
    cy.get('.my-3').type('{esc}');
    // Check if the popup is closed
    cy.get('.my-3').should('not.exist');
  });

  it('Should have multiple pages and navigate between them', function () {
    cy.get('.page-count').should('have.text', ' 0 selected /  44 total ');
    // Go to the last page
    cy.get('.datatable-icon-skip').click();
    // Go to previous page
    cy.get('.datatable-icon-left').click();
    // Go to first page
    cy.get('.datatable-icon-prev').click();
    // Go the next page
    cy.get('.datatable-icon-right').click();

    // Filtering the data should reset the page to 1 and remove page buttons
    cy.get('[data-qa="taxonomy-form-input"]').type('Grenouille');
    cy.get('#ngb-typeahead-0-0 > .ng-star-inserted').click();
    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.get('.datatable-icon-skip').should('be.hidden');
    cy.get('.datatable-icon-left').should('be.hidden');
    cy.get('.datatable-icon-prev').should('be.hidden');
    cy.get('.datatable-icon-right').should('be.hidden');

    // Reseting the search should bring back the page buttons
    cy.get('[data-qa="synthese-refresh-btn"]').click();
    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.get('.datatable-icon-skip').should('be.visible');
    cy.get('.datatable-icon-left').should('be.visible');
    cy.get('.datatable-icon-prev').should('be.visible');
    cy.get('.datatable-icon-right').should('be.visible');
  });
});
