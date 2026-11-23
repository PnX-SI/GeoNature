const VALIDATION_STATUS_ID = 458;
const VALIDATION_STATUS_CODE = '0';

function openSyntheseWithConfirmationConfig(confirmSearchFilters) {
  cy.interceptGlobalConfig({
    SYNTHESE: {
      CONFIRM_SEARCH_FILTERS: confirmSearchFilters,
      DEFAULT_FILTERS: { cd_nomenclature_valid_status: [] },
    },
  });
  cy.intercept('POST', '**/synthese/for_web*').as('search');
  cy.visit('/#/synthese');
  cy.wait('@search');
}

function selectValidationStatus() {
  cy.get('[data-qa="field-nomenclature-id_nomenclature_valid_status"] ng-select').click();
  cy.get(`ng-dropdown-panel [data-qa="${VALIDATION_STATUS_CODE}"]`).click();
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
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: false,
      },
    ]);
    selectValidationStatus();

    searchAndExpectConfirmation();
  });

  it('confirms when confirmOnAbsence is false and the value is not configured but selected', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        confirmOnAbsence: false,
      },
    ]);
    selectValidationStatus();

    searchAndExpectConfirmation();
  });

  it('does not confirm an empty filter when confirmOnAbsence is false', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: false,
      },
    ]);

    searchWithoutConfirmation();
  });

  it('confirms when confirmOnAbsence is true and the configured value is absent', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: true,
      },
    ]);

    searchAndExpectConfirmation();
  });

  it('does not confirm when confirmOnAbsence is true and the value is configured', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: true,
      },
    ]);
    selectValidationStatus();

    searchWithoutConfirmation();
  });

  it('does not confirm when confirmOnAbsence is true and the selected value is not configured', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        confirmOnAbsence: true,
      },
    ]);
    selectValidationStatus();

    searchWithoutConfirmation();
  });

  it('confirms an empty filter when confirmOnAbsence is true and values is empty', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'id_nomenclature_valid_status', values: [], confirmOnAbsence: true },
    ]);

    searchAndExpectConfirmation();
  });

  it('does not confirm a set filter when confirmOnAbsence is true and values is empty', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'id_nomenclature_valid_status', values: [], confirmOnAbsence: true },
    ]);
    selectValidationStatus();

    searchWithoutConfirmation();
  });

  it('confirms a set filter when confirmOnAbsence is false and values is empty', () => {
    openSyntheseWithConfirmationConfig([
      { field: 'id_nomenclature_valid_status', values: [], confirmOnAbsence: false },
    ]);
    selectValidationStatus();

    searchAndExpectConfirmation();
  });

  it('uses presence behavior when confirmOnAbsence is omitted', () => {
    openSyntheseWithConfirmationConfig([{ field: 'id_nomenclature_valid_status', values: [] }]);
    selectValidationStatus();

    searchAndExpectConfirmation();
  });

  it('does not show a modal when no filters require confirmation', () => {
    openSyntheseWithConfirmationConfig([]);

    searchWithoutConfirmation();
  });

  it('shows all confirmation rules with the same field', () => {
    openSyntheseWithConfirmationConfig([
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: false,
        message: 'Filters.ConfirmSearch.Messages.valid_status',
      },
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID],
        confirmOnAbsence: false,
        message: 'Filters.ConfirmSearch.Messages.other_valid_status',
      },
      {
        field: 'id_nomenclature_valid_status',
        values: [VALIDATION_STATUS_ID + 1],
        confirmOnAbsence: false,
        message: 'Filters.ConfirmSearch.Messages.unmatched_valid_status',
      },
    ]);
    selectValidationStatus();

    searchAndExpectConfirmation();
    cy.get('[data-qa="synthese-search-filters-modal"] mat-list-item').should('have.length', 2);
    cy.get('[data-qa="synthese-search-filters-modal-cancel-button"]').click();
  });
});
