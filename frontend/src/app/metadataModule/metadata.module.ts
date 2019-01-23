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

const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'datasets', component: DatasetListComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'afs', component: AfListComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent }
];

@NgModule({
  imports: [
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token'
    }),
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes)
  ],
  exports: [],
  declarations: [
    MetadataComponent,
    DatasetListComponent,
    DatasetFormComponent,
    AfListComponent,
    AfFormComponent,
    ActorComponent
  ],
  providers: []
})
export class MetadataModule {}
