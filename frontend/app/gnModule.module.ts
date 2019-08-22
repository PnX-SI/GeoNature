import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { CommonModule } from '@angular/common';
import { FormsModule } from "@angular/forms";
import { ReactiveFormsModule } from "@angular/forms";
import { MatTabsModule } from '@angular/material/tabs';
import { ChartsModule } from "ng2-charts";
import { NouisliderModule } from 'ng2-nouislider';
import "chartjs-plugin-labels";
// import "chartjs-plugin-piechart-outlabels";
// Components
import { DashboardComponent } from "./dashboard/dashboard.component";
import { DashboardMapsComponent } from "./dashboard/dashboard-maps/dashboard-maps.component";
import { DashboardHistogramComponent } from "./dashboard/dashboard-histogram/dashboard-histogram.component";
import { DashboardTaxonomyComponent } from "./dashboard/dashboard-taxonomy/dashboard-taxonomy.component";
import { DashboardFrameworksComponent } from "./dashboard/dashboard-frameworks/dashboard-frameworks.component";
import { DashboardRecontactComponent } from "./dashboard/dashboard-recontact/dashboard-recontact.component";
// Services
import { DataService } from "./dashboard/services/data.services"

// my module routing
const routes: Routes = [
  { path: "", component: DashboardComponent },
  { path: "maps", component: DashboardMapsComponent },
  { path: "histogram", component: DashboardHistogramComponent },
  { path: "piechart", component: DashboardTaxonomyComponent },
  { path: "linechart", component: DashboardFrameworksComponent }
];

@NgModule({
  declarations: [DashboardComponent, DashboardMapsComponent, DashboardHistogramComponent, DashboardTaxonomyComponent, DashboardFrameworksComponent, DashboardRecontactComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes), CommonModule, FormsModule, ReactiveFormsModule, MatTabsModule, ChartsModule, NouisliderModule],
  providers: [DataService],
  bootstrap: [DashboardComponent]
})
export class GeonatureModule { }
