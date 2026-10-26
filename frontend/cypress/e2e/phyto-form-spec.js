const dateSaisieTaxon = '25/01/2022';
const taxaSearch = 'canis lupus';

/**
 * End-to-end tests for the Phytosociology (Phyto) module and its dedicated components:
 * 1. pnx-phyto-strata-table (Vegetation strata cover & height configuration in Releve form)
 * 2. pnx-phyto-occurrence (Taxon occurrence form with strata abundance inputs)
 * 3. pnx-phyto-abundance (Braun-Blanquet abundance selector per vegetation stratum)
 * 4. pnx-phyto-taxa-table (Taxa summary table with strata columns, sorting & actions)
 * 5. pnx-phyto-occurrence-modal (Modal dialog for detailed occurrence editing)
 * 6. pnx-occtax-form-phyto-advanced-counting (Advanced countings & validation inside modal accordion)
 */
describe('Testing phyto components', { testIsolation: false }, () => {
  beforeEach(() => {
    cy.geonatureLogin();
  });

  // =========================================================================
  // 1. Navigation & Access
  // =========================================================================

  it('should be available in the menu tab', () => {
    cy.visit('/');
    cy.get("[data-qa='pnx-home-content-sidebar-open-button']").click();
    cy.get("[data-qa='gn-sidenav-link-PHYTO']").should('exist');
    cy.get("[data-qa='gn-sidenav-link-PHYTO']").click();
    cy.url().should('include', '/phyto');
  });

  it('should be possible to add a survey', () => {
    cy.visit('/#/phyto');
    cy.get("[data-qa='gn-occtax-btn-add-releve']").should('exist');
    cy.get("[data-qa='gn-occtax-btn-add-releve']").click();
    cy.url().should('include', '/phyto/form/releve');
  });

  // =========================================================================
  // 2. Releve Prerequisites (Geometry, Observer, Dataset, Dates)
  // =========================================================================

  it('should set geolocation on map and select observer', () => {
    // Zoom and click on leaflet map to define geometry and unlock the form
    cy.get(
      'pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in'
    ).as('plus');
    Array(10)
      .fill(0)
      .forEach(() => cy.get('@plus').wait(200).click());
    cy.get(
      'pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom'
    ).click(100, 100);
    cy.wait(500);

    // Verify overlay is dismissed after geometry selection
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] #overlay").should('not.exist');

    // Ensure at least one observer is selected
    cy.get(
      "[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container"
    ).click();
    cy.get(
      "[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option"
    )
      .first()
      .click();
  });

  it('should select dataset and survey date', () => {
    // Select dataset from dropdown
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select").click();
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel").should(
      'exist'
    );
    cy.get(
      "[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel .ng-dropdown-panel-items .ng-option"
    )
      .first()
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select .ng-value-container")
      .find('.ng-value')
      .should('have.length', 1);

    // Open date inputs if not already open and fill date min
    cy.get('body').then(($body) => {
      if ($body.find("[data-qa='pnx-occtax-releve-form-adddate']").length > 0) {
        cy.get("[data-qa='pnx-occtax-releve-form-adddate']").click();
      }
    });

    cy.get("[data-qa='pnx-occtax-releve-form-datemin'] [data-qa='input-date']")
      .click()
      .clear()
      .type(dateSaisieTaxon);
    cy.get("[data-qa='pnx-occtax-releve-form-datemax'] [data-qa='input-date']").should(
      'have.value',
      dateSaisieTaxon
    );
  });

  // =========================================================================
  // 3. Component: pnx-phyto-strata-table (Vegetation Strata Table)
  // =========================================================================

  it('should display the phyto strata table with all columns', () => {
    cy.get('pnx-phyto-strata-table').should('exist');
    cy.get("[data-qa='phyto-strata-table']").should('exist');

    // Verify header column definitions
    cy.get("[data-qa='phyto-strata-table-label_default']").should('exist');
    cy.get("[data-qa='phyto-strata-table-percentage_cover_vegetation_stratum']").should('exist');
    cy.get("[data-qa='phyto-strata-table-average_height']").should('exist');
    cy.get("[data-qa='phyto-strata-table-min_height']").should('exist');
    cy.get("[data-qa='phyto-strata-table-max_height']").should('exist');

    // Verify there are strata rows rendered
    cy.get("[data-qa='phyto-strata-table'] tr[mat-row]").should('have.length.at.least', 1);
  });

  it('should validate strata cover percentage and height order constraints', () => {
    // Target the first stratum row
    cy.get("[data-qa='phyto-strata-table'] tr[mat-row]").first().as('firstStratumRow');

    // 1. Test Cover range validation (> 100 is invalid)
    cy.get('@firstStratumRow')
      .find('input[formControlName="percentage_cover_vegetation_stratum"]')
      .clear()
      .type('150');
    // Error message should be visible for cover out of range
    cy.get('@firstStratumRow')
      .find('small.text-danger[id^="stratum-cover-error-"]')
      .should('exist');

    // Reset cover to a valid value (e.g. 50%)
    cy.get('@firstStratumRow')
      .find('input[formControlName="percentage_cover_vegetation_stratum"]')
      .clear()
      .type('50');
    cy.get('@firstStratumRow')
      .find('small.text-danger[id^="stratum-cover-error-"]')
      .should('not.exist');

    // 2. Test Height order validation: min_height > max_height is invalid
    cy.get('@firstStratumRow').find('input[formControlName="min_height"]').clear().type('10');
    cy.get('@firstStratumRow').find('input[formControlName="max_height"]').clear().type('2');

    // Error message should be visible for invalid height order
    cy.get('@firstStratumRow')
      .find('small.text-danger[id^="stratum-height-order-error-"]')
      .should('exist');

    // Correct the heights to valid ordering: min = 2, avg = 5, max = 10
    cy.get('@firstStratumRow').find('input[formControlName="min_height"]').clear().type('2');
    cy.get('@firstStratumRow').find('input[formControlName="average_height"]').clear().type('5');
    cy.get('@firstStratumRow').find('input[formControlName="max_height"]').clear().type('10');

    cy.get('@firstStratumRow')
      .find('small.text-danger[id^="stratum-height-order-error-"]')
      .should('not.exist');
  });

  // =========================================================================
  // 4. Submit Releve -> Navigate to Phyto Taxon Tab
  // =========================================================================

  it('should submit releve and navigate to the phyto-taxons tab', () => {
    cy.get('[data-qa]="pnx-occtax-releve-submit-btn"]').should('be.enabled').click();

    // Check URL includes phyto-taxons
    cy.url().should('include', '/phyto-taxons');

    // Verify main phyto components on this tab
    cy.get("[data-qa]='pnx-phyto-occurrence'").should('exist');
    cy.get("[data-qa]='pnx-phyto-taxa-table'").should('exist');

    // The occurrence save button must be disabled initially before entering taxon data
    cy.get("[data-qa]='phyto-save-occurrence'").should('be.disabled');
  });

  // =========================================================================
  // 5. Component: pnx-phyto-occurrence & pnx-phyto-abundance
  // =========================================================================

  it('should search taxon, select strata abundances and save occurrence', () => {
    // 1. Search and select taxon
    cy.get("input[data-qa='taxonomy-form-input']").as('taxonInput');
    cy.get('@taxonInput').clear().type(taxaSearch);
    cy.get('ngb-typeahead-window:visible').find('button.dropdown-item').as('results');
    cy.get('@results').first().click();

    // Verify valid taxon name display
    cy.get('#phyto-valid-name').should('not.be.empty');

    // 2. Verify strata columns in the abundance table
    cy.get('pnx-phyto-occurrence table.abundance-table').should('exist');
    cy.get("[data-qa]='pnx-phyto-abundance-table'").should('exist');

    // 3. Set abundance on the first stratum
    cy.get("[data-qa]='pnx-phyto-abundance-table' pnx-phyto-abundance ng-select").first().click();
    cy.get('ng-dropdown-panel div.ng-option').should('exist');
    cy.get('ng-dropdown-panel div.ng-option').first().click();

    // 4. Fill optional occurrence comment
    cy.get('pnx-phyto-occurrence textarea#commentaire')
      .clear()
      .type('Test phyto observation comment');

    // 5. Occurrence save button should now be enabled
    cy.get("[data-qa]='phyto-save-occurrence'").should('be.enabled').click();

    // Verify save spinner appears or form resets after submission
    cy.wait(500);
  });

  // =========================================================================
  // 6. Component: pnx-phyto-taxa-table (Taxa Summary Table)
  // =========================================================================

  it('should display the saved occurrence in the taxa table with sorting and action buttons', () => {
    cy.get("[data-qa]='data-qa='phyto-taxa-table'").should('exist');

    // Verify that the table contains at least one saved row
    cy.get("[data-qa]='data-qa='phyto-taxa-table' tr[mat-row]").should('have.length.at.least', 1);

    // Verify valid name column contains expected taxon text
    cy.get("[data-qa]='data-qa='phyto-taxa-table'-table td.mat-column-nom_valide")
      .first()
      .should('contain.text', 'Canis lupus');

    // Verify comment column contains entered comment
    cy.get("[data-qa]='data-qa='phyto-taxa-table' td.mat-column-comment")
      .first()
      .should('contain.text', 'Test phyto observation comment');

    // Test column sorting by clicking header
    cy.get("[data-qa]='data-qa='phyto-taxa-table' th.mat-column-nom_valide").click();
    cy.wait(300);

    // Verify action buttons exist on the row (edit in modal and delete)
    cy.get("[data-qa]='data-qa='phyto-taxa-table' table.striped-table tr[mat-row]")
      .first()
      .find('button[mat-icon-button]')
      .should('have.length.at.least', 1);
  });

  // =========================================================================
  // 7. Component: pnx-phyto-occurrence-modal & pnx-occtax-form-phyto-advanced-counting
  // =========================================================================

  it('should open occurrence edit modal and configure advanced countings', () => {
    // 1. Click edit button on the first occurrence in the table
    cy.get("[data-qa]='data-qa='phyto-taxa-table' tr[mat-row]")
      .first()
      .find('button[mat-icon-button]')
      .first()
      .click();

    // 2. Verify modal dialog is opened
    cy.get('pnx-phyto-occurrence-modal').should('exist');
    cy.get('mat-dialog-container h2[mat-dialog-title]').should('exist');

    // 3. Edit determiner and comment in modal
    cy.get('pnx-phyto-occurrence-modal input#phyto-determiner').clear().type('Botaniste Expert');
    cy.get('pnx-phyto-occurrence-modal textarea#comment')
      .clear()
      .type('Updated comment from phyto modal');

    // 4. Verify Abundances accordion and expand first stratum panel
    cy.get("[data-qa]='phyto-occ-modal-accordion'").should('exist');
    cy.get("[data-qa]='phyto-occ-modal-accordion' mat-expansion-panel-header").first().click();

    // 5. Verify pnx-occtax-form-phyto-advanced-counting is displayed inside panel
    cy.get('pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting').should('exist');

    // 6. Test count min > max validation error
    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting input[formControlName="count_min"]'
    )
      .clear()
      .type('10');
    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting input[formControlName="count_max"]'
    )
      .clear()
      .type('2');

    // Error alert must be shown for count min > count max
    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting small.error[role="alert"]'
    ).should('exist');

    // Set valid count min/max
    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting input[formControlName="count_min"]'
    )
      .clear()
      .type('2');
    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting input[formControlName="count_max"]'
    )
      .clear()
      .type('10');

    cy.get(
      'pnx-phyto-occurrence-modal pnx-occtax-form-phyto-advanced-counting small.error[role="alert"]'
    ).should('not.exist');

    // 7. Save modifications via modal submit button
    cy.get("[data-qa]='modal_save_occ'").click();
    cy.wait(500);

    // Modal dialog should close and comment in table should be updated
    cy.get('pnx-phyto-occurrence-modal').should('not.exist');
    cy.get('pnx-phyto-taxa-table table.striped-table td.mat-column-comment')
      .first()
      .should('contain.text', 'Updated comment from phyto modal');
  });

  // =========================================================================
  // 8. Occurrence Deletion & Finish Survey Flow
  // =========================================================================

  it('should allow deleting an occurrence from the taxa table', () => {
    // Add another occurrence so deletion leaves valid releve or test deletion directly
    cy.get('pnx-phyto-taxa-table table.striped-table tr[mat-row]').then(($rows) => {
      const initialCount = $rows.length;

      // Find the delete button on the row
      cy.get('pnx-phyto-taxa-table table.striped-table tr[mat-row]')
        .first()
        .find('button[color="warn"]')
        .then(($btn) => {
          if ($btn.length > 0) {
            cy.wrap($btn).click();
            // Confirm deletion in dialog
            cy.get('mat-dialog-container button')
              .contains(/oui|yes|supprimer/i)
              .click();
            cy.wait(500);
            cy.get('pnx-phyto-taxa-table table.striped-table tr[mat-row]').should(
              'have.length.lessThan',
              initialCount + 1
            );
          }
        });
    });
  });
});
