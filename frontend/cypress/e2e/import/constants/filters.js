export const FILTERS_TABLE = [
  {
    columnName: 'Voir la fiche du JDD',
    searchTerm: ['JDD-TEST', 'JDD-TEST-IMPORT-ADMIN', 'JDD-INVALID'],
    expectedRowsCount: [4, 1, 0],
  },
  {
    columnName: 'Fichier',
    searchTerm: ['valid_file_test_import', 'invalid_file.csv'],
    expectedRowsCount: [2, 0],
  },
  {
    columnName: 'Auteur',
    searchTerm: ['Administrateur-test-import', 'Agent-test-import'],
    expectedRowsCount: [4, 1],
  },
];
