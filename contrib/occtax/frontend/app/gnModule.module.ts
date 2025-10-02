import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { GNPanelModule } from '@geonature/templates/gn-panel/gn-panel.module';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';

// Components
import { OcctaxMapListComponent } from './occtax-map-list/occtax-map-list.component';
import { OcctaxMapListFilterComponent } from './occtax-map-list/filter/occtax-map-list-filter.component';
import { OcctaxMapInfoComponent } from './occtax-map-info/occtax-map-info.component';

import { OcctaxFormComponent } from './occtax-form/occtax-form.component';
import { OcctaxFormMapComponent } from './occtax-form/map/occtax-map.component';
import { OcctaxFormReleveComponent } from './occtax-form/releve/releve.component';
import { OcctaxFormOccurrenceComponent } from './occtax-form/occurrence/occurrence.component';
import { OcctaxFormTaxaListComponent } from './occtax-form/taxa-list/taxa-list.component';
import { OcctaxFormCountingComponent } from './occtax-form/counting/counting.component';
import { OcctaxProfilesComponent } from './occtax-form/occurrence/profiles.component';
import { OcctaxFormParamDialog } from './occtax-form/form-param/form-param.dialog';
import { PhytoStratumComponent } from './occtax-form/releve/phyto/strate.component';

// Service
import { OcctaxDataService } from './services/occtax-data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

import { OcctaxFormMapService } from './occtax-form/map/occtax-map.service';
import { OcctaxFormParamService } from './occtax-form/form-param/form-param.service';

import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTabsModule } from '@angular/material/tabs';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { ConfigService } from '@geonature/services/config.service';
import { CustomTranslateLoader } from '@geonature/shared/translate/custom-loader';
import { I18nService } from '@geonature/shared/translate/i18n-service';

const routes: Routes = [
  { path: '', component: OcctaxMapListComponent },
  {
    path: 'form',
    component: OcctaxFormComponent,
    children: [
      {
        path: 'releve',
        component: OcctaxFormReleveComponent,
      },
      {
        path: 'releve/:id',
        component: OcctaxFormReleveComponent,
      },
      {
        path: ':id/taxons',
        component: OcctaxFormOccurrenceComponent,
      },
    ],
  },
  { path: 'info/:id', component: OcctaxMapInfoComponent, pathMatch: 'full' },
  {
    path: 'info/id_counting/:id_counting',
    component: OcctaxMapInfoComponent,
    pathMatch: 'full',
  },
];

export function createTranslateLoader(http: HttpClient, config: ConfigService) {
  return new CustomTranslateLoader(http, config, { moduleName: 'occtax' });
}

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    TranslateModule.forChild({
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient, ConfigService],
      },
      isolate: true,
    }),
    CommonModule,
    MatSlideToggleModule,
    MatTabsModule,
    FormsModule,
    ReactiveFormsModule,
    MatTableModule,
    MatFormFieldModule,
    MatInputModule,
    NgbModule,
    GNPanelModule,
  ],
  declarations: [
    OcctaxFormComponent,
    OcctaxMapInfoComponent,
    OcctaxMapListComponent,
    OcctaxMapListFilterComponent,
    OcctaxFormMapComponent,
    OcctaxFormReleveComponent,
    OcctaxFormOccurrenceComponent,
    OcctaxFormTaxaListComponent,
    OcctaxFormCountingComponent,
    OcctaxProfilesComponent,
    OcctaxFormParamDialog,
    PhytoStratumComponent
  ],
  providers: [OcctaxDataService, MapListService, OcctaxFormMapService, OcctaxFormParamService],
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
