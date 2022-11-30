describe('Testing Leaflet control layers', () => {
  const controlSelector = '.leaflet-control-layers';
  const controlExpandedSelector = `.leaflet-control-layers-expanded`;
  const overlayersTitleSelector = '.title-overlay';
  // Go to home page
  before(() => {
    cy.geonatureLogout();
    cy.geonatureLogin();
    cy.visit('/#/');
  });
  it('should display "overlayers button controler"', () => {
    cy.get(controlSelector).should('be.visible');
    cy.get(controlSelector).trigger('mouseover');
    cy.get(controlExpandedSelector).should('be.visible');
  });
  it('should control "overlayers content"', () => {
    cy.get(overlayersTitleSelector).should('have.length', 4);
    cy.get(overlayersTitleSelector).first().should('contains.text', 'Znieff de Bretagne');
  });
});
