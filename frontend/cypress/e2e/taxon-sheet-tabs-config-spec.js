const TAXON_TABS = ['observations', 'taxonomy', 'observers', 'media', 'profile'];

describe('Taxon sheet tabs configuration', () => {
  beforeEach(() => {
    cy.geonatureLogin();
  });

  it('should expose taxon sheet links when ENABLE_TAXON_SHEETS is true', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_TAXON_SHEETS: true,
      },
    });

    cy.openSyntheseList();
    cy.get('[data-qa="synthese-list-taxon-sheet-link"]').should('exist');
  });

  it('should hide taxon sheet links when ENABLE_TAXON_SHEETS is false', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_TAXON_SHEETS: false,
      },
    });

    cy.openSyntheseList();
    cy.get('[data-qa="synthese-list-taxon-sheet-link"]').should('not.exist');
  });

  it('should display all taxon sheet tabs when all flags are true', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_TAXON_SHEETS: true,
        TAXON_SHEET: {
          ENABLE_TAB_OBSERVATIONS: true,
          ENABLE_TAB_TAXONOMY: true,
          ENABLE_TAB_OBSERVERS: true,
          ENABLE_TAB_MEDIA: true,
          ENABLE_TAB_PROFILE: true,
        },
      },
    });

    cy.openTaxonSheet();
    cy.assertTabsVisible(TAXON_TABS);
  });

  it('should hide all taxon sheet tabs when all flags are false', () => {
    cy.interceptGlobalConfig({
      SYNTHESE: {
        ENABLE_TAXON_SHEETS: true,
        TAXON_SHEET: {
          ENABLE_TAB_OBSERVATIONS: false,
          ENABLE_TAB_TAXONOMY: false,
          ENABLE_TAB_OBSERVERS: false,
          ENABLE_TAB_MEDIA: false,
          ENABLE_TAB_PROFILE: false,
        },
      },
    });

    cy.openTaxonSheet();
    cy.assertTabsHidden(TAXON_TABS);
  });
});
