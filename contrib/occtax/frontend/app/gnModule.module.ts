import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { GNPanelModule } from '@geonature/templates/gn-panel/gn-panel.module';

// Components
import { OcctaxMapListComponent } from './occtax-map-list/occtax-map-list.component';
import { OcctaxMapListFilterComponent } from './occtax-map-list/filter/occtax-map-list-filter.component';
import { OcctaxMapInfoComponent } from './occtax-map-info/occtax-map-info.component';

import { OcctaxFormComponent } from './occtax-form/occtax-form.component';
import { OcctaxFormMapComponent } from './occtax-form/map/occtax-map.component';
import { OcctaxFormReleveComponent } from './occtax-form/releve/releve.component';
import { OcctaxFormOccurrenceComponent } from './occtax-form/occurrence/occurrence.component';
import { OcctaxFormTaxaListComponent } from './occtax-form/taxa-list/taxa-list.component';
import { OcctaxFormCountingComponent } from './occtax-form/counting/counting.component';
import { OcctaxProfilesComponent } from './occtax-form/occurrence/profiles.component';
import { OcctaxFormParamDialog } from './occtax-form/form-param/form-param.dialog';

// Service
import { OcctaxDataService } from './services/occtax-data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

import { OcctaxFormMapService } from './occtax-form/map/occtax-map.service';
import { OcctaxFormParamService } from './occtax-form/form-param/form-param.service';

import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTabsModule } from '@angular/material/tabs';
const routes: Routes = [
  { path: '', component: OcctaxMapListComponent },
  {
    path: 'form',
    component: OcctaxFormComponent,
    children: [
      {
        path: 'releve',
        component: OcctaxFormReleveComponent,
      },
      {
        path: 'releve/:id',
        component: OcctaxFormReleveComponent,
      },
      {
        path: ':id/taxons',
        component: OcctaxFormOccurrenceComponent,
      },
    ],
  },
  { path: 'info/:id', component: OcctaxMapInfoComponent, pathMatch: 'full' },
  {
    path: 'info/id_counting/:id_counting',
    component: OcctaxMapInfoComponent,
    pathMatch: 'full',
  },
];

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    CommonModule,
    MatSlideToggleModule,
    MatTabsModule,
    NgbModule,
    GNPanelModule,
  ],
  declarations: [
    OcctaxFormComponent,
    OcctaxMapInfoComponent,
    OcctaxMapListComponent,
    OcctaxMapListFilterComponent,
    OcctaxFormMapComponent,
    OcctaxFormReleveComponent,
    OcctaxFormOccurrenceComponent,
    OcctaxFormTaxaListComponent,
    OcctaxFormCountingComponent,
    OcctaxProfilesComponent,
    OcctaxFormParamDialog,
  ],
  providers: [OcctaxDataService, MapListService, OcctaxFormMapService, OcctaxFormParamService],
})
export class GeonatureModule {}
