import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';

const USER = USERS[0];
const VIEWPORT = VIEWPORTS[0];

function handleFieldValidation(dataQa, paramsName, expectedValue, fieldType) {
  if (['textarea', 'text', 'number'].includes(fieldType)) {
    cy.get(dataQa)
      .find(`[data-qa^="field-${fieldType}-${paramsName}_default_value_"]`)
      .should('have.value', expectedValue);
  } else if (fieldType === 'date') {
    cy.get(dataQa).find('[data-qa="input-date"]').should('have.value', expectedValue);
  } else if (fieldType === 'nomenclature') {
    cy.get(`${dataQa} .ng-value-container .ng-value-label`).should('have.text', expectedValue);
  }
}

const paramsByDestination = [
  {
    destination: 'synthese',
    queryParams: [
      {
        paramsName: 'nom_cite',
        paramsValue: 'test_nomcite',
        fieldType: 'textarea',
        expectedValue: 'test_nomcite',
      },
      {
        paramsName: 'altitude_max',
        paramsValue: 10,
        fieldType: 'number',
        expectedValue: 10,
      },
      {
        paramsName: 'date_min',
        paramsValue: '2024-12-12',
        fieldType: 'date',
        expectedValue: '12/12/2024',
      },
      {
        paramsName: 'id_nomenclature_geo_object_nature',
        paramsValue: 'Inventoriel',
        fieldType: 'nomenclature',
        expectedValue: 'Inventoriel',
      },
    ],
  },
  {
    destination: 'occhab',
    queryParams: [
      {
        paramsName: 'id_nomenclature_determination_type',
        paramsValue: 'Inconnu',
        fieldType: 'nomenclature',
        entityLabel: 'Habitat',
        expectedValue: 'Inconnu',
      },
      // TODO: some fields seems to be not handled to be directly added as default value 
      // {
      //   paramsName: 'nom_cite',
      //   paramsValue: 'test_nomcite',
      //   fieldType: 'taxonomy-input',
      //   entityLabel: 'Habitat',
      //   expectedValue: 'test_nomcite',
      // },
      {
        paramsName: 'station_name',
        paramsValue: 'test_station_name',
        fieldType: 'textarea',
        entityLabel: 'Station',
        expectedValue: 'test_station_name',
      },
    ],
  },
];

describe('Import - Upload step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER.login.username, USER.login.password);
      cy.wait(TIMEOUT_WAIT);
    });

    paramsByDestination.forEach(({ destination, queryParams }) => {
      describe(`Destination: ${destination}`, () => {
        beforeEach(() => {
          const urlParams = queryParams
            .map((param) => `${param.paramsName}=${param.paramsValue}`)
            .join('&');
          cy.visit(`/#/import/${destination}/process/upload?${urlParams}`);
          cy.pickDataset(USER.dataset);
          cy.loadImportFile(FILES[destination].valid.fixture);
          cy.configureImportFile();
        });

        it(`Validates fields for destination: ${destination}`, () => {
          queryParams.forEach(({ paramsName, expectedValue, fieldType, entityLabel }) => {
            let dataQa = `[data-qa="import-fieldmapping-theme-${paramsName}"]`;

            if (destination === 'occhab' && entityLabel) {
              const dataQaEntity = `[data-qa="import-entity-tab-${entityLabel}"]`;
              cy.get(dataQaEntity, { timeout: 30000 })
                .should('be.visible') 
                .click();
            }

            handleFieldValidation(dataQa, paramsName, expectedValue, fieldType);
          });
          cy.visitImport();
          cy.removeFirstImportInList();
        });

      });
    });
  });
});
