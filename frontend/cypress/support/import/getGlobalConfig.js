Cypress.Commands.add('getGlobalConfig', () => {
  return cy
    .request('GET', Cypress.env('apiEndpoint') + 'gn_commons/config')
    .its('body.IMPORT.LIST_COLUMNS_FRONTEND')
    .then((columnsImport) => {
      const columnNames = [
        'Id Import',
        'Fichier',
        'Auteur',
        'Debut import',
        'Destination',
        'Fin import',
      ];
      const columns = columnsImport
        .filter((column) => columnNames.includes(column.name))
        .map((column) => ({
          name: column.name,
          sortable: column.filter,
        }));
      return columns;
    })
    .as('globalColumnsConfig');
});
