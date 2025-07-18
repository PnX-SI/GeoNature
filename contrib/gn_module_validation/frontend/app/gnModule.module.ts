import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { TreeModule } from '@circlon/angular-tree-component';
import { TranslateService, TranslateModule, TranslateLoader } from '@ngx-translate/core';

import { SharedSyntheseModule } from '@geonature/shared/syntheseSharedModule/synthese-shared.module';

//components
import { ValidationComponent } from './components/validation.component';
import { ValidationSyntheseListComponent } from './components/validation-synthese-list/validation-synthese-list.component';
import { ValidationDataService } from './services/data.service';
import { ValidationSyntheseCarteComponent } from './components/validation-synthese-carte/validation-synthese-carte.component';
import { ValidationPopupComponent } from './components/validation-popup/validation-popup.component';
import { ValidationDefinitionsComponent } from './components/validation-definitions/validation-definitions.component';
import { ValidationModalInfoObsComponent } from './components/validation-modal-info-obs/validation-modal-info-obs.component';
//services
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { ValidationService } from './services/validation.service';
import { ConfigService } from '@geonature/services/config.service';
import { CustomTranslateLoader } from '@geonature/shared/translate/custom-loader';
import { I18nService } from '@geonature/shared/translate/i18n-service';

export function createTranslateLoader(http: HttpClient, config: ConfigService) {
  return new CustomTranslateLoader(http, config, { moduleName: 'validation' });
}

// my module routing
const routes: Routes = [
  { path: '', component: ValidationComponent },
  { path: 'occurrence/:id_synthese', component: ValidationComponent },
  { path: 'occurrence/:id_synthese/:tab', component: ValidationComponent },
];

@NgModule({
  declarations: [
    ValidationComponent,
    ValidationSyntheseListComponent,
    ValidationSyntheseCarteComponent,
    ValidationPopupComponent,
    ValidationDefinitionsComponent,
    ValidationModalInfoObsComponent,
  ],
  imports: [
    GN2CommonModule,
    SharedSyntheseModule,
    RouterModule.forChild(routes),
    TranslateModule.forChild({
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient, ConfigService],
      },
      isolate: true,
    }),
    CommonModule,
    NgbModule,
    TreeModule,
  ],
  providers: [
    SyntheseDataService,
    ValidationDataService,
    SyntheseFormService,
    DynamicFormService,
    ValidationService,
    TaxonAdvancedStoreService,
  ],

  bootstrap: [],
})
export class GeonatureModule {
  constructor(
    private translateService: TranslateService,
    private i18nService: I18nService
  ) {
    // Workaround to force translation loaded for LazyModule.
    // See: https://github.com/ngx-translate/core/issues/1302
    this.i18nService.initializeModuleTranslateService(this.translateService);
  }
}
