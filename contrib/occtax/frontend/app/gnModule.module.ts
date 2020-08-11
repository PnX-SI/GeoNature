import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
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

import { OcctaxFormService } from "./occtax-form/occtax-form.service";
import { OcctaxFormMapService } from "./occtax-form/map/map.service";
import { OcctaxFormReleveService } from "./occtax-form/releve/releve.service";
import { OcctaxFormOccurrenceService } from "./occtax-form/occurrence/occurrence.service";
import { OcctaxFormCountingService } from "./occtax-form/counting/counting.service";
import { OcctaxTaxaListService } from "./occtax-form/taxa-list/taxa-list.service";
import { OcctaxFormParamService } from "./occtax-form/form-param/form-param.service";

import { MatSlideToggleModule, MatTabsModule } from "@angular/material";

const routes: Routes = [
  { path: "", component: OcctaxMapListComponent },
  { path: "form", component: OcctaxFormComponent },
  { path: "form/:id", component: OcctaxFormComponent, pathMatch: "full" },
  {
    path: "form/:id/taxons",
    component: OcctaxFormComponent,
    pathMatch: "full",
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
  entryComponents: [OcctaxFormParamDialog],
  providers: [
    OcctaxDataService,
    MapListService,
    OcctaxFormService,
    OcctaxFormMapService,
    OcctaxFormReleveService,
    OcctaxFormOccurrenceService,
    OcctaxFormCountingService,
    OcctaxTaxaListService,
    OcctaxFormParamService,
  ],
})
export class GeonatureModule {}
