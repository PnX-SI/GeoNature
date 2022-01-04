import { NgModule } from "@angular/core";
import { NgbModule } from "@ng-bootstrap/ng-bootstrap";
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

import { CommonModule } from "@angular/common";
import { HttpClient } from '@angular/common/http';
import { AppConfig } from "@geonature_config/app.config";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { OccHabFormComponent } from "./components/occhab-map-form/occhab-form.component";
import { OccHabMapListComponent } from "./components/occhab-map-list/occhab-map-list.component";
import { OcchabMapListFilterComponent } from "./components/occhab-map-list/occhab-map-list-filter.component";
import { OccHabDataService } from "./services/data.service";
import { OcchabStoreService } from "./services/store.service";
import { OccHabMapListService } from "./services/occhab-map-list.service";
import { OccHabModalDownloadComponent } from "./components/occhab-map-list/modal-download.component";
import { OcchabInfoComponent } from "./components/occhab-info/occhab-info.component";
import { ModalDeleteStation } from "./components/delete-modal/delete-modal.component";
import { OccHabDatasetMapOverlayComponent } from "./components/occhab-map-form/dataset-map-overlay/dataset-map-overlay.component";

function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './external_assets/occhab/i18n/', '.json');
}

// my module routing
const routes: Routes = [
  { path: "form", component: OccHabFormComponent },
  { path: "form/:id_station", component: OccHabFormComponent },
  { path: "", component: OccHabMapListComponent },
  { path: "info/:id_station", component: OcchabInfoComponent }
];

@NgModule({
  declarations: [
    OccHabFormComponent,
    OccHabMapListComponent,
    OcchabMapListFilterComponent,
    OcchabInfoComponent,
    OccHabModalDownloadComponent,
    ModalDeleteStation,
    OccHabDatasetMapOverlayComponent
  ],
  imports: [
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
    TranslateModule.forChild({
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient]
      },
      isolate: true,
    }),
    NgbModule.forRoot()
  ],
  entryComponents: [OccHabModalDownloadComponent],

  providers: [OccHabDataService, OcchabStoreService, OccHabMapListService],
  bootstrap: []
})
export class GeonatureModule {
  constructor(
    private translate: TranslateService
  ) {
  translate.use(AppConfig.DEFAULT_LANGUAGE)
}
}
