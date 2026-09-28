/**
 * Helpers for the `pnx-observers` component (GN2CommonModule/form/observers).
 *
 * The component is a server-side autocomplete: nothing is listed until at least
 * `charNumber` (default 2) non-blank characters are typed, then (after a 300ms debounce)
 * it calls `GET /users/menu/<id>`, `/users/menu/` or `/users/menu_from_code/<code>`
 * with `?nom_complet=<trimmed term>&limit=50`.
 */

import { OBSERVERS_SELECT, USERS_MENU_SEARCH_URL } from './observersConstants';

let aliasCounter = 0;

function observersSelector(container) {
  return container ? `${container} ${OBSERVERS_SELECT}` : OBSERVERS_SELECT;
}

/**
 * Spy on the observers search requests (the ones carrying a `nom_complet` parameter).
 */
Cypress.Commands.add('interceptObserversSearch', (alias = 'observersSearch') => {
  cy.intercept({ method: 'GET', url: USERS_MENU_SEARCH_URL }).as(alias);
});

/**
 * Type `text` in the search input of a `pnx-observers` field (opens the dropdown first).
 *
 * @param {string|null} container CSS selector of an ancestor of the pnx-observers ng-select
 *   (e.g. its host `data-qa`), null if there is only one observers field on the page.
 * @param {string} text text to type
 */
Cypress.Commands.add('typeInObservers', (container, text) => {
  const select = observersSelector(container);
  cy.get(`${select} .ng-select-container`).click();
  cy.get(`${select} .ng-input input`).type(text);
});

/**
 * Search then select an observer in a `pnx-observers` field.
 *
 * @param {string|null} container see `typeInObservers`
 * @param {string} nomComplet `nom_complet` of the observer to select (e.g. 'AGENT test')
 * @param {string} [searchTerm] text typed in the field; defaults to the first word of
 *   `nomComplet` (at least 2 characters are required to trigger the search)
 */
Cypress.Commands.add('selectObserver', (container, nomComplet, searchTerm) => {
  const term = searchTerm || nomComplet.split(' ')[0];
  expect(term.trim().length, 'observers search term length').to.be.at.least(2);

  const select = observersSelector(container);
  const alias = `observersSearch${aliasCounter++}`;
  cy.interceptObserversSearch(alias);

  cy.typeInObservers(container, term);
  cy.wait(`@${alias}`).then(({ request, response }) => {
    expect(request.query.nom_complet).to.equal(term.trim());
    expect(response.statusCode).to.equal(200);
    expect(response.body.map((role) => role.nom_complet)).to.include(nomComplet);
  });

  cy.get(`${select} [data-qa="gn-common-form-observers-select-${nomComplet}"]`)
    .should('be.visible')
    .click();
  cy.get(`${select} .ng-value-container .ng-value-label`).should('contain', nomComplet);
});
