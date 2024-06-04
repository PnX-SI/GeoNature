const DESTINATIONS_PROPERTIES = {
  "Synthèse": {
    count: 1,
    code: "synthese"
  },
  "Occhab": {
    count: 1,
    code: "occhab"
  }
}
const AVAILABLE_DESTINATIONS = Object.keys(DESTINATIONS_PROPERTIES);
const AVAILABLE_IMPORTS_COUNT = Object.values(DESTINATIONS_PROPERTIES).reduce((partialSum, item) => partialSum + item.count, 0);

import { checkImportListSize } from "./list-utils";

function generateRequestForDestination(destination){
  if (!destination) {
    return `${Cypress.env('apiEndpoint')}/import/imports/*`
  }
  return `${Cypress.env('apiEndpoint')}/import/${destination}/imports/*`
}

describe('Import List - Toolbar - Destinations', () => {
  beforeEach(() => {
    cy.geonatureInitImportList()
  });

  it('Should have pnx-destinations', () => {
    cy.get("[data-qa=import-list-toolbar-destinations]").should('exist');
  })

  it('Should contains exactly all the available modules', () => {
    cy.get("[data-qa=import-list-toolbar-destinations]").click()
      .get("ng-dropdown-panel")
      .get(".ng-option").then(options => {
        expect(options.length === AVAILABLE_DESTINATIONS.length)
        for (let i = 0; i < options.length; i++){
          const option = options[i].innerText;
          expect(AVAILABLE_DESTINATIONS.includes(option))
        }
      })
  })
  it('Should trigger an api call with the destination', () => {
    // Select every destination, one after the other- check that request is sent
    for (const destinationAvailable of AVAILABLE_DESTINATIONS) {
      const code = DESTINATIONS_PROPERTIES[destinationAvailable].code;
      const request = generateRequestForDestination(code);
      cy.intercept("GET", request).as(`getImports${code}`);
      cy.get("[data-qa=import-list-toolbar-destinations]").click()
        .get("ng-dropdown-panel")
        .get(".ng-option").contains(destinationAvailable).then((destination) => {
          cy.wrap(destination).click();
          cy.wait(`@getImports${code}`)
        });
    }
    const request = generateRequestForDestination();
    cy.intercept("GET", request).as('getImports');
    // Clear selection
    cy.get("[data-qa=import-list-toolbar-destinations]").get(".ng-clear-wrapper").click();
    cy.wait(`@getImports`);
  })

  it('Should filter the list with every available destinations', () => {
    // Select every destination, one after the other
    for (const destinationAvailable of AVAILABLE_DESTINATIONS) {
      cy.get("[data-qa=import-list-toolbar-destinations]").click()
        .get("ng-dropdown-panel")
        .get(".ng-option").contains(destinationAvailable).then((destination) => {
          cy.wrap(destination).click();
          checkImportListSize(DESTINATIONS_PROPERTIES[destinationAvailable].count)
        });
    }
    // Clear selection
    cy.get("[data-qa=import-list-toolbar-destinations]").get(".ng-clear-wrapper").click();
    checkImportListSize(AVAILABLE_IMPORTS_COUNT)
  })
})
