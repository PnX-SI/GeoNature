Cypress.Commands.add('geonatureLogout', () => {
  cy.request({
    method: 'GET',
    url: `${Cypress.env('apiEndpoint')}auth/logout`,
  });
});
