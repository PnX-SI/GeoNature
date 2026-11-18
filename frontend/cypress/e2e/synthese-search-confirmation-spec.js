const DATE_MIN = '2016-12-24';

function openSyntheseWithConfirmationConfig(confirmSearchFilters) {
  cy.interceptGlobalConfig({
    SYNTHESE: { CONFIRM_SEARCH_FILTERS: confirmSearchFilters },
  });
  cy.intercept('POST', '**/synthese/for_web*').as('search');
  cy.visit('/#/synthese');
  cy.wait('@search');
}

function selectDateMin() {
  cy.get('[data-qa="synthese-form-date-min"]').click();
  cy.get('[aria-label="Select year"]').select('2016');
  cy.get('[aria-label="Select month"]').select('Déc');
  cy.get('[aria-label="Samedi, 24 Décembre 2016"]').click();
}

function searchAndExpectConfirmation() {
  cy.get('[data-qa="synthese-search-btn"]').click();
  cy.get('[data-qa="synthese-search-filters-modal"]').should('be.visible');
}

function searchWithoutConfirmation() {
  cy.get('[data-qa="synthese-search-btn"]').click();
  cy.get('[data-qa="synthese-search-filters-modal"]').should('not.exist');
  cy.wait('@search');
}

describe('Synthese search confirmation', () => {
  beforeEach(() => {
    cy.geonatureLogin();
  });

  it('confirms when confirmOnAbsence is false and the value is configured', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: [DATE_MIN], confirmOnAbsence: false },
    ]);
    selectDateMin();

    searchAndExpectConfirmation();
  });

  it('does not confirm when confirmOnAbsence is false and the value is not configured', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: ['01/01/2017'], confirmOnAbsence: false },
    ]);
    selectDateMin();

    searchWithoutConfirmation();
  });

  it('does not confirm an empty filter when confirmOnAbsence is false', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: [DATE_MIN], confirmOnAbsence: false },
    ]);

    searchWithoutConfirmation();
  });

  it('confirms when confirmOnAbsence is true and the configured value is absent', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: [DATE_MIN], confirmOnAbsence: true },
    ]);

    searchAndExpectConfirmation();
  });

  it('does not confirm when confirmOnAbsence is true and the value is configured', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: [DATE_MIN], confirmOnAbsence: true },
    ]);
    selectDateMin();

    searchWithoutConfirmation();
  });

  it('confirms when confirmOnAbsence is true and the selected value is not configured', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: ['01/01/2017'], confirmOnAbsence: true },
    ]);
    selectDateMin();

    searchAndExpectConfirmation();
  });

  it('confirms an empty filter when confirmOnAbsence is true and values is empty', () => {
    openSyntheseWithConfirmationConfig([{ field: 'date_min', values: [], confirmOnAbsence: true }]);

    searchAndExpectConfirmation();
  });

  it('does not confirm a set filter when confirmOnAbsence is true and values is empty', () => {
    openSyntheseWithConfirmationConfig([{ field: 'date_min', values: [], confirmOnAbsence: true }]);
    selectDateMin();

    searchWithoutConfirmation();
  });

  it('confirms a set filter when confirmOnAbsence is false and values is empty', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'date_min', values: [], confirmOnAbsence: false },
    ]);
    selectDateMin();

    searchAndExpectConfirmation();
  });

  it('uses presence behavior when confirmOnAbsence is omitted', () => {
    openSyntheseWithConfirmationConfig([{ field: 'date_min', values: [] }]);
    selectDateMin();

    searchAndExpectConfirmation();
  });

  it('does not show a modal when no filters require confirmation', () => {
    openSyntheseWithConfirmationConfig([]);

    searchWithoutConfirmation();
  });
});
