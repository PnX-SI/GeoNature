const DEFAULT_LOGIN = {
  username: 'admin',
  password: 'admin',
};

Cypress.Commands.add('geonatureLogin', (username, password) => {
  if (!username || !password) {
    ({ username, password } = DEFAULT_LOGIN);
  }
  cy.session([username, password], () => {
    cy.request({
      method: 'POST',
      url: `${Cypress.env('apiEndpoint')}auth/login`,
      body: {
        login: username,
        password: password,
      },
    })
      .its('body')
      .then((body) => {
        window.localStorage.setItem('gn_expires_at', body.expires);
        window.localStorage.setItem('gn_id_token', body.token);
        window.localStorage.setItem('gn_current_user', JSON.stringify(body.user));
      });
    cy.log('Logged with: ' + username);
  });
});
