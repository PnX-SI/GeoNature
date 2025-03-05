export const FILTERS_TABLE = [
  {
    columnName: 'Fichier',
    searchTerm: ['valid_file_test_import', 'invalid_file.csv'],
    expectedRowsCount: [2, 0],
  },
  {
    columnName: 'Auteur',
    searchTerm: ['Administrateur-test-import', 'Agent-test-import'],
    expectedRowsCount: [5, 1],
  },
];
