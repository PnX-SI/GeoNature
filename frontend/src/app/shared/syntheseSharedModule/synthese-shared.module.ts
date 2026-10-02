import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgChartsModule } from 'ng2-charts';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { RouterModule } from '@angular/router';
import { ClipboardModule } from '@angular/cdk/clipboard';
import { MatCheckboxModule } from '@angular/material/checkbox';

import { SyntheseInfoObsComponent } from './synthese-info-obs/synthese-info-obs.component';
import { DiscussionCardComponent } from '../discussionCardModule/discussion-card.component';
import { AlertInfoComponent } from '../alertInfoModule/alert-Info.component';
import { TaxonomyComponent } from './synthese-info-obs/taxonomy/taxonomy.component';
import { SyntheseCriteriaService } from '@geonature/syntheseModule/services/criteria.service';
import { SendMailFormComponent } from '@geonature/components/send-mail/send-mail-form-component';

@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule,
    NgChartsModule,
    RouterModule,
    ClipboardModule,
    MatCheckboxModule,
  ],
  exports: [
    SyntheseInfoObsComponent,
    DiscussionCardComponent,
    AlertInfoComponent,
    TaxonomyComponent,
    SendMailFormComponent,
  ],
  declarations: [
    SyntheseInfoObsComponent,
    DiscussionCardComponent,
    AlertInfoComponent,
    TaxonomyComponent,
    SendMailFormComponent,
  ],
  providers: [SyntheseCriteriaService],
})
export class SharedSyntheseModule {}
