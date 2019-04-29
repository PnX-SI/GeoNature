import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { CommonModule } from '@angular/common';
// Components
import { DashboardComponent } from "./dashboard/dashboard.component";
// Services
import { DataService } from "./dashboard/services/data.services"

// my module routing
const routes: Routes = [
  { path: "", component: DashboardComponent }
];

@NgModule({
  declarations: [DashboardComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes), CommonModule],
  providers: [DataService],
  bootstrap: []
})
export class GeonatureModule {}
