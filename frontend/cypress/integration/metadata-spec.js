import promisify from 'cypress-promise';

describe('Testing metadata', () => {
  const cadreAcq = 'CA-1';
  const jdd = ' JDD-1 ';
  const jddUUID = '4d331cae-65e4-4948-b0b2-a11bc5bb46c2';
  const caUUID = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5';
  const caSelector = '[data-qa="pnx-metadata-acq-framework-' + caUUID + '"]';

  const newCadreAcq = {
    name: 'CA-created',
    // name:'Mon cadre d\'acquisition',
    description: "description de mon cadre d'acquisition",
    startDate: '17/03/2022',
  };
  const newJdd = {
    name: 'Mon jeu de données',
    shortname: 'Mon jdd',
    description: 'description de mon jdd',
  };

  before(() => {
    cy.geonatureLogout();
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

  it('should display "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').contains(jdd);
    cy.get('[data-qa="pnx-metadata-jdd-actif-' + jddUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-jdd-nb-obs-' + jddUUID + '"]').contains('3');
    cy.get('[data-qa="pnx-metadata-jdd-delete-' + jddUUID + '"]').should('be.disabled');
  });

  it('should display the first "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(jdd);
    cy.get('[data-qa="pnx-metadata-exit-jdd"]').click();
  });

  it('should display the good "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-search"]').type(jdd);
    cy.get('[data-qa="pnx-metadata-jdd-' + jddUUID + '"]').contains(jdd);
    cy.get('[data-qa="pnx-metadata-jdd-actif-' + jddUUID + '"]').click({ force: true });
  });

  it('should create a new "cardre d\'acquisition"', () => {
    cy.get('[data-qa="pnx-metadata-add-af"]').click();

    cy.get('pnx-metadata-actor > div > form > ng-select > div > div > div.ng-input').click();
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
    cy.get("[data-qa='pnx-metadata-save-af']").click();
  });

  it('should new "jeux de données" created', () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-name"]').contains(newCadreAcq.name);
  });

  it('should create a new "jeux de données"', () => {
    cy.visit('/#/metadata');
    cy.get('[data-qa="pnx-metadata-add-jdd"]').click();

    cy.get("[data-qa='pnx-dataset-form-save-jdd'] ").should('be.disabled');

    cy.get('pnx-metadata-actor > div > form > ng-select > div > div > div.ng-input').click();
    cy.get('[data-qa="pnx-metadata-organism-ALL"]').click();
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

    cy.get('[data-qa="pnx-dataset-form-save-jdd"]').click();
  });

  it('should new "jeux de données" created', () => {
    cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(newJdd.name);
    cy.get('[data-qa="pnx-metadata-exit-jdd"]').click();
  });

  it('should delete the new "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-search"]').clear();
    cy.get('[data-qa="pnx-metadata-search"]').type(newJdd.name);
    cy.wait(2000);
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click();
    cy.get('[data-qa="pnx-metadata-dataset-name-' + newJdd.name + '"] td > button').click({
      multiple: true,
      force: true,
    });
  });

  it('should display data of the dataset in synthese', () => {
    cy.visit('/#/metadata');
    cy.get('[data-qa="pnx-metadata-acq-framework-header-' + caUUID + '"]').click({ force: true });
    cy.get('[data-qa="pnx-metadata-jdd-display-data-' + jddUUID + '"]').click({ force: true });
    cy.url().should('include', 'synthese?id_dataset=');
  });
});
