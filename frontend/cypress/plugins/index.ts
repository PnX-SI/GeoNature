// Plugins enable you to tap into, modify, or extend the internal behavior of Cypress
// For more info, visit https://on.cypress.io/plugins-api
import * as registerCodeCoverageTasks from '@cypress/code-coverage/task';

export default (on, config) => {
  return registerCodeCoverageTasks(on, config);
};
