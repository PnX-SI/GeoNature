import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import { DEFAULT_FIELDMAPPINGS } from './constants/mappings';
import { v4 as uuidv4 } from 'uuid';
import {
  SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE,
  SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE_OK,
  SELECTOR_IMPORT_FIELDMAPPING_CD_NOM,
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
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
    .should('exist')
    .click()
    .get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(mappingName)
    .then((v) => {
      cy.wrap(v).should('exist').click();
    });
}

function deleteCurrentMapping() {
  // Delete the mapping
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE).should('exist').click();
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE_OK, { force: true })
    .should('be.enabled')
    .click();
  cy.wait(TIMEOUT_WAIT);
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
}

function fillTheForm() {
  // Fill in the form with mandatory field
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist');

  selectField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_debut');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('not.be.enabled');

  selectField(SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS, 'date_debut');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('not.be.enabled');
  selectField;
  selectField(SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE, 'date_debut');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('not.be.enabled');

  selectField(SELECTOR_IMPORT_FIELDMAPPING_WKT, 'date_debut');
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_VALIDATE).should('exist').should('not.be.enabled');

  selectField(SELECTOR_IMPORT_FIELDMAPPING_CD_NOM, 'date_debut');

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
  cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK, { force: true }).should('be.enabled').click();

  cy.wait(TIMEOUT_WAIT);
}

function runTheProcess(user) {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination();
  cy.pickDataset(user.dataset);
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
}

function restartTheProcess(user) {
  cy.wait(TIMEOUT_WAIT);
  cy.deleteCurrentImport();
  cy.wait(TIMEOUT_WAIT);
  runTheProcess(user);
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
      runTheProcess(USER_ADMIN);
      cy.get('[data-qa="import-new-fieldmapping-form"]').should('exist');
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
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_OK).should('be.enabled').click();

      cy.wait(TIMEOUT_WAIT);

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
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK, { force: true }).should('be.enabled').click();

      cy.wait(TIMEOUT_WAIT);

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
      cy.wait(TIMEOUT_WAIT);
    });

    it('Should not be able to access fieldmapping owned by a different user', () => {
      // Create the fieldmapping
      fillTheForm();

      // Switch user
      cy.wait(TIMEOUT_WAIT);
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess(USER_AGENT);

      // Check that field mapping does not exist
      cy.get(SELECTOR_IMPORT_FIELDMAPPING_SELECTION)
        .should('exist')
        .click()
        .get('ng-dropdown-panel')
        .get('.ng-option')
        .contains(FIELDMAPPING_TEST_NAME)
        .should('not.exist');

      // Switch back to previous user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);

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
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess(USER_AGENT);

      // Create a mapping
      fillTheForm();

      // Switch back to previous user
      cy.deleteCurrentImport();
      cy.geonatureLogout();
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);

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
      selectField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_fin');
      checkThatMappingCanBeSaved();

      restartTheProcess(USER_ADMIN);
      selectMapping(DEFAULT_FIELDMAPPINGS[1]);
      fillTheFormRaw();
      checkThatMappingCanBeSaved();
    });
    it('Should not be able to modifiy the default mapping if user does not got rights', () => {
      cy.geonatureLogout();
      cy.geonatureLogin(USER_AGENT.login.username, USER_AGENT.login.password);
      runTheProcess(USER_AGENT);
      selectMapping(DEFAULT_FIELDMAPPINGS[0]);
      selectField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_fin');
      checkThatMappingCanNotBeSaved();
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });
});
