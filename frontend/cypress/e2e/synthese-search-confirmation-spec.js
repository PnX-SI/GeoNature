describe('Synthese search confirmation', () => {
  beforeEach(() => {
    cy.geonatureLogin();
    cy.interceptGlobalConfig({
      SYNTHESE: { CONFIRM_SEARCH_FILTERS: ['date_min'] },
    });
    cy.intercept('POST', '**/synthese/for_web*').as('search');
    cy.visit('/#/synthese');
    cy.wait('@search');
  });

  it('asks for confirmation when a configured filter is set', () => {
    cy.get('[data-qa="synthese-form-date-min"]').click();
    cy.get('[aria-label="Select year"]').select('2016');
    cy.get('[aria-label="Select month"]').select('Déc');
    cy.get('[aria-label="Samedi, 24 Décembre 2016"]').click();

    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.get('[data-qa="synthese-search-filters-modal"]').should('be.visible');
    cy.get('[data-qa="synthese-search-filters-modal"]').should('contain', 'date_min');

    cy.get('[data-qa="synthese-search-filters-modal-cancel-button"]').click();
    cy.get('@search.all').should('have.length', 1); // only the initial request
  });

  it('searches with the confirmed filter values', () => {
    cy.get('[data-qa="synthese-form-date-min"]').click();
    cy.get('[aria-label="Select year"]').select('2016');
    cy.get('[aria-label="Select month"]').select('Déc');
    cy.get('[aria-label="Samedi, 24 Décembre 2016"]').click();

    cy.get('[data-qa="synthese-search-btn"]').click();
    cy.get('[data-qa="synthese-search-filters-modal-confirm-button"]').click();

    cy.wait('@search')
      .its('request.body')
      .should((body) => {
        expect(body).to.have.property('date_min');
      });
  });
});
