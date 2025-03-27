import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_ALTITUDE_MAX,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATE_MIN,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOMENCLATURE_DETERMINATION_TYPE,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOMENCLATURE_GEO_OBJECT_NATURE,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOM_CITE,
  SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_STATION_NAME,
} from './constants/selectors';

const USER = USERS[0];
const VIEWPORT = VIEWPORTS[0];

function handleFieldValidation(dataQa, expectedValue, isNgSelect) {
  if (isNgSelect) {
    cy.get(dataQa)
      .should('exist')
      .within(() => {
        cy.get('.ng-value-label').should('have.text', expectedValue);
      });
  } else {
    cy.get(dataQa).should('have.value', expectedValue);
  }
}

const paramsByDestination = [
  {
    destination: 'synthese',
    queryParams: [
      {
        paramsName: 'nom_cite',
        paramsValue: 'test_nomcite',
        isNgSelect: false,
        expectedValue: 'test_nomcite',
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOM_CITE,
      },
      {
        paramsName: 'altitude_max',
        paramsValue: 10,
        isNgSelect: false,
        expectedValue: 10,
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_ALTITUDE_MAX,
      },
      {
        paramsName: 'date_min',
        paramsValue: '2024-12-12',
        isNgSelect: false,
        expectedValue: '2024-12-12',
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_DATE_MIN,
      },
      {
        paramsName: 'id_nomenclature_geo_object_nature',
        paramsValue: 'Inventoriel',
        isNgSelect: true,
        expectedValue: 'Inventoriel',
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOMENCLATURE_GEO_OBJECT_NATURE,
      },
    ],
  },
  {
    destination: 'occhab',
    queryParams: [
      {
        paramsName: 'id_nomenclature_determination_type',
        paramsValue: 'Inconnu',
        isNgSelect: true,
        entityLabel: 'Habitat',
        expectedValue: 'Inconnu',
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_NOMENCLATURE_DETERMINATION_TYPE,
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
        isNgSelect: false,
        entityLabel: 'Station',
        expectedValue: 'test_station_name',
        constantDataQA: SELECTOR_IMPORT_FIELDMAPPING_CONSTANT_STATION_NAME,
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
          cy.loadImportFile(FILES[destination].valid.fixture);
          cy.configureImportFile();
        });

        it(`Validates fields for destination: ${destination}`, () => {
          queryParams.forEach(
            ({ expectedValue, isNgSelect, entityLabel, constantDataQA: constantDataQA }) => {
              if (entityLabel) {
                const dataQaEntity = `[data-qa="import-entity-tab-${entityLabel}"]`;
                cy.get(dataQaEntity, { timeout: 30000 }).should('be.visible').click();
              }

              handleFieldValidation(constantDataQA, expectedValue, isNgSelect);
            }
          );
          cy.visitImport();
          cy.removeFirstImportInList();
        });
      });
    });
  });
});
