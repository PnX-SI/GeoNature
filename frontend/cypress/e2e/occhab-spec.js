describe('Testing occhab', () => {
  beforeEach(() => {
    cy.geonatureLogin();
  });

  it('should create an habitation', () => {
    cy.visit('/#/occhab');

    const canvas =
      "[data-qa='pnx-occhab-form'] > div:nth-child(1) > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom";
    cy.get('#add-btn').click();

    cy.get('#validateButton').should('be.disabled');

    cy.get(
      '[data-qa="pnx-occhab-form"] > div:nth-child(1) > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-left > div.leaflet-draw.leaflet-control > div:nth-child(1) > div > a'
    ).click();
    // Leaflet.draw creates its tooltip only once the draw handler is enabled
    cy.get('.leaflet-draw-tooltip').should('exist');
    const positions = [
      [250, 250],
      [300, 250],
      [300, 300],
      [250, 300],
      [250, 250],
    ];
    positions.forEach((pos) => {
      cy.get(canvas).click(pos[0], pos[1]);
      cy.wait(500);
    });
    cy.get('#validateButton').should('be.disabled');

    cy.get('[data-qa="gn-common-form-observers-select"]').click();
    cy.get('[data-qa="gn-common-form-observers-select-AGENT test"]').click();
    cy.get('#validateButton').should('be.disabled');

    cy.get('[data-qa="pnx-occhab-form-dataset"] > ng-select').click();
    cy.get('[data-qa="Carto d\'habitat X"]').click();
    cy.get('#validateButton').should('be.disabled');

    cy.get('[data-qa="pnx-occhab-form-geographic"] > div > select').select('1: Object');
    cy.get('#validateButton').should('be.disabled');

    cy.get('#add-hab-btn').click();
    cy.get('#taxonInput').type('dune');
    var selected_element = '';
    cy.get('#ngb-typeahead-3-0').then(($el) => {
      selected_element = $el.text().trim();
      cy.get('#ngb-typeahead-3-0').click();

      cy.get('[data-qa="pnx-occhab-form-technique-collect"] > div > select').select('1: Object');
      cy.get('[data-qa="pnx-occhab-form-valid-button"]').click();

      cy.get('#validateButton').click();
    });

    const rowSelector =
      '[data-qa="pnx-occhab-map-list-datatable"] > div > datatable-body > datatable-selection > datatable-scroller';
    cy.get(rowSelector).should(($el) => {
      expect($el[0].children[0].children[0].children[1].children[4].innerText).contains(
        selected_element
      );
    });
    cy.get(rowSelector).then(($el) => {
      $el[0].children[0].children[0].children[1].children[2].children[0].children[0].click();
    });
  });
});
