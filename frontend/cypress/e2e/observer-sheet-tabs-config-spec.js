const OBSERVER_TABS = ['observations', 'taxa', 'medias'];

describe('Observer sheet tabs configuration', () => {
  beforeEach(() => {
    cy.geonatureLogin();
  });

  it('should allow observer sheet access when ENABLE_OBSERVER_SHEETS is true', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_OBSERVER_SHEETS: true,
      },
    });

    cy.openObserverSheet();
    cy.get('[data-qa="tabs-layout-nav"]').should('exist');
  });

  it('should redirect observer sheet access to 404 when ENABLE_OBSERVER_SHEETS is false', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_OBSERVER_SHEETS: false,
      },
    });

    cy.visit('/#/');
    cy.wait('@globalConfig');

    cy.window().then((win) => {
      const currentUser = JSON.parse(win.localStorage.getItem('gn_current_user'));
      cy.visit(`/#/synthese/observer/${currentUser.id_role}`);
    });

    cy.get('[data-qa="page-not-found-title"]').should('exist');
  });

  it('should display all observer sheet tabs when all flags are true', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_OBSERVER_SHEETS: true,
        OBSERVER_SHEET: {
          ENABLE_TAB_OBSERVATIONS: true,
          ENABLE_TAB_TAXA: true,
          ENABLE_TAB_MEDIA: true,
        },
      },
    });

    cy.openObserverSheet();
    cy.assertTabsVisible(OBSERVER_TABS);
  });

  it('should hide all observer sheet tabs when all flags are false', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_OBSERVER_SHEETS: true,
        OBSERVER_SHEET: {
          ENABLE_TAB_OBSERVATIONS: false,
          ENABLE_TAB_TAXA: false,
          ENABLE_TAB_MEDIA: false,
        },
      },
    });

    cy.openObserverSheet();
    cy.assertTabsHidden(OBSERVER_TABS);
  });
});
