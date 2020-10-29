import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ChartModule } from 'angular2-chartjs';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { SyntheseInfoObsComponent } from './synthese-info-obs/synthese-info-obs.component';

@NgModule({
  imports: [CommonModule, GN2CommonModule, ChartModule],
  exports: [SyntheseInfoObsComponent],
  declarations: [SyntheseInfoObsComponent],
  providers: []
})
export class SharedSyntheseModule {}
