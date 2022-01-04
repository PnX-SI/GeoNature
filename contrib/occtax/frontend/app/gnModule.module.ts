import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { HttpClient } from '@angular/common/http';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { AppConfig } from "@geonature_config/app.config";
import { Routes, RouterModule } from "@angular/router";
import { NgbModule } from "@ng-bootstrap/ng-bootstrap";
import { GNPanelModule } from "@geonature/templates/gn-panel/gn-panel.module";

// Components
import { OcctaxMapListComponent } from "./occtax-map-list/occtax-map-list.component";
import { OcctaxMapListFilterComponent } from "./occtax-map-list/filter/occtax-map-list-filter.component";
import { OcctaxMapInfoComponent } from "./occtax-map-info/occtax-map-info.component";

import { OcctaxFormComponent } from "./occtax-form/occtax-form.component";
import { OcctaxFormMapComponent } from "./occtax-form/map/map.component";
import { OcctaxFormReleveComponent } from "./occtax-form/releve/releve.component";
import { OcctaxFormOccurrenceComponent } from "./occtax-form/occurrence/occurrence.component";
import { OcctaxFormTaxaListComponent } from "./occtax-form/taxa-list/taxa-list.component";
import { OcctaxFormCountingComponent } from "./occtax-form/counting/counting.component";
import { OcctaxFormParamDialog } from "./occtax-form/form-param/form-param.dialog";

// Service
import { OcctaxDataService } from "./services/occtax-data.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";

import { OcctaxFormMapService } from "./occtax-form/map/map.service";
import { OcctaxFormParamService } from "./occtax-form/form-param/form-param.service";

import { MatSlideToggleModule, MatTabsModule } from "@angular/material";

function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './external_assets/occtax/i18n/', '.json');
}

const routes: Routes = [
  { path: "", component: OcctaxMapListComponent },
  { 
    path: "form", 
    component: OcctaxFormComponent,
    children : [
      {
        path: "releve",
        component: OcctaxFormReleveComponent
      },
      {
        path: "releve/:id",
        component: OcctaxFormReleveComponent
      },
      {
        path: ":id/taxons",
        component: OcctaxFormOccurrenceComponent
      }
    ] 
  },
  { path: "info/:id", component: OcctaxMapInfoComponent, pathMatch: "full" },
  {
    path: "info/id_counting/:id_counting",
    component: OcctaxMapInfoComponent,
    pathMatch: "full",
  },
];

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    TranslateModule.forChild({
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient]
      },
      isolate: true,
    }),
    CommonModule,
    MatSlideToggleModule,
    MatTabsModule,
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
    OcctaxFormParamDialog,
  ],
  providers: [
    OcctaxDataService,
    MapListService,
    OcctaxFormMapService,
    OcctaxFormParamService,
  ],
})
export class GeonatureModule {
  constructor(
    private translate: TranslateService
  ) {
    translate.use(AppConfig.DEFAULT_LANGUAGE)
  }
}
