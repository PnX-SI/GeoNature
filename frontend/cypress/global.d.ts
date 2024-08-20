/// <reference types="cypress" />

declare namespace Cypress {
  interface Chainable {
    customCommand1(args: any): Chainable<Element>;

    customCommand2(args: any): Chainable<Element>;
  }
}
