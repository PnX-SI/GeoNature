import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common"
// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

function generateRequestForDestination(destination) {
  if (!destination) {
    return `${Cypress.env('apiEndpoint')}/import/imports/*`
  }
  return `${Cypress.env('apiEndpoint')}/import/${destination}/imports/*`
}

function availableDestinations(destinations) {
  return Object.keys(destinations);
}
function availableImportsCount(destinations) {
  return Object.values(destinations).reduce((partialSum, item) => partialSum + item.count, 0);
}

describe("Import List - Toolbar - Destinations", () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      USERS.forEach((user) => {
        context(`user: ${user.login.username}`, () => {

          beforeEach(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
          })
          it('Should have pnx-destinations', () => {
            cy.get("[data-qa=import-list-toolbar-destinations]").should('exist');
          })

          it('Should contains exactly all the available modules', () => {
            const destinations = Object.keys(user.destinations);
            cy.get("[data-qa=import-list-toolbar-destinations]").should('exist').click()
              .get("ng-dropdown-panel")
              .get(".ng-option").then(options => {
                expect(options.length === destinations.length)
                for (let i = 0; i < options.length; i++) {
                  const option = options[i].innerText;
                  expect(destinations.includes(option))
                }
              })
          });
          it('Should trigger an api call with the destination', () => {
            const destinations = availableDestinations(user.destinations);
            // Select every destination, one after the other- check that request is sent
            for (const destinationKey of destinations) {
              const code = user.destinations[destinationKey].code;
              const request = generateRequestForDestination(code);
              cy.intercept("GET", request).as(`getImports${code}`);
              cy.get('[data-qa="import-list-toolbar-destinations"] > [data-qa="destinations"]').should('exist').click()
                .get("ng-dropdown-panel")
                .get(".ng-option").contains(destinationKey).then((destination) => {
                  cy.wrap(destination).should('exist').click();
                  cy.wait(`@getImports${code}`)
                });
            }
            const request = generateRequestForDestination();
            cy.intercept("GET", request).as('getImports');
            // Clear selection
            cy.get("[data-qa=import-list-toolbar-destinations]").find(".ng-clear-wrapper").should('exist').click();
            cy.wait(`@getImports`);
          });

          it('Should filter the list with every available destinations', () => {
            const destinations = availableDestinations(user.destinations);
            // Select every destination, one after the other
            for (const destinationKey of destinations) {
              cy.get('[data-qa="import-list-toolbar-destinations"] > [data-qa="destinations"]').should('exist').click()
                .get("ng-dropdown-panel")
                .get(".ng-option").contains(destinationKey).then((destination) => {
                  cy.wrap(destination).should('exist').click();
                  cy.checkImportListSize(user.destinations[destinationKey].count)
                });
            }
            // Clear selection
            cy.get("[data-qa=import-list-toolbar-destinations]").find(".ng-clear-wrapper").click();
            cy.checkImportListSize(availableImportsCount(user.destinations));
          });
        });
      });
    });
  });
});
