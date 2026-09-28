import promisify from 'cypress-promise';
import {
  OBSERVERS_DEBOUNCE_WAIT,
  OBSERVERS_MIN_CHARS_MESSAGE,
  USERS_MENU_URL,
} from '../support/common/observersConstants';

describe('Testing metadata', () => {
  const cadreAcq = 'CA-1';
  const jdd = 'JDD-1';
  const jddUUID = '4d331cae-65e4-4948-b0b2-a11bc5bb46c2';
  const caUUID = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5';
  const caSelector = '[data-qa="pnx-metadata-acq-framework-' + caUUID + '"]';
  const ORGANISM_SELECT_FORM = '.organism-form > .auto > .ng-select-container';
  const newCadreAcq = {
    name: 'CA-created',
    // name:'Mon cadre d\'acquisition',
    description: "description de mon cadre d'acquisition",
    startDate: '17/03/2022',
    testAdditionalFieldValue: 'test de valeur',
  };
  const newJdd = {
    name: 'Mon jeu de données',
    shortname: 'Mon jdd',
    description: 'description de mon jdd',
    testAdditionalFieldValue: 'test de valeur',
  };

  const actorPerson = { nomComplet: 'AGENT test', searchTerm: 'agent' };

  let newOrganism = {
    name: 'Ma structure 2',
    email: 'mastructure2@example.com',
  };

  beforeEach(() => {
    cy.geonatureLogin();
    cy.visit('/#/metadata');
  });

  it('should display "cadre d\'acquisition"', async () => {
    // const listCadreAcq = await promisify(cy.get("[data-qa='pnx-metadata-acq-framework']"));
    const wantedCA = await promisify(cy.get(caSelector));
    // listCadreAcq[0].firstChild.firstChild.firstChild.children[1].innerText;
    expect(wantedCA[0].innerText).to.equal('CA-1\n57b7d0f2-4183-4b7b-8f08-6e105d476dc5');
    // expect(firstCadreAcqIntitule).to.equal("Données d'observation de la faune, de la Flore et de la fonge du Parc national des Ecrins\n57b7d0f2-4183-4b7b-8f08-6e105d476dc5")
  });

  it('should display the first "cadre d\'acquisition"', () => {
    cy.get(caSelector).click();
    cy.get('[data-qa="pnx-metadata-acq-framework-name"]').contains(cadreAcq);
    cy.get('[data-qa="pnx-metadata-exit-af"]').click();
  });

  it('should display "jeu de données"', () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').contains(jdd);
    cy.get('[data-qa="pnx-metadata-jdd-actif-' + jddUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-jdd-delete-' + jddUUID + '"]').should('be.disabled');

    // go to the JDD detail page
    cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(jdd);
    cy.get('[data-qa="pnx-metadata-exit-jdd"]').click();
  });

  it('should search a JDD and find it"', { defaultCommandTimeout: 60000 }, () => {
    cy.get('[data-qa="pnx-metadata-search"]').type(jdd);
    //http://127.0.0.1:8000/meta/acquisition_frameworks?datasets=0&creator=1&actors=1
    cy.intercept(Cypress.env('apiEndpoint') + 'meta/acquisition_frameworks?**', (req) => {
      cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click();
      cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').contains(jdd);
    });
  });
  it('should search the person filter server-side, only with enough non-blank characters', () => {
    // Count every /users/menu* call made by the person filter (pnx-observers)
    const usersMenuCalls = [];
    cy.intercept({ method: 'GET', url: USERS_MENU_URL }, (req) => {
      usersMenuCalls.push(req.query);
    }).as('usersMenu');

    const personField = '[data-qa="pnx-metadata-search-person"]';
    const personSelect = `${personField} [data-qa="gn-common-form-observers-select"]`;

    // Open the advanced search modal (button next to the reset button)
    cy.get('[data-qa="pnx-metadata-refresh"]').siblings('button').first().click();
    cy.get(personSelect).should('be.visible');

    // Nothing is listed nor requested before typing
    cy.get(`${personSelect} .ng-select-container`).click();
    cy.get(`${personSelect} ng-dropdown-panel`).should('contain', OBSERVERS_MIN_CHARS_MESSAGE);

    // Whitespace-only input: no request, still the "type at least N characters" hint
    cy.get(`${personSelect} .ng-input input`).type('     ');
    cy.wait(OBSERVERS_DEBOUNCE_WAIT);
    cy.then(() => expect(usersMenuCalls, 'no /users/menu call on blank input').to.have.length(0));
    cy.get(`${personSelect} ng-dropdown-panel`).should('contain', OBSERVERS_MIN_CHARS_MESSAGE);
    cy.get(`${personSelect} [data-qa^="gn-common-form-observers-select-"]`).should('not.exist');

    // A single non-blank character (surrounded by spaces) is still too short
    cy.get(`${personSelect} .ng-input input`).type('a ');
    cy.wait(OBSERVERS_DEBOUNCE_WAIT);
    cy.then(() => expect(usersMenuCalls, 'no /users/menu call under 2 chars').to.have.length(0));
    cy.get(`${personSelect} ng-dropdown-panel`).should('contain', OBSERVERS_MIN_CHARS_MESSAGE);

    // 2+ non-blank characters: exactly one request, with the trimmed term
    cy.get(`${personSelect} .ng-input input`).clear().type('  adm  ');
    cy.wait('@usersMenu').then(({ request, response }) => {
      expect(request.query.nom_complet).to.equal('adm');
      expect(response.statusCode).to.equal(200);
      expect(response.body.map((role) => role.nom_complet)).to.include('ADMINISTRATEUR test');
    });
    cy.wait(OBSERVERS_DEBOUNCE_WAIT);
    cy.then(() => expect(usersMenuCalls, 'one debounced /users/menu call').to.have.length(1));

    // Pick the result and use it as a search filter
    cy.get(`${personSelect} [data-qa="gn-common-form-observers-select-ADMINISTRATEUR test"]`)
      .should('be.visible')
      .click();
    cy.get(`${personSelect} .ng-value-label`).should('contain', 'ADMINISTRATEUR test');

    cy.intercept('POST', '**/meta/acquisition_frameworks*').as('afSearch');
    cy.get('.modal-body button.button-success').click();
    cy.wait('@afSearch').its('request.body.person').should('be.a', 'number');
  });

  it('should create a new "cadre d\'acquisition"', () => {
    // cy.visit('/#/metadata');
    // Generate a new organism based on newOrganism but with a slight modification
    newOrganism = {
      name: newOrganism.name + (Math.floor(Math.random() * 100) + 1).toString(),
      email: newOrganism.email,
    };

    cy.get('[data-qa="pnx-metadata-add-af"]').click();

    // Create a new organism, later used for the creation of the new JDD
    cy.get('[data-qa="pnx-organism-create-button"]').click();
    cy.get('[data-qa="pnx-organism-form-dialog-name"]').type(newOrganism.name);
    //    Verify that the organism 'ma structure test' is displayed in the list of similar organisms
    cy.get('[data-qa="pnx-organism-form-dialog-similar-list"] li').should('have.length.least', 1);
    const similarOrganismDiv = cy
      .get('[data-qa="pnx-organism-form-dialog-similar-list"] span')
      .filter((index, el) => {
        return Cypress.$(el).text() === 'ma structure test';
      });
    similarOrganismDiv.click();
    const similarOrganismAddress = cy
      .get('[data-qa="pnx-organism-form-dialog-similar-org-address"]')
      .filter((index, el) => {
        return Cypress.$(el).text() === ' Rue des bois ';
      });

    similarOrganismAddress.should('be.visible');
    //    Complete the form with an email, and submit
    cy.get('mat-dialog-content').scrollTo('bottom');
    cy.get('[data-qa="pnx-organism-form-dialog-email"]').type(newOrganism.email, {
      force: true,
    });
    cy.get('[data-qa="organism-dialog-save"]').click();

    cy.get(ORGANISM_SELECT_FORM).click();
    cy.get('[data-qa="pnx-metadata-organism-ALL"]').click();
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get("[data-qa='pnx-metadata-af-form-name']").type(newCadreAcq.name);
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get('[data-qa="pnx-metadata-af-form-description"]').type(newCadreAcq.description);
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get(
      "[data-qa='pnx-metadata-af-form-territory'] > ng-select > div > div > div.ng-input"
    ).click();
    cy.get('[data-qa="METROP"]').click();
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get(
      "[data-qa='pnx-metadata-af-form-territory-level'] > ng-select > div > div > div.ng-input"
    ).click();
    cy.get('[data-qa="3"]').click();
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get(
      "[data-qa='pnx-metadata-af-form-objectif'] > ng-select > div > div > div.ng-input"
    ).click();
    cy.get('[data-qa="10"]').click();
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get(
      "[data-qa='pnx-metadata-af-form-financing-type'] > ng-select > div > div > div.ng-input"
    ).click();
    cy.get('[data-qa="4"]').click();
    cy.get("[data-qa='pnx-metadata-save-af']").should('be.disabled');

    cy.get('[data-qa="pnx-metadata-af-form-start-date"] [data-qa="input-date"]')
      .click()
      .type(newCadreAcq.startDate);

    cy.get("[data-qa='field-text-test_champs_additionnel']")
      .click()
      .type(newCadreAcq.testAdditionalFieldValue);

    cy.get("[data-qa='pnx-metadata-save-af']").click();

    cy.get('[data-qa="pnx-metadata-acq-framework-name"]').contains(newCadreAcq.name);
    cy.get('[data-qa="pnx-metadata-additional-field-test_champs_additionnel"]').contains(
      newCadreAcq.testAdditionalFieldValue
    );
  });

  it('should create a new "jeu de données"', () => {
    cy.visit('/#/metadata');
    cy.get('[data-qa="pnx-metadata-add-jdd"]').click();

    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get(ORGANISM_SELECT_FORM).click();
    cy.get('[data-qa="pnx-metadata-organism-ALL"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    // Add a second main contact, the new organism created before from AF form
    cy.get('[data-qa="pnx-dataset-form-add-main-contact"]').click();
    cy.get('pnx-metadata-actor').eq(1).find('ng-select > div > div > div.ng-input').click();
    cy.get('[data-qa="pnx-metadata-organism-' + newOrganism.name + '"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    // ... also linked to a person (organism + person), searched server-side in pnx-observers
    cy.get('pnx-metadata-actor').eq(1).find('mat-button-toggle[value="all"] button').click();
    cy.selectObserver(
      'pnx-metadata-actor:eq(1) [data-qa="pnx-metadata-actor-person"]',
      actorPerson.nomComplet,
      actorPerson.searchTerm
    );
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-select-cadre-acq"]').click();
    cy.get('[data-qa="pnx-metadata-jdd-' + cadreAcq + '"]').click({ force: true });
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-input-jdd-name"]').type(newJdd.name);
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-input-jdd-shortname"]').type(newJdd.shortname);
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-input-jdd-description"]').type(newJdd.description);
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get("[data-qa='pnx-dataset-form-datatype'] > ng-select > div > div > div.ng-input").click();
    cy.get('[data-qa="5"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get(
      '[data-qa="pnx-dataset-form-status-source"] > ng-select > div > div > div.ng-input'
    ).click();
    cy.get('[data-qa="Co"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-objectif"] > ng-select > div > div > div.ng-input').click();
    cy.get('[data-qa="7.2"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get(
      '[data-qa="pnx-dataset-form-territories"] > ng-select > div > div > div.ng-input'
    ).click();
    cy.get('[data-qa="CLI"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get(
      '[data-qa="pnx-dataset-form-collecting-method"] > ng-select > div > div > div.ng-input'
    ).click();
    cy.get('[data-qa="12"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get(
      '[data-qa="pnx-dataset-form-data-origin"] > ng-select > div > div > div.ng-input'
    ).click();
    cy.get('[data-qa="NSP"]').click();
    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('[data-qa="pnx-dataset-form-resource-type"] > ng-select > div').click();
    cy.get('[data-qa="1"]').click();

    cy.get("[data-qa='field-text-test_champs_additionnel']")
      .click()
      .type(newJdd.testAdditionalFieldValue);

    cy.intercept('POST', '**/meta/dataset').as('createDataset');
    cy.get('[data-qa="pnx-dataset-form-save-jdd"]').click();
    cy.wait('@createDataset').then(({ request, response }) => {
      expect(response.statusCode).to.equal(200);
      const personActors = request.body.cor_dataset_actor.filter((actor) => actor.id_role);
      expect(personActors).to.have.length(1);
    });

    cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(newJdd.name);
    cy.get('[data-qa="pnx-metadata-additional-field-test_champs_additionnel"]').contains(
      newJdd.testAdditionalFieldValue
    );
    cy.get('[data-qa="pnx-metadata-exit-jdd"]').click();
  });

  it('should delete the new "jeu de données"', () => {
    // Search for the parent CA
    cy.get('[data-qa="pnx-metadata-search"]').clear();
    cy.get('[data-qa="pnx-metadata-search"]').type(cadreAcq);

    // Wait for the parent CA to display and click to display its JDD
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]')
      .should('be.visible')
      .click();

    // Search and click on the delete button for the new JDD
    cy.get('[data-qa="pnx-metadata-dataset-name-' + newJdd.name + '"] td > button').click({
      multiple: true,
      force: true,
    });

    // Intercept the delete request to know when it completes
    cy.intercept('DELETE', '**/meta/dataset/*').as('deleteDataset');

    // Wait for and confirm the deletion dialog
    cy.get('[data-qa="confirmation-dialog-yes"]').should('be.visible').click({
      multiple: true,
      force: true,
    });

    // Wait for the dialog to close and the API call to complete
    cy.get('[data-qa="confirmation-dialog-yes"]').should('not.exist');
    cy.wait('@deleteDataset');

    // Verify the new JDD is no longer present while the remaining JDD is visible
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]')
      .should('be.visible')
      .click();
    cy.get('[data-qa="pnx-metadata-dataset-name-' + jdd + '"]').should('be.visible');
    cy.get('[data-qa="pnx-metadata-dataset-name-' + newJdd.name + '"]').should('not.exist');
  });

  it('should delete the new "cadre d\'acquisition"', () => {
    // Find the panel that contains the CA name and click its delete button
    cy.contains('mat-expansion-panel', newCadreAcq.name)
      .find('[data-qa="gn-button-delete-af"]')
      .click({
        force: true,
        multiple: true,
      });

    // Wait for and confirm the deletion dialog
    cy.get('[data-qa="confirmation-dialog-yes"]').should('be.visible').click({
      force: true,
      multiple: true,
    });
    // Wait for the dialog to close
    cy.get('[data-qa="confirmation-dialog-yes"]').should('not.exist');

    // Verify the new CA is no longer present while the old CA is visible
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').should('be.visible');
    cy.contains('mat-expansion-panel', newCadreAcq.name).should('not.exist');
  });

  it('should display data of the dataset in synthese', () => {
    cy.visit('/#/metadata');
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click({ force: true });
    cy.get('[data-qa="pnx-metadata-jdd-display-data-' + jddUUID + '"]').click({ force: true });
    cy.url().should('include', 'synthese?id_dataset=');
  });
});
