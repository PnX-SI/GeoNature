import { Type } from '@angular/core'
import { NgSelectModule } from '@ng-select/ng-select';
import { mount, MountConfig } from 'cypress/angular'
declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof customMount
    }
  }
}


// Source : https://docs.cypress.io/guides/component-testing/angular/examples#Default-Declarations-Providers-or-Imports
const declarations = []
const imports = [NgSelectModule]
const providers = []

function customMount<T>(component: string | Type<T>, config?: MountConfig<T>) {
  if (!config) {
    config = { declarations, imports, providers }
  } else {
    config.declarations = [...(config?.declarations || []), ...declarations]
    config.imports = [...(config?.imports || []), ...imports]
    config.providers = [...(config?.providers || []), ...providers]
  }
  return mount<T>(component, config)
}

Cypress.Commands.add('mount', customMount)
