import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import { v4 as uuidv4 } from 'uuid';

import { DEFAULT_CONTENTMAPPINGS } from './constants/mappings';
import {
  SELECTOR_IMPORT_CONTENTMAPPING_BUTTON_DELETE,
  SELECTOR_IMPORT_CONTENTMAPPING_FORM,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL_CLOSE,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL_DELETE_OK,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NAME,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK,
  SELECTOR_IMPORT_CONTENTMAPPING_MODAL_OK,
  SELECTOR_IMPORT_CONTENTMAPPING_SELECT,
  SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME,
  SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME_OK,
  SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_TEXT,
  SELECTOR_IMPORT_CONTENTMAPPING_VALIDATE,
  SELECTOR_IMPORT_NEW_VERIFICATION_START,
  SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATASET,
  SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN,
  SELECTOR_IMPORT_FIELDMAPPING_WKT,
  SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE,
  SELECTOR_IMPORT_FIELDMAPPING_CD_HAB,
  SELECTOR_IMPORT_FIELDMAPPING_VALIDATE,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_CLOSE,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_NAME,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK,
  SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const FIELD = 'id_nomenclature_behaviour';
const MAPPING_TEST_NAME = uuidv4();
const MAPPING_TEST_RENAME = uuidv4();
const USER_ADMIN = USERS[0];
const USER_AGENT = USERS[1];
const VALUE = '0 - Inconnu';
const VIEWPORT = VIEWPORTS[0];

function selectField(dataQa, value) {
  cy.get(`[data-qa=import-contentmapping-theme-${dataQa}]`).should('exist').select(value);
}

function selectMapping(mappingName) {
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_SELECT).should('exist').select(mappingName);
}

function deleteCurrentMapping() {
  // Delete the mapping
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_BUTTON_DELETE).should('exist').click();
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_DELETE_OK, { force: true })
    .should('be.enabled')
    .click({ force: true });
}

// ////////////////////////////////////////////////////////////////////////////
// Save mappping
// ////////////////////////////////////////////////////////////////////////////

function saveTheForm() {
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_VALIDATE).should('exist').should('be.enabled').click();

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL, { force: true }).should('exist');
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_OK, { force: true })
    .should('be.enabled')
    .click({ force: true });
}

function saveTheNewForm() {
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_VALIDATE)
    .should('exist')
    .should('be.enabled')
    .click({ force: true });

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL, { force: true }).should('exist');
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK, { force: true }).should('be.disabled');

  // Save the model
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NAME, { force: true })
    .should('exist')
    .clear()
    .type(MAPPING_TEST_NAME);
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK, { force: true })
    .should('be.enabled')
    .click({ force: true });
}

function checkThatMappingCanNotBeSaved() {
  // Trigger the modal
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_VALIDATE)
    .should('exist')
    .should('be.enabled')
    .click({ force: true });

  // Validation modal appear
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL, { force: true }).should('be.visible');
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_OK, { force: true }).should('not.exist');
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK, { force: true }).should('be.disabled');

  // Save the model
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NAME, { force: true })
    .should('exist')
    .clear()
    .type(MAPPING_TEST_NAME);
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK, { force: true }).should('be.enabled');

  // Close the modal
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_MODAL_CLOSE, { force: true }).click({ force: true });
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

function runTheProcess(user) {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination();
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
  cy.configureImportFieldMapping(user.dataset);
}

function runTheProcessForOcchab(user) {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination('Occhab');
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
  // cy.configureImportFieldMapping(user.dataset);
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'error');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_WKT, 'error');
  cy.get('#mat-tab-label-0-1').click();
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE, 'error');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_CD_HAB, 'error');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATASET, 'error');

  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).click();
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_CANCEL, { force: true }).click();
}

function restartTheProcess(user) {
  cy.deleteCurrentImport();
  cy.wait(TIMEOUT_WAIT);
  runTheProcess(user);
}

// Occhab dedicated
function selectFieldMappingField(dataQa, value) {
  cy.get(`[data-qa="${dataQa}"]`)
    .should('exist')
    .click()
    .get('ng-dropdown-panel >')
    .get('.ng-option')
    .contains(value)
    .then((v) => {
      cy.wrap(v).should('exist').click();
    });
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Content mapping step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);
      cy.get(SELECTOR_IMPORT_CONTENTMAPPING_FORM).should('exist');
    });

    it('Should be able to create a new mapping, rename it, and delete it', () => {
      cy.log('Mapping: ' + MAPPING_TEST_NAME);
      saveTheNewForm();
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(MAPPING_TEST_NAME);

      // Rename the mapping
      cy.get(SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME).should('exist').click();
      cy.get(SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME_OK).should('be.disabled');
      cy.get(SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_TEXT)
        .should('exist')
        .clear()
        .type(MAPPING_TEST_RENAME);
      cy.get(SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME_OK).should('be.enabled').click();

      // Reload the page
      cy.reload();

      // Check that the name has changed
      selectMapping(MAPPING_TEST_RENAME);

      // Delete the mapping
      deleteCurrentMapping();

      // Reload the page
      cy.reload();

      // Check that the name has disappeared
      cy.get(
        `${SELECTOR_IMPORT_CONTENTMAPPING_SELECT} option:contains(${MAPPING_TEST_NAME})`
      ).should('not.exist');
    });

    it('Should be able to modifiy an item of the contentmapping', () => {
      saveTheNewForm();
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(MAPPING_TEST_NAME);
      selectField(FIELD, VALUE);
      saveTheForm();

      // restart the process
      restartTheProcess(USER_ADMIN);

      // Check the import list, and select expected mapping
      selectMapping(MAPPING_TEST_NAME);

      cy.get(`[data-qa=import-contentmapping-theme-${FIELD}] option:selected`).should(
        'have.text',
        ` ${VALUE} `
      );

      // delete current mapping
      deleteCurrentMapping();
    });

    it('Should not be able to access mapping owned by a different user', () => {
      // Create the mapping
      saveTheNewForm();

      // Switch user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess(USER_AGENT);

      // Check that content mapping does not exist
      cy.get(
        `${SELECTOR_IMPORT_CONTENTMAPPING_SELECT} option:contains(${MAPPING_TEST_NAME})`
      ).should('not.exist');

      // Switch back to previous user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);

      // Check that content mapping does exist
      cy.get(
        `${SELECTOR_IMPORT_CONTENTMAPPING_SELECT} option:contains(${MAPPING_TEST_NAME})`
      ).should('exist');

      // Check the import list, and select expected mapping
      selectMapping(MAPPING_TEST_NAME);
      deleteCurrentMapping();
    });

    it('An admin user should be able to access and delete a mapping owned by an agent user', () => {
      // Switch user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess(USER_AGENT);

      // Create the mapping
      saveTheNewForm();

      // Switch back to previous user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);

      // Check that content mapping does exist
      cy.get(
        `${SELECTOR_IMPORT_CONTENTMAPPING_SELECT} option:contains(${MAPPING_TEST_NAME})`
      ).should('exist');

      // Check the import list, and select expected mapping
      selectMapping(MAPPING_TEST_NAME);
      deleteCurrentMapping();
    });

    it('Should not be able to modifiy the default mapping. A save to alternative should be offered to the user.', () => {
      // Mapping Synthese
      selectMapping(DEFAULT_CONTENTMAPPINGS[0]);
      selectField(FIELD, VALUE);
      checkThatMappingCanNotBeSaved();
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });

  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    it('Should skip the contentmapping if it is not needed', () => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      // occhab
      runTheProcessForOcchab(USER_ADMIN);
      // Should be on step "verification"
      cy.get(SELECTOR_IMPORT_NEW_VERIFICATION_START).should('exist');
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });
});
