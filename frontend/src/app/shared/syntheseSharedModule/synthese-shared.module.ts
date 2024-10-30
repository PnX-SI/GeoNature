import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgChartsModule } from 'ng2-charts';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { RouterModule } from '@angular/router';
import { ClipboardModule } from '@angular/cdk/clipboard';

import { SyntheseInfoObsComponent } from './synthese-info-obs/synthese-info-obs.component';
import { DiscussionCardComponent } from '../discussionCardModule/discussion-card.component';
import { AlertInfoComponent } from '../alertInfoModule/alert-Info.component';
import { TaxonomyComponent } from './synthese-info-obs/taxonomy/taxonomy.component';

@NgModule({
  imports: [CommonModule, GN2CommonModule, NgChartsModule, RouterModule, ClipboardModule],
  exports: [
    SyntheseInfoObsComponent,
    DiscussionCardComponent,
    AlertInfoComponent,
    TaxonomyComponent,
  ],
  declarations: [
    SyntheseInfoObsComponent,
    DiscussionCardComponent,
    AlertInfoComponent,
    TaxonomyComponent,
  ],
  providers: [],
})
export class SharedSyntheseModule {}
