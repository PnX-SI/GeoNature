import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseComponent } from './synthese.component';
import { TreeModule } from '@circlon/angular-tree-component';
import { SharedSyntheseModule } from '@geonature/shared/syntheseSharedModule/synthese-shared.module';
import { TaxonSheetComponent } from './taxon-sheet/taxon-sheet.component';
import {
  RouteService,
  ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES,
} from './taxon-sheet/taxon-sheet.route.service';
import { NgbActiveModal, NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseObsModalWrapperComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs-container.component';
import { SyntheseFormService } from './services/form.service';
import { SyntheseInfoObsComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
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
    SyntheseComponent,
  ],
  entryComponents: [
    SyntheseComponent,
    SyntheseInfoObsComponent,
    SyntheseObsModalWrapperComponent
  ],
  providers: [NgbActiveModal, RouteService, SyntheseFormService, TaxonAdvancedStoreService],
})
export class SyntheseModule {}
