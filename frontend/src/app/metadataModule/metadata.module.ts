import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientXsrfModule } from '@angular/common/http';
import { MatPaginatorIntl } from '@angular/material/paginator';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonToggleModule } from '@angular/material/button-toggle';

import { DatasetFormComponent } from './datasets/dataset-form.component';
import { DatasetCardComponent } from './datasets/dataset-card.component';
import { AfFormComponent } from './af/af-form.component';
import { ActorComponent } from './actors/actors.component';
import { MetadataComponent } from './metadata.component';
import { MetadataDatasetComponent } from './metadata-dataset.component';
import { AfCardComponent } from './af/af-card.component';
import { ChartsModule } from 'ng2-charts';
import { ChartModule } from 'angular2-chartjs';
import { MetadataService } from './services/metadata.service';
import { MetadataDataService } from './services/metadata-data.service';
import { ActorFormService } from './services/actor-form.service';

const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'dataset_detail/:id', component: DatasetCardComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'af_detail/:id', component: AfCardComponent },
];

export class MetadataPaginator extends MatPaginatorIntl {
  constructor() {
    super();
    this.nextPageLabel = 'Page suivante';
    this.previousPageLabel = 'Page précédente';
    this.itemsPerPageLabel = 'Éléments par page';
    this.getRangeLabel = (page: number, pageSize: number, length: number) => {
      if (length == 0 || pageSize == 0) {
        return `0 sur ${length}`;
      }
      length = Math.max(length, 0);
      const startIndex = page * pageSize;
      const endIndex =
        startIndex < length ? Math.min(startIndex + pageSize, length) : startIndex + pageSize;
      return `${startIndex + 1} - ${endIndex} sur ${length}`;
    };
  }
}

@NgModule({
  imports: [
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token',
    }),
    CommonModule,
    GN2CommonModule,
    ChartsModule,
    ChartModule,
    RouterModule.forChild(routes),
    MatCheckboxModule,
    MatButtonToggleModule,
  ],
  exports: [],
  declarations: [
    MetadataComponent,
    MetadataDatasetComponent,
    DatasetFormComponent,
    DatasetCardComponent,
    AfFormComponent,
    ActorComponent,
    AfCardComponent,
  ],
  providers: [
    MetadataService,
    MetadataDataService,
    ActorFormService,
    {
      provide: MatPaginatorIntl,
      useClass: MetadataPaginator,
    },
  ],
})
export class MetadataModule {}
