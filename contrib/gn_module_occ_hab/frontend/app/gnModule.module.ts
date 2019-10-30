import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import {
  MatAutocompleteModule,
  MatFormFieldModule,
  MatInputModule
} from "@angular/material";

import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { OccHabFormComponent } from "./components/occhab-form.component";
import { OccHabMapListComponent } from "./components/occhab-map-list.component";
import { OcchabFormService } from "./services/form-service";
import { OccHabDataService } from "./services/data.service";
import { OcchabStoreService } from "./services/store.service";

// my module routing
const routes: Routes = [
  { path: "form", component: OccHabFormComponent },
  { path: "form/:id_station", component: OccHabFormComponent },
  { path: "", component: OccHabMapListComponent }
];

@NgModule({
  declarations: [OccHabFormComponent, OccHabMapListComponent],
  imports: [
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
    MatAutocompleteModule,
    MatFormFieldModule,
    MatInputModule
  ],
  providers: [OccHabDataService, OcchabStoreService],
  bootstrap: []
})
export class GeonatureModule {}
