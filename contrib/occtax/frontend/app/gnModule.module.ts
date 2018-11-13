import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
// Components
import { OcctaxMapFormComponent } from "./occtax-map-form/occtax-map-form.component";
import { ReleveComponent } from "./occtax-map-form/form/releve/releve.component";
import { CountingComponent } from "./occtax-map-form/form/counting/counting.component";
import { OccurrenceComponent } from "./occtax-map-form/form/occurrence/occurrence.component";
import { OcctaxFormComponent } from "./occtax-map-form/form/occtax-form.component";
import { TaxonsListComponent } from "./occtax-map-form/form/taxons-list/taxons-list.component";
import { OcctaxMapListComponent } from "./occtax-map-list/occtax-map-list.component";
import { OcctaxMapInfoComponent } from "./occtax-map-info/occtax-map-info.component";
// Service
import { OcctaxFormService } from "./occtax-map-form/form/occtax-form.service";
import { OcctaxDataService } from "./services/occtax-data.service";
import { OcctaxStoreService } from "./services/occtax-store.service";


const routes: Routes = [
  { path: "", component: OcctaxMapListComponent },
  { path: "form", component: OcctaxMapFormComponent },
  { path: "form/:id", component: OcctaxMapFormComponent, pathMatch: "full" },
  { path: "info/:id", component: OcctaxMapInfoComponent, pathMatch: "full" },
  {
    path: "info/id_counting/:id",
    component: OcctaxMapInfoComponent,
    pathMatch: "full"
  }
];

@NgModule({
  imports: [CommonModule, GN2CommonModule, RouterModule.forChild(routes)],
  declarations: [
    OcctaxMapFormComponent,
    OcctaxFormComponent,
    OcctaxMapInfoComponent,
    ReleveComponent,
    CountingComponent,
    OccurrenceComponent,
    TaxonsListComponent,
    OcctaxMapListComponent
  ],
  providers: [OcctaxFormService, OcctaxDataService, OcctaxStoreService],
  bootstrap: [OcctaxMapFormComponent]
})
export class GeonatureModule {}
