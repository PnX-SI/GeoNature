import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";

import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { OccHabFormComponent } from "./components/occhab-form.component";
import { OcchabFormService } from "./services/form-service";

// my module routing
const routes: Routes = [{ path: "", component: OccHabFormComponent }];

@NgModule({
  declarations: [OccHabFormComponent],
  imports: [CommonModule, GN2CommonModule, RouterModule.forChild(routes)],
  providers: [OcchabFormService],
  bootstrap: []
})
export class GeonatureModule {}
