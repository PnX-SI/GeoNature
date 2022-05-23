import promisify from 'cypress-promise';

NodeList.prototype.forEach = Array.prototype.forEach;

describe("Tests gn_synthese", () => {

  before(() => {
    cy.geonatureLogout()
    cy.geonatureLogin();
      cy.visit("/#/synthese")
    });

  // it("Should display synthese interface", () => {
  //   // check there are elements in the list --> au 13/01/22, ce test n'est pas complet, plus d'éléments testables sur la fenêtre : présence des filtres, de la carte et des listes d'observations
  //   cy.get('datatable-scroller').children('datatable-row-wrapper');
  // });

  it('Should search by taxa name', function () {
    // objectifs : pouvoir rentrer un nom d'espèce dans le filtre, que cela affiche le ou les observations sur la liste correspondant à ce nom
    cy.get('#taxonInput').clear();
    cy.get('#taxonInput').type('lynx');
    cy.get('ngb-typeahead-window button').first().click({ force: true });

    cy.get('.button-success').click();
    cy.wait(500)
    const table = cy.get('datatable-row-wrapper > datatable-body-row')
    table.then(d => {
      expect(d.length).to.greaterThan(0)
      Array.prototype.forEach.call(d, e => {
        expect(e.children[1].children[2].firstChild.innerText).contains('Lynx')
      })
    })
  });

  // it('Should search by date', function () {
  //   // objectifs : pouvoir changer les dates des filtres, que cela affiche le ou les taxons dans la liste d'observations dans la plage de dates donnée 
  //   // (prendre deux ou trois observations et vérifier que la date d'obs soit supérieure à date min et inférieure à date max) 
  //   cy.get(':nth-child(2) > pnx-date > .input-group > .input-group-append > .btn > .fa').click();
  //   cy.get('[aria-label="Select year"]').select('2017');
  //   cy.get('ngb-datepicker-navigation.ng-star-inserted > :nth-child(1) > .btn').click();
  //   cy.get('[aria-label="Saturday, December 24, 2016"] > .btn-light').click();
  //   cy.get(':nth-child(3) > pnx-date > .input-group > .form-control').click();
  //   cy.get('[aria-label="Select year"]').select('2017');
  //   cy.get('[aria-label="Monday, January 2, 2017"] > .btn-light').click();
  //   cy.get('.button-success > .mat-button-wrapper').click();
  //   const table = cy.get('datatable-row-wrapper > datatable-body-row')
  //   table.then(d => {
  //     expect(d.length).to.greaterThan(0)
  //   })
  //   const cell = cy.get('datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted > datatable-body-cell:nth-child(4) > div')
  //   cell.contains(' 01-01-2017 ')
  // });

  it('Should search by observer', function () {
    //objectifs : pouvoir entrer un nom d'observateur (ici Admin); 
    // cliquer sur rechercher et vérifier que les observations retournées ont bien pour observateur des personnes contenant 'Admin' 
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').clear();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').type('Admin');
    cy.get('.button-success').click();
    cy.wait(500)
    const table = cy.get('datatable-row-wrapper > datatable-body-row')
    table.then(d => {
      expect(d.length).to.greaterThan(0)
      Array.prototype.forEach.call(d, e => {
        expect(e.children[1].children[5].firstChild.innerText).to.contains('Administrateur test')
      })
    })
  });

  it('Should search with a new filter', function () {
    //objectifs : pouvoir ajouter un nouveau filtre, (assert que nouveau filtre est bon) 
    // pouvoir sélectionner une valeur dans ce nouveau champ 
    // pouvoir afficher les observations comportant la valeur du champ sélectionné. ici le sexe (femelle) qu'on selectionne à partir du cd_nomenclature (2)
    cy.get('pnx-dynamic-form-generator > :nth-child(1) > .input-group > .form-control').select('Sexe');
    cy.get('.ng-star-inserted > .auto > .ng-select-container > .ng-value-container > .ng-input > input').click(); 
    // get element from its cd_nomenclature (2)
    cy.get('[data-qa="Féminin : L\'individu est de sexe féminin."]').click();
    cy.get('.button-success').click();

    cy.get(':nth-child(1) > .datatable-body-cell-label > .btn > .mat-tooltip-trigger')
      .first()
      .click();
    cy.get('[data-qa="synthese-info-obs-sexe-value"]').contains('Femelle');
  });

  // TODO : non fonctionnel à cause du selecteur #ab5b2c6557fb-0. Se baser le data-qa rajouter sur le composant pnx-dataset

  // it('Should search by acquisition framework and dataset', function () {
  //   // ce test permet de faire une suite d'actions basées sur la sélection des CA et des JDD
  //   // l'idéal serait de tester sur plus que la première ligne, ce qui n'est pas le cas au 13/01/22
  // pouvoir sélectionner un cadre d'acquisition
  // Ensuite : pouvoir sélectionnner un jeu de données dans la liste déroulante qui soit lié au bon cadre d'acquisition correspondannt, je suis pas sûr que ce soir dans la synthèse --<
  //   // vérifier que la sélection d'un cadre d'acquisition filtre bien les jeux de données 
  //   //objectifs : pouvoir sélectionnner un jeu de données dans la liste déroulante, 
  //   //cliquer sur rechercher et vérifier que les observations retournées ont bien pour jeu de données le jeu de données sélectionné
  // refaire la suite d'actions 

  // });

  it('Should open the observation details pop-up and check its quality', async () => {
    //Objectif : que tout ce qui est dans le "i" fonctionne
    // TODO Note : pour moi la 1ere partie de ce test  est un peu "superflu": on récupère les valeurs sur la liste et on vérifie qu'on a les mêmes valeurs sur la page info.
    // const row = cy.get("datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper:nth-child(1) > datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted")
    // const data = await promisify(row)
    // const taxon = data[0].childNodes[2].innerText
    // const date = data[0].childNodes[3].innerText
    // const jdd = data[0].childNodes[5].innerText
    // const observateur = data[0].childNodes[4].innerText
    // cy.get(':nth-child(1) > .clickable > .datatable-row-center > :nth-child(1) > .datatable-body-cell-label > .btn > .mat-tooltip-trigger').click();
    // // assert : la pop-up s'ouvre,
    // // le taxon est présent et correspond à celui de l'observation sur la liste
    // // l'observateur est présent et correspond à celui de l'observation sur la liste
    // cy.get('[data-qa="synthese-info-obs-observateur"]').contains(observateur)
    // // le date est présente est présent et correspond à celle de l'observation sur la liste
    // cy.get('[data-qa="synthese-info-obs-date"]').contains(date.replaceAll("-", "/"))
    // TODO : interessant à partir d'ici
    // l'onglet "détails de l'occurrence" est présent
    // cy.get('#mat-tab-label-0-1 > .mat-tab-label-content').click();
    // // l'onglet "métadonnées" est présent
    // cy.get("#mat-tab-content-0-1 > div > table > tr:nth-child(1) > td:nth-child(2)").contains(` ${jdd} `)
    // // assert : le jeu de données correspond à celui de la liste
    // cy.get('#mat-tab-label-0-2 > .mat-tab-label-content').click(); // l'onglet "taxonomie" est présent
    // cy.get('#mat-tab-label-0-3').click(); // l'onglet "zonage" est présent
    // cy.get('.mat-tab-label-content > .ng-star-inserted').click(); // l'onglet "validation" est présent
    // TODO : à terminer
    // const a_inpn = await promisify(cy.get("body > ngb-modal-window > div > div > pnx-synthese-info-obs > mat-card > div > a"))
    // cy.get('.d-flex > .mat-focus-indicator > .mat-button-wrapper').click();
    // //la page INPN s'ouvre bien
    // //assert : la fiche correspond bien au CD_nom de l'observation (cd_nom URL)
    // cy.get('.font-xs > .mat-focus-indicator > .mat-button-wrapper').click();
    // // assert : le relevé ouverte dans occtax correspond bien à celle de départ (UUID ou autre)
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

  it("Should open the observation in OccTax module when clicking on the 'page' icon", function () {
      cy.get(':nth-child(1) > .clickable > .datatable-row-center > :nth-child(2) > .datatable-body-cell-label > .btn > .mat-tooltip-trigger').click({force: true});
      // assert : l'observation ouverte dans occtax correspond bien à celle de départ (UUID ou autre) 
  });
  it('Should download data at the csv format', function () {
      cy.get('#taxonInput').clear({force: true});
      cy.get('#taxonInput').type('abl');
      cy.get('#ngb-typeahead-0-0 > .ng-star-inserted').click({force: true});
      cy.get('.button-success > .mat-button-wrapper').click({force: true});
      cy.get('#download-btn > .mat-button-wrapper').click({force: true});
      cy.get('div.ng-star-inserted > :nth-child(1) > :nth-child(2) > .mat-button-wrapper').click({force: true});
      //assert : le téléchargement du csv s'effectue bien en prenant en compte les résultats du filtre
  });
});
