import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { DEFAULT_FIELDMAPPINGS } from './constants/mappings';
import { v4 as uuidv4 } from 'uuid';
import {
  SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE,
  SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE_OK,
  SELECTOR_IMPORT_FIELDMAPPING_CD_NOM,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATASET,
  SELECTOR_IMPORT_FIELDMAPPING_DATASET,
  SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_CLOSE,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_NAME,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK,
  SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE,
  SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS,
  SELECTOR_IMPORT_FIELDMAPPING_SELECTION,
  SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME,
  SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_OK,
  SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_TEXT,
  SELECTOR_IMPORT_FIELDMAPPING_SWITCH_DATASET,
  SELECTOR_IMPORT_FIELDMAPPING_VALIDATE,
  SELECTOR_IMPORT_FIELDMAPPING_WKT,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const FIELDMAPPING_TEST_NAME = uuidv4();
const FIELDMAPPING_TEST_RENAME = uuidv4();
const USER_ADMIN = USERS[0];
const USER_AGENT = USERS[1];
const VIEWPORT = VIEWPORTS[0];

function selectField(dataQa, value) {
  cy.get(dataQa)
    .should('exist')
    .click()
    .get('ng-dropdown-panel >')
    .get('.ng-option')
    .contains(value)
    .then((v) => {
      cy.wrap(v).should('exist').click();
    });
}

function selectMapping(mappingName) {
  // Kept as one chain (no .then()+cy.wrap() detour): the option list can still be
  // re-rendering right after navigating here, and breaking into .then() captures a
  // one-off element reference that can detach mid-click ("page updated while this
  // command was executing"). Staying in the chain lets Cypress retry the whole query
  // from scratch instead of clicking a stale node.
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION).should('exist').click();
  cy.get('ng-dropdown-panel .ng-option').contains(mappingName).click();
}

function deleteCurrentMapping() {
  // Delete the mapping
  cy.intercept('DELETE', '**/fieldmappings/*/').as('deleteFieldMapping');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE).should('exist').click();
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE_OK, { force: true })
    .should('be.enabled')
    .click();
  cy.wait('@deleteFieldMapping');
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

function fillTheFormRaw() {
  selectField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_debut');
  selectField(SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS, 'date_debut');
  selectField(SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE, 'date_debut');
  selectField(SELECTOR_IMPORT_FIELDMAPPING_WKT, 'date_debut');
  selectField(SELECTOR_IMPORT_FIELDMAPPING_CD_NOM, 'date_debut');
  cy.selectDataset();
}

function fillTheForm() {
  // Fill in the form with mandatory field
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist');

  fillTheFormRaw();

  // Every mandatory field is filled: should be able to validate
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('be.enabled').click();

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL, { force: true }).should('be.visible');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK, { force: true }).should('be.disabled');

  // Save the model
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NAME, { force: true })
    .should('exist')
    .clear()
    .type(FIELDMAPPING_TEST_NAME);
  cy.intercept('POST', '**/fieldmappings/**').as('createFieldMapping');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK, { force: true }).should('be.enabled').click();
  cy.wait('@createFieldMapping');
}

function runTheProcess() {
  cy.setupImportViaApi('fieldmapping').as('currentImportId');
}

function restartTheProcess() {
  cy.get('@currentImportId').then((importId) => {
    cy.deleteImport(importId, 'synthese');
  });
  runTheProcess();
}

function checkThatMappingCanBeSaved() {
  // Trigger the modal
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('be.enabled').click();

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK, { force: true }).should('exist');

  // Close the modal
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_CLOSE, { force: true }).click();
}

function checkThatMappingCanNotBeSaved() {
  // Trigger the modal
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('be.enabled').click();

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK, { force: true }).should('not.exist');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL, { force: true }).should('be.visible');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK, { force: true }).should('be.disabled');

  // Save the model
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NAME, { force: true })
    .should('exist')
    .clear()
    .type(FIELDMAPPING_TEST_NAME);
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK, { force: true }).should('be.enabled');

  // Close the modal
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_CLOSE, { force: true }).click();
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Field mapping step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess();
      cy.get('[data-qa="import-new-fieldmapping-form"]').should('exist');
      cy.selectDataset();
    });

    it('Should access jdd only filtered based on permissions  ', () => {
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATASET)
        .click()
        .get('.ng-option')
        .should('have.length', 2)
        .should('contain', USER_ADMIN.dataset)
        .should('contain', USER_AGENT.dataset);
    });

    it('Should be able to create a new field mapping, rename it, and delete it', () => {
      fillTheForm();
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(FIELDMAPPING_TEST_NAME);

      // Rename the mapping
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME).should('exist').click();
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_OK).should('be.disabled');
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_TEXT)
        .should('exist')
        .clear()
        .type(FIELDMAPPING_TEST_RENAME);
      cy.intercept('POST', '**/fieldmappings/**').as('renameFieldMapping');
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_OK).should('be.enabled').click();
      cy.wait('@renameFieldMapping');

      // Reload the page
      cy.reload();

      // Check that the name has changed
      selectMapping(FIELDMAPPING_TEST_RENAME);

      // Delete the mapping
      deleteCurrentMapping();

      // Reload the page
      cy.reload();

      // Check that the name has disappaeared
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
        .should('exist')
        .click()
        .get('ng-dropdown-panel')
        .get('.ng-option')
        .contains(FIELDMAPPING_TEST_RENAME)
        .should('not.exist');
    });

    it('Should be able to modifiy an item of the field mapping', () => {
      fillTheForm();
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(FIELDMAPPING_TEST_NAME);

      // Change a mapping value and save
      selectField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_fin');

      cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('be.enabled').click();
      cy.intercept('POST', '**/fieldmappings/*/').as('updateFieldMapping');
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK, { force: true }).should('be.enabled').click();
      cy.wait('@updateFieldMapping');

      // restart the process
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(FIELDMAPPING_TEST_NAME);

      cy.get(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN)
        .find('.ng-value-label')
        .should('exist')
        .should('contains.text', 'date_fin');

      // delete current mapping
      deleteCurrentMapping();
    });

    it('Should not be able to access fieldmapping owned by a different user', () => {
      // Create the fieldmapping
      fillTheForm();

      // Switch user
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess();

      // Check that field mapping does not exist
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
        .should('exist')
        .click()
        .get('ng-dropdown-panel')
        .get('.ng-option')
        .contains(FIELDMAPPING_TEST_NAME)
        .should('not.exist');

      // Switch back to previous user
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess();

      // Check that field mapping does exist
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
        .should('exist')
        .click()
        .get('ng-dropdown-panel')
        .get('.ng-option')
        .contains(FIELDMAPPING_TEST_NAME)
        .should('exist');

      // Check the import list, and select expected mapping
      selectMapping(FIELDMAPPING_TEST_NAME);
      deleteCurrentMapping();
    });

    it('An admin user should be able to access and delete a mapping owned by an agent user', () => {
      // Switch user
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess();

      // Create a mapping
      fillTheForm();

      // Switch back to previous user
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess();

      // Check that field mapping does exist
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
        .should('exist')
        .click()
        .get('ng-dropdown-panel')
        .get('.ng-option')
        .contains(FIELDMAPPING_TEST_NAME)
        .should('exist');

      // Check the import list, and select expected mapping
      selectMapping(FIELDMAPPING_TEST_NAME);
      deleteCurrentMapping();
    });

    it('Should be able to modifiy the default mapping if user got rights. A save to alternative should be offered to the user.', () => {
      // Mapping Synthese
      selectMapping(DEFAULT_FIELDMAPPINGS[0]);
      // Selecting a mapping preset overwrites the dataset field set by beforeEach — reselect it.
      cy.selectDataset();
      checkThatMappingCanBeSaved();

      restartTheProcess(USER_ADMIN);
      selectMapping(DEFAULT_FIELDMAPPINGS[1]);
      fillTheFormRaw();
      cy.selectDataset();
      checkThatMappingCanBeSaved();
    });
    it('Should not be able to modifiy the default mapping if user does not got rights', () => {
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess();
      selectMapping(DEFAULT_FIELDMAPPINGS[0]);
      cy.selectDataset();
      checkThatMappingCanNotBeSaved();
    });

    afterEach(() => {
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
    });
  });
});
