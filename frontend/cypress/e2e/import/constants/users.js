export const USERS = [
  {
    "id": 0,
    "login" : {
      "username": "admin-test-import",
      "password": "admin"
    },
    "destinations": {
      "Synthèse": {
        "count": 2,
        "code": "synthese"
      },
      "Occhab": {
        "count": 1,
        "code": "occhab"
      }
    },
    "dataset": "JDD-TEST-IMPORT-ADMIN"
  },
  {
    "id": 1,
    "login": {
      "username": "agent-test-import",
      "password": "agent"
    },
    "destinations": {
      "Synthèse": {
        "count": 1,
        "code": "synthese"
      },
      "Occhab": {
        "count": 0,
        "code": "occhab"
      }
    }
  }
]

export function availableDestinations(destinations) {
  return Object.keys(destinations);
}
export function availableImportsCount(destinations) {
  return Object.values(destinations).reduce((partialSum, item) => partialSum + item.count, 0);
}
