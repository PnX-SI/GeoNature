
import { startImport, pickDestination, loadImportFile, configureImportFile, configureImportFieldMapping, configureImportContentMapping, verifyImport, executeImport } from "./new-import-utils";
describe('Import - create a new import', () => {
  beforeEach(() => {
    cy.geonatureInitImportList()
  });

  it('Should be able to import a valid-file in synthese', () => {
    startImport();
    pickDestination();
    loadImportFile();
    configureImportFile();
    configureImportFieldMapping();
    configureImportContentMapping();
    verifyImport();
    executeImport();
  })
})
