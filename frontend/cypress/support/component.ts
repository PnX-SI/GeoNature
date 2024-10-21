import { Type } from '@angular/core';
import { MatIconRegistry } from '@angular/material/icon';
import { mount, MountConfig } from 'cypress/angular';

import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { FormService } from '@geonature_common/form/form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { CommonService } from '@geonature_common/service/common.service';
import { MediaService } from '@geonature_common/service/media.service';
import { TranslateService } from '@ngx-translate/core';
import { AppModule } from '@geonature/app.module';
declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof customMount
    }
  }
}


// Source : https://docs.cypress.io/guides/component-testing/angular/examples#Default-Declarations-Providers-or-Imports

const declarations = [
]
const imports = [AppModule]

const providers = [
  MapService,
  MapListService,
  CommonService,
  DataFormService,
  DynamicFormService,
  ConfigService,
  FormService,
  MatIconRegistry,
  MediaService,
  NgbDatePeriodParserFormatter,
  SyntheseDataService,
  TranslateService
]

/**
 * Mounts a component with the given configuration including default declarations, imports and providers
 *
 * @param {string | Type<T>} component - The component to mount
 * @param {MountConfig<T>} config - The configuration for mounting the component
 * @return {T} The mounted component
 */
function customMount<T>(component: string | Type<T>, config?: MountConfig<T>) {
  console.log(providers)
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
