import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientModule, HttpClientXsrfModule, HTTP_INTERCEPTORS } from '@angular/common/http';

import { DatasetListComponent } from './datasets/dataset-list.component';
import { DatasetFormComponent } from './datasets/dataset-form.component';
import { AfListComponent } from './af/af-list.component';
import { AfFormComponent } from './af/af-form.component';
import { ActorComponent } from './actors/actors.component';
import { MetadataComponent } from './metadata.component';
import { AfCardComponent } from './af/af-card.component';
import { ChartsModule } from 'ng2-charts/ng2-charts';
import { ChartModule } from 'angular2-chartjs';
const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'datasets', component: DatasetListComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'afs', component: AfListComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'af-card/:id', component: AfCardComponent }
];

@NgModule({
  imports: [
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token'
    }),
    CommonModule,
    GN2CommonModule,
    ChartsModule,
    ChartModule,
    RouterModule.forChild(routes)
  ],
  exports: [],
  declarations: [
    MetadataComponent,
    DatasetListComponent,
    DatasetFormComponent,
    AfListComponent,
    AfFormComponent,
    ActorComponent,
    AfCardComponent
  ],
  providers: []
})
export class MetadataModule {}
