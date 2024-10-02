export const USERS = [
  {
    id: 0,
    login: {
      username: 'admin-test-import',
      password: 'admin',
    },
    destinations: {
      Synthèse: {
        count: 3,
        code: 'synthese',
      },
      Occhab: {
        count: 1,
        code: 'occhab',
      },
    },
    availableDestinations: ['synthese', 'occhab'],
    dataset: 'JDD-TEST-IMPORT-ADMIN',
    datasetId: 9999,
  },
  {
    id: 1,
    login: {
      username: 'agent-test-import',
      password: 'agent',
    },
    destinations: {
      Synthèse: {
        count: 1,
        code: 'synthese',
      },
      Occhab: {
        count: 0,
        code: 'occhab',
      },
      availableDestinations: ['synthese'],
    },
    dataset: 'JDD-TEST-IMPORT-2',
    datasetId: 9998,
  },
];

export function availableDestinations(destinations) {
  return Object.keys(destinations);
}
export function availableImportsCount(destinations) {
  return Object.values(destinations).reduce((partialSum, item) => partialSum + item.count, 0);
}
