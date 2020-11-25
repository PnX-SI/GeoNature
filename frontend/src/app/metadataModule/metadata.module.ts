import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientXsrfModule } from '@angular/common/http';

import { DatasetFormComponent } from './datasets/dataset-form.component';
import { DatasetCardComponent } from './datasets/dataset-card.component';
import { AfFormComponent } from './af/af-form.component';
import { ActorComponent } from './actors/actors.component';
import { MetadataComponent } from './metadata.component';
import { AfCardComponent } from './af/af-card.component';
import { ChartsModule } from 'ng2-charts/ng2-charts';
import { ChartModule } from 'angular2-chartjs';

const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'dataset_detail/:id', component: DatasetCardComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'af_detail/:id', component: AfCardComponent }
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
    DatasetFormComponent,
    DatasetCardComponent,
    AfFormComponent,
    ActorComponent,
    AfCardComponent
  ],
})
export class MetadataModule { }
