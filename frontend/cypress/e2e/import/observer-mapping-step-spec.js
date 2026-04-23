import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const USER = USERS[1];
const VIEWPORT = VIEWPORTS[0];

// ////////////////////////////////////////////////////////////////////////////
// Test data and helpers
// ////////////////////////////////////////////////////////////////////////////

const SELECTORS = {
  title: 'h5',
  mappingTable: 'table.matching-table',
  tableHeaders: 'table.matching-table thead th',
  tableRows: 'table.matching-table tbody tr',
  observersForm: '[data-qa="import-observersmapping-observers-form"]',
  loadableLayout: 'gn-loadable-layout',
  resetButton: '.MappingBtn button:first-child',
  clearButton: '.MappingBtn button:last-child',
  backBtn: '[data-qa="import-observersmapping-back-btn"]',
  nextBtn: '[data-qa="import-observersmapping-model-validate"]',
};

// ////////////////////////////////////////////////////////////////////////////
// Helper function to navigate to observer mapping step
// ////////////////////////////////////////////////////////////////////////////

function runTheProcessToObserverMapping() {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination();
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
  cy.configureImportFieldMapping(USER.dataset);
  cy.configureImportContentMapping();
}

// ////////////////////////////////////////////////////////////////////////////
// Test suite
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Observer Mapping step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER.login.username, USER.login.password);
    });

    context('Observer mapping interface display', () => {
      beforeEach(() => {
        runTheProcessToObserverMapping();
      });

      it('Should display all required interface elements', () => {
        // Title
        cy.get(SELECTORS.title).should('exist').should('be.visible');

        // Mapping table with headers
        cy.get(SELECTORS.mappingTable).should('exist').should('be.visible');
        cy.get(SELECTORS.tableHeaders).should('have.length', 2);

        // Action buttons (reset and clear)
        cy.get(SELECTORS.resetButton)
          .should('exist')
          .should('be.visible')
          .should('have.attr', 'mat-flat-button');

        cy.get(SELECTORS.clearButton)
          .should('exist')
          .should('be.visible')
          .should('have.attr', 'mat-flat-button');

        // Loadable layout
        cy.get(SELECTORS.loadableLayout).should('exist');
      });

      it('Should display observer mapping table with correct structure', () => {
        // Table rows should exist
        cy.get(SELECTORS.tableRows).should('have.length.greaterThan', 0);

        // Each row should have 2 cells (observer name and form) with observers form components
        cy.get(SELECTORS.tableRows).each(($row) => {
          cy.wrap($row).find('td').should('have.length', 2);
          cy.wrap($row)
            .find(SELECTORS.observersForm)
            .should('have.attr', 'data-qa', 'import-observersmapping-observers-form');
        });
      });

      it('Should reset mapping when reset button is clicked', () => {
        // Store initial values
        const initialValues = {};

        cy.get(SELECTORS.observersForm).each(($form, index) => {
          cy.wrap($form)
            .find('ng-select .ng-value')
            .invoke('text')
            .then((text) => {
              initialValues[index] = text?.trim() || '';
            });
        });

        cy.wait(500);

        // Now fill with different observer (second option instead of first)
        cy.get(SELECTORS.observersForm).each(($form) => {
          cy.wrap($form)
            .find('ng-select')
            .first()
            .click()
            .then(() => {
              // Select second option instead of first for more meaningful reset test
              cy.get('ng-dropdown-panel').find('.ng-option').eq(1).click({ force: true });
            });

          cy.wait(200);
        });

        cy.wait(500);

        // Verify forms are filled with different values
        cy.get(SELECTORS.observersForm).each(($form) => {
          cy.wrap($form).find('ng-select .ng-value').should('have.length.greaterThan', 0);
        });

        // Now reset all mappings
        cy.get(SELECTORS.resetButton).should('exist').should('be.enabled').click();

        cy.wait(500);

        // Verify all forms are back to their initial state with exact same values
        cy.get(SELECTORS.observersForm).each(($form, index) => {
          cy.wrap($form)
            .find('ng-select .ng-value')
            .invoke('text')
            .then((text) => {
              const currentValue = text?.trim() || '';
              expect(currentValue).to.equal(initialValues[index]);
            });
        });

        // Button should still be visible after click
        cy.get(SELECTORS.resetButton).should('exist').should('be.visible');
      });

      it('Should clear mapping when clear button is clicked', () => {
        // First fill some mappings with a different observer than the first one
        cy.get(SELECTORS.observersForm).each(($form) => {
          cy.wrap($form)
            .find('ng-select')
            .first()
            .click()
            .then(() => {
              // Select second option instead of first
              cy.get('ng-dropdown-panel').find('.ng-option').eq(1).click({ force: true });
            });

          cy.wait(200);
        });

        cy.wait(500);

        // Now clear all mappings
        cy.get(SELECTORS.clearButton).should('exist').should('be.enabled').click();

        cy.wait(500);

        // Verify all forms are empty after clearing
        cy.get(SELECTORS.observersForm).each(($form) => {
          cy.wrap($form).find('ng-select .ng-value').should('have.length', 0);
        });

        // Button should still be visible after click
        cy.get(SELECTORS.clearButton).should('exist').should('be.visible');
      });
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });
});
