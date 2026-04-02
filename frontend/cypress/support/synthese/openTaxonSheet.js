Cypress.Commands.add('openTaxonSheet', () => {
  cy.openSyntheseList();

  cy.get('[data-qa="synthese-list-taxon-sheet-link"]')
    .first()
    .should('have.attr', 'href')
    .then((href) => {
      cy.visit(href);
    });

  cy.location('hash').should('match', /#\/synthese\/taxon\/.+/);
});
