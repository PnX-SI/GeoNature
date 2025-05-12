import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseComponent } from './synthese.component';
import { SyntheseListComponent } from './synthese-results/synthese-list/synthese-list.component';
import { SyntheseCarteComponent } from './synthese-results/synthese-carte/synthese-carte.component';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { MapService } from '@geonature_common/map/map.service';
import { TreeModule } from '@circlon/angular-tree-component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { SharedSyntheseModule } from '@geonature/shared/syntheseSharedModule/synthese-shared.module';
import { SyntheseInfoObsComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { DiscussionCardComponent } from '@geonature/shared/discussionCardModule/discussion-card.component';
import { AlertInfoComponent } from '../shared/alertInfoModule/alert-Info.component';
import { TaxonSheetComponent } from './taxon-sheet/taxon-sheet.component';
import {
  RouteService,
  ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES,
} from './taxon-sheet/taxon-sheet.route.service';
import { NgbActiveModal, NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseObsModalWrapperComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs-container.component';
const routes: Routes = [
  {
    path: '',
    component: SyntheseComponent,
    children: [
      {
        path: 'occurrence/:id_synthese',
        redirectTo: 'occurrence/:id_synthese/details',
        pathMatch: 'full',
      },
      {
        path: 'occurrence/:id_synthese/:tab',
        component: SyntheseObsModalWrapperComponent,
      },
    ],
  },
  {
    path: 'taxon/:cd_ref',
    component: TaxonSheetComponent,
    canActivate: [RouteService],
    canActivateChild: [RouteService],
    children: [
      // The tabs are all optional. therefore, we can't apply redireciotn here.
      // A redirection from parent to child is apply in canActivate
      ...ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES.map((tab) => {
        return {
          path: tab.path,
          component: tab.component,
        };
      }),
    ],
  },
];

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    SharedSyntheseModule,
    CommonModule,
    TreeModule,
    NgbModule,
    TaxonSheetComponent,
  ],
  declarations: [
    SyntheseComponent,
    SyntheseListComponent,
    SyntheseCarteComponent,
    SyntheseModalDownloadComponent,
  ],
  entryComponents: [
    SyntheseComponent,
    SyntheseInfoObsComponent,
    SyntheseModalDownloadComponent,
    DiscussionCardComponent,
    AlertInfoComponent,
    SyntheseObsModalWrapperComponent,
  ],
  providers: [
    MapService,
    DynamicFormService,
    TaxonAdvancedStoreService,
    SyntheseFormService,
    NgbActiveModal,
    RouteService,
  ],
})
export class SyntheseModule {}
