import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
// Components
import { OcctaxMapFormComponent } from "./occtax-map-form/occtax-map-form.component";
import { OcctaxMapFormComponent as NOcctaxMapFormComponent } from "./n-occtax-map-form/occtax-map-form.component";
import { ReleveComponent } from "./occtax-map-form/form/releve/releve.component";
import { CountingComponent } from "./occtax-map-form/form/counting/counting.component";
import { OccurrenceComponent } from "./occtax-map-form/form/occurrence/occurrence.component";
import { OcctaxFormComponent } from "./occtax-map-form/form/occtax-form.component";
import { TaxonsListComponent } from "./occtax-map-form/form/taxons-list/taxons-list.component";
import { OcctaxMapListComponent } from "./occtax-map-list/occtax-map-list.component";
import { OcctaxMapListFilterComponent } from "./occtax-map-list/filter/occtax-map-list-filter.component";
import { OcctaxMapInfoComponent } from "./occtax-map-info/occtax-map-info.component";

import { OcctaxFormMapComponent } from "./n-occtax-map-form/form/map/map.component";
// Service
import { OcctaxDataService } from "./services/occtax-data.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";

import { OcctaxFormService } from "./n-occtax-map-form/services/form.service";

import {
  MatSlideToggleModule
} from '@angular/material';

const routes: Routes = [
  { path: "", component: OcctaxMapListComponent },
  { path: "form", component: NOcctaxMapFormComponent },
  { path: "form/:id", component: NOcctaxMapFormComponent, pathMatch: "full" },
  { path: "info/:id", component: OcctaxMapInfoComponent, pathMatch: "full" },
  {
    path: "info/id_counting/:id",
    component: OcctaxMapInfoComponent,
    pathMatch: "full"
  }
];

@NgModule({
  imports: [
    RouterModule.forChild(routes), 
    GN2CommonModule, 
    CommonModule, 
    MatSlideToggleModule, 
    NgbModule
  ],
  declarations: [
    OcctaxMapFormComponent,
    NOcctaxMapFormComponent,
    OcctaxFormComponent,
    OcctaxMapInfoComponent,
    ReleveComponent,
    CountingComponent,
    OccurrenceComponent,
    TaxonsListComponent,
    OcctaxMapListComponent,
    OcctaxMapListFilterComponent,
    OcctaxFormMapComponent
  ],
  providers: [OcctaxDataService, MapListService, OcctaxFormService],
  bootstrap: [OcctaxMapFormComponent]
})
export class GeonatureModule { }
