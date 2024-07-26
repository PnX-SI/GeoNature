Cypress.Commands.add('deleteFile', (fileName, downloadFolder) => {
  const filePath = `${downloadFolder}/${fileName}`;
  cy.task('deleteFile', filePath);
});
