import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  getSelectorImportListTableRowEdit,
  getSelectorImportListTableRowId,
  SELECTOR_IMPORT_CONTENTMAPPING_STEP_BUTTON,
  SELECTOR_IMPORT_FIELDMAPPING_CD_NOM,
  SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN,
  SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATASET,
  SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE,
  SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS,
  SELECTOR_IMPORT_FIELDMAPPING_WKT,
  SELECTOR_IMPORT_FOOTER_DELETE,
  SELECTOR_IMPORT_FOOTER_SAVE,
  SELECTOR_IMPORT_MODAL_EDIT_VALIDATE,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

function runTheProcessUntilFieldMapping(user) {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination();
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
}

function runTheProcessUntilContentMapping(user) {
  runTheProcessUntilFieldMapping(user);
  cy.configureImportFieldMapping(user.dataset);
  cy.wait(500);
}

function goToContentMappingPage() {
  cy.get(SELECTOR_IMPORT_CONTENTMAPPING_STEP_BUTTON).click();
  cy.wait(500);
}

function checkImportIsFirstInList(importId) {
  cy.get(getSelectorImportListTableRowId(0)).should('have.text', ` ${importId} `);
}

function checkImportIsNotFirstInList(importId) {
  cy.get(getSelectorImportListTableRowId(0)).should('not.have.text', ` ${importId} `);
}

function clickOnFirstLineEdit() {
  cy.get(getSelectorImportListTableRowEdit(0)).click();
  cy.get(SELECTOR_IMPORT_MODAL_EDIT_VALIDATE).should('exist').click()
  cy.wait(TIMEOUT_WAIT);
}

function selectFieldMappingField(dataQa, value) {
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

function selectContentMappingField(dataQa, value) {
  cy.get(`[data-qa=import-contentmapping-theme-${dataQa}]`).should('exist').select(value);
}

function fillTheFieldMappingFormRaw(datasetName) {
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN, 'date_debut');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS, 'date_debut');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE, 'date_debut');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_WKT, 'date_debut');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_CD_NOM, 'date_debut');
  selectFieldMappingField(SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATASET, datasetName);
}
// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

describe('Navigation - cancel and save', () => {
  const viewport = VIEWPORTS[0];
  const user = USERS[0];
  context(`viewport: ${viewport.width}x${viewport.height}`, () => {
    context(`user: ${user.login.username}`, () => {
      beforeEach(() => {
        cy.viewport(viewport.width, viewport.height);
        cy.geonatureLogin(user.login.username, user.login.password);
        cy.visitImport();
      });

      it('fieldmapping - cancel and suppress', () => {
        runTheProcessUntilFieldMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element

          fillTheFieldMappingFormRaw(user.dataset);
          cy.get(SELECTOR_IMPORT_FOOTER_DELETE).should('be.enabled').click();
          cy.wait(TIMEOUT_WAIT);
          cy.checkCurrentPageIsImport();
          checkImportIsNotFirstInList(importID);
        });
      });

      it('fieldmapping - cancel', () => {
        runTheProcessUntilFieldMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element

          fillTheFieldMappingFormRaw(user.dataset);
          cy.visitImport();
          checkImportIsFirstInList(importID);
          clickOnFirstLineEdit();
          cy.url().then((url) => {
            const parts = url.split('/');
            const importID_reopened = parts[parts.length - 2]; // Get the penultimate element
            expect(importID).to.be.equal(importID_reopened);
            // Checks that a ng-select is not restored
            cy.get(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN).find('.ng-placeholder');
            cy.deleteCurrentImport();
          });
        });
      });

      it('fieldmapping - save', () => {
        runTheProcessUntilFieldMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element
          fillTheFieldMappingFormRaw(user.dataset);
          cy.get(SELECTOR_IMPORT_FOOTER_SAVE).should('be.enabled').click();
          checkImportIsFirstInList(importID);
          clickOnFirstLineEdit();

          // Checks that a ng-select is well restored
          cy.get(SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN)
            .find('.ng-value-label')
            .should('exist')
            .should('contains.text', 'date_debut');

          cy.deleteCurrentImport();
        });
      });

      it('contentmapping - cancel and suppress', () => {
        runTheProcessUntilContentMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element
          cy.get(SELECTOR_IMPORT_FOOTER_DELETE).should('be.enabled').click();
          cy.wait(TIMEOUT_WAIT);
          cy.checkCurrentPageIsImport();
          checkImportIsNotFirstInList(importID);
        });
      });

      it('contentmapping - cancel', () => {
        const FIELD = 'id_nomenclature_behaviour';
        const VALUE = '0 - Inconnu';
        runTheProcessUntilContentMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element
          selectContentMappingField(FIELD, VALUE);
          cy.visitImport();
          cy.wait(500);
          checkImportIsFirstInList(importID);
          clickOnFirstLineEdit();
          goToContentMappingPage();

          cy.url().then((url) => {
            const parts = url.split('/');
            const importID_reopened = parts[parts.length - 2]; // Get the penultimate element
            expect(importID).to.be.equal(importID_reopened);
            cy.get(`[data-qa=import-contentmapping-theme-${FIELD}] option:selected`).should(
              'not.have.text',
              ` ${VALUE} `
            );
            cy.deleteCurrentImport();
          });
        });
        cy.wait(500);
      });

      it('contentmapping - save', () => {
        const FIELD = 'id_nomenclature_behaviour';
        const VALUE = '0 - Inconnu';

        runTheProcessUntilContentMapping(user);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const importID = parts[parts.length - 2]; // Get the penultimate element

          selectContentMappingField(FIELD, VALUE);

          cy.get(SELECTOR_IMPORT_FOOTER_SAVE).should('be.enabled').click();
          cy.wait(TIMEOUT_WAIT);
          checkImportIsFirstInList(importID);
          clickOnFirstLineEdit();
          goToContentMappingPage();

          // Checks that a ng-select is well restored
          cy.get(`[data-qa=import-contentmapping-theme-${FIELD}] option:selected`).should(
            'have.text',
            ` ${VALUE} `
          );

          cy.deleteCurrentImport();
        });
      });
    });
  });
});
