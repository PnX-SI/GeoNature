import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { CommonModule } from '@angular/common';
import { FormsModule } from "@angular/forms";
import { ReactiveFormsModule } from "@angular/forms";
import { ChartsModule } from "ng2-charts";
import { NouisliderModule } from 'ng2-nouislider';
// Components
import { DashboardComponent } from "./dashboard/dashboard.component";
import { DashboardMapsComponent } from "./dashboard/dashboard-maps/dashboard-maps.component";
import { DashboardHistogramComponent } from "./dashboard/dashboard-histogram/dashboard-histogram.component";
import { DashboardPieChartComponent } from "./dashboard/dashboard-pie-chart/dashboard-pie-chart.component";
// Services
import { DataService } from "./dashboard/services/data.services"

// my module routing
const routes: Routes = [
  { path: "", component: DashboardComponent },
  { path: "maps", component: DashboardMapsComponent },
  { path: "histogram", component: DashboardHistogramComponent },
  { path: "piechart", component: DashboardPieChartComponent }
];

@NgModule({
  declarations: [DashboardComponent, DashboardMapsComponent, DashboardHistogramComponent, DashboardPieChartComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes), CommonModule, FormsModule, ReactiveFormsModule, ChartsModule, NouisliderModule],
  providers: [DataService],
  bootstrap: [DashboardComponent]
})
export class GeonatureModule {}
