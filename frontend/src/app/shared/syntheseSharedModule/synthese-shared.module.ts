import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ChartsModule } from 'ng2-charts';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { RouterModule } from '@angular/router';
import { ClipboardModule } from '@angular/cdk/clipboard';

import { SyntheseInfoObsComponent } from './synthese-info-obs/synthese-info-obs.component';

@NgModule({
  imports: [CommonModule, GN2CommonModule, ChartsModule, RouterModule, ClipboardModule],
  exports: [SyntheseInfoObsComponent],
  declarations: [SyntheseInfoObsComponent],
  providers: [],
})
export class SharedSyntheseModule {}
