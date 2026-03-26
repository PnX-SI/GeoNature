Cypress.Commands.add('interceptGlobalConfig', (overrides) => {
  cy.request('GET', `${Cypress.env('apiEndpoint')}gn_commons/config`).then((response) => {
    const config = response.body;
    const syntheseOverrides = overrides.SYNTHESE || {};
    const mockedConfig = {
      ...config,
      SYNTHESE: {
        ...config.SYNTHESE,
        ...syntheseOverrides,
        TAXON_SHEET: {
          ...config.SYNTHESE.TAXON_SHEET,
          ...(syntheseOverrides.TAXON_SHEET || {}),
        },
        OBSERVER_SHEET: {
          ...config.SYNTHESE.OBSERVER_SHEET,
          ...(syntheseOverrides.OBSERVER_SHEET || {}),
        },
      },
    };

    cy.intercept('GET', '**/gn_commons/config*', mockedConfig).as('globalConfig');
  });
});
