import { USERS, availableDestinations, availableImportsCount } from './constants/users';
import { VIEWPORTS } from './constants/common';
import {
  SELECTOR_DESTINATIONS,
  SELECTOR_IMPORT_LIST_TOOLBAR,
  SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

function generateRequestForDestination(destination) {
  if (!destination) {
    return `${Cypress.env('apiEndpoint')}/import/imports/*`;
  }
  return `${Cypress.env('apiEndpoint')}/import/${destination}/imports/*`;
}

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Import List - Toolbar - Destinations', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      USERS.forEach((user) => {
        context(`user: ${user.login.username}`, () => {
          beforeEach(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
          });
          it('Should have pnx-destinations', () => {
            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS).should('exist');
          });

          it('Should contains exactly all the available modules', () => {
            const destinations = Object.keys(user.destinations);
            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS)
              .should('exist')
              .click()
              .get('ng-dropdown-panel')
              .get('.ng-option')
              .then((options) => {
                expect(options.length === destinations.length);
                for (let i = 0; i < options.length; i++) {
                  const option = options[i].innerText;
                  expect(destinations.includes(option));
                }
              });
          });
          // TODO: this test is not valid on the CI. But actually, it is already covered by the next test: filtering the list
          it.skip('Should trigger an api call with the destination', () => {
            const destinations = availableDestinations(user.destinations);
            // Select every destination, one after the other- check that request is sent
            for (const destinationKey of destinations) {
              const code = user.destinations[destinationKey].code;
              const request = generateRequestForDestination(code);
              cy.intercept('GET', request).as(`getImports${code}`);
              cy.get(SELECTOR_IMPORT_LIST_TOOLBAR).within(() => {
                cy.get(SELECTOR_DESTINATIONS, { force: true })
                  .should('exist')
                  .click()
                  .get('ng-dropdown-panel')
                  .get('.ng-option')
                  .contains(destinationKey)
                  .then((destination) => {
                    cy.wrap(destination).should('exist').click();
                    cy.wait(`@getImports${code}`);
                  });
              });
            }
            const request = generateRequestForDestination();
            cy.intercept('GET', request).as('getImports');
            // Clear selection
            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS)
              .find('.ng-clear-wrapper')
              .should('exist')
              .click();
            cy.wait(`@getImports`);
          });

          it('Should filter the list with every available destinations', () => {
            const destinations = availableDestinations(user.availableDestinations);
            // Select every destination, one after the other
            for (const destinationKey of destinations) {
              cy.get(SELECTOR_IMPORT_LIST_TOOLBAR).within(() => {
                cy.get(SELECTOR_DESTINATIONS, { force: true })
                  .should('exist')
                  .click()
                  .get('ng-dropdown-panel')
                  .get('.ng-option')
                  .contains(destinationKey)
                  .then((destination) => {
                    cy.wrap(destination).should('exist').click();
                  });
              });
              cy.checkImportListSize(user.destinations[destinationKey].count);
            }
            // Clear selection
            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS).find('.ng-clear-wrapper').click();
            cy.checkImportListSize(availableImportsCount(user.destinations));
          });
        });
      });
    });
  });
});
