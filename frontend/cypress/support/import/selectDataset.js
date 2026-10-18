const SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATASET =
  '[data-qa=field-dataset-unique_dataset_id] mat-select';
function selectDataset() {
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATASET).click().get('mat-option').first().click();
}

Cypress.Commands.add('selectDataset', selectDataset);
