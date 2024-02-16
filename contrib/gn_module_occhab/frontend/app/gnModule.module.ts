import { NgModule } from "@angular/core";
import { NgbModule } from "@ng-bootstrap/ng-bootstrap";

import { CommonModule } from "@angular/common";
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
import { StationResolver } from "./resolvers/station.resolver";
import { DataService } from "../../../../frontend/src/app/modules/imports/services/data.service";

// my module routing
const routes: Routes = [
  { path: "", component: OccHabMapListComponent },
  { path: "add", component: OccHabFormComponent },
  {
    path: "edit/:id_station",
    component: OccHabFormComponent,
    resolve: { station: StationResolver },
  },
  {
    path: "info/:id_station",
    component: OcchabInfoComponent,
    resolve: { station: StationResolver },
  },
];

@NgModule({
  declarations: [
    OccHabFormComponent,
    OccHabMapListComponent,
    OcchabMapListFilterComponent,
    OcchabInfoComponent,
    OccHabModalDownloadComponent,
    ModalDeleteStation,
    OccHabDatasetMapOverlayComponent,
  ],
  imports: [
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
    NgbModule,
  ],
  entryComponents: [OccHabModalDownloadComponent],

  providers: [
    OccHabDataService,
    OcchabStoreService,
    OccHabMapListService,
    StationResolver,
    DataService,
  ],
  bootstrap: [],
})
export class GeonatureModule {}
