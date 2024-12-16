import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';

const USER = USERS[0];
const VIEWPORT = VIEWPORTS[0];

function testQueryParamField(dataQa, paramName, expectedValue, fieldType) {
  if (fieldType === 'textarea' || fieldType === 'text' || fieldType === 'number') {
    cy.get(dataQa)
      .find(`[data-qa^="field-${fieldType}-${paramName}_default_value_"]`)
      .should('have.value', expectedValue);
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
        isTypeComp: false,
        expectedValue: 'test_nomcite',
      },
      {
        paramsName: 'altitude_max',
        paramsValue: 10,
        fieldType: 'number',
        isTypeComp: false,
        expectedValue: 10,
      },
      {
        paramsName: 'date_min',
        paramsValue: '2024-12-12',
        fieldParentType: 'field-date',
        fieldType: 'date',
        isTypeComp: true,
        expectedValue: '12/12/2024',
      },
      {
        paramsName: 'id_nomenclature_geo_object_nature',
        paramsValue: 'Inventoriel',
        fieldParentType: 'field-nomenclature',
        fieldType: 'nomenclature',
        isTypeComp: true,
        expectedValue: 'Inventoriel',
      },
    ],
  },
  //   {
  //     destination: 'occhab',
  //     queryParams: [
  //       { paramsName: 'nom_cite', paramsValue: 'test_nomcite' },
  //       { paramsName: 'date_min', paramsValue: '2024-12-12' },
  //     ],
  //   },
];

describe('Import - Upload step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER.login.username, USER.login.password);
      cy.wait(TIMEOUT_WAIT);
    });

    paramsByDestination.forEach(({ destination, queryParams }) => {
      it(`Should handle for destination: ${destination}`, () => {
        const urlParams = queryParams
          .map((param) => `${param.paramsName}=${param.paramsValue}`)
          .join('&');
        cy.visit(`/#/import/${destination}/process/upload?${urlParams}`);

        cy.pickDataset(USER.dataset);
        cy.loadImportFile(FILES.synthese.valid.fixture);
        cy.configureImportFile();

        queryParams.forEach(({ paramsName, paramsValue, fieldType, isTypeComp, expectedValue }) => {
          let dataQa = `[data-qa="import-fieldmapping-theme-${paramsName}"]`;

          // Récupérer et vérifier la valeur en fonction du type de champ
          if (!isTypeComp) {
            testQueryParamField(dataQa, paramsName, expectedValue, fieldType);
          } else if (fieldType === 'date' || fieldType === 'nomenclature') {
            // Si c'est un champ de type 'date' ou 'nomenclature'
            dataQa = `[data-qa="field-${fieldType}-${paramsName}_default_value"]`;
            cy.get(dataQa)
              .find(`input`)
              .each(($el) => cy.wrap($el).scrollIntoView().should('be.visible'));

            if (fieldType === 'date') {
              cy.get(dataQa).find('[data-qa="input-date"]').should('have.value', expectedValue);
            } else if (fieldType === 'nomenclature') {
              cy.get(`${dataQa} .ng-value-container .ng-value-label`).should(
                'have.text',
                expectedValue
              );
            }
          }
        });
      });
    });
  });
});
