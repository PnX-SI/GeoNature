import { Injectable, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientXsrfModule } from '@angular/common/http';
import { MatPaginatorIntl } from '@angular/material/paginator';
import { TranslateService } from '@ngx-translate/core';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MAT_DATE_LOCALE, MatNativeDateModule } from '@angular/material/core';

import { DatasetFormComponent } from './datasets/dataset-form.component';
import { DatasetCardComponent } from './datasets/dataset-card.component';
import { AfFormComponent } from './af/af-form.component';
import { ActorComponent } from './actors/actors.component';
import { MetadataComponent } from './metadata.component';
import { MetadataFiltersComponent } from './filters/metadata-filters.component';
import { MetadataDatasetComponent } from './metadata-dataset.component';
import { AfCardComponent } from './af/af-card.component';
import { NgChartsModule } from 'ng2-charts';
import { MetadataService } from './services/metadata.service';
import { MetadataDataService } from './services/metadata-data.service';
import { ActorFormService } from './services/actor-form.service';
import { ButtonDeleteAfComponent } from './af/button-delete-af.component';
import { ButtonCloseAfComponent } from './af/button-close-af.component';
import { OrganismFormDialogComponent } from './organisms/organism-form-dialog.component';
import { DatasetActivationToggleComponent } from './datasets/dataset-activation-toggle.component';

const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'dataset_detail/:id', component: DatasetCardComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'af_detail/:id', component: AfCardComponent },
];

@Injectable()
export class MetadataPaginator extends MatPaginatorIntl {
  constructor(private translate: TranslateService) {
    super();
    this.translate
      .stream([
        'MetaData.UI.Paginator.Next',
        'MetaData.UI.Paginator.Previous',
        'MetaData.UI.Paginator.ItemsPerPage',
      ])
      .subscribe((labels) => {
        this.nextPageLabel = labels['MetaData.UI.Paginator.Next'];
        this.previousPageLabel = labels['MetaData.UI.Paginator.Previous'];
        this.itemsPerPageLabel = labels['MetaData.UI.Paginator.ItemsPerPage'];
        this.changes.next();
      });
    this.getRangeLabel = (page: number, pageSize: number, length: number) => {
      const of = this.translate.instant('MetaData.UI.Paginator.Of');
      if (length == 0 || pageSize == 0) {
        return `0 ${of} ${length}`;
      }
      length = Math.max(length, 0);
      const startIndex = page * pageSize;
      const endIndex =
        startIndex < length ? Math.min(startIndex + pageSize, length) : startIndex + pageSize;
      return `${startIndex + 1} - ${endIndex} ${of} ${length}`;
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
    NgChartsModule,
    RouterModule.forChild(routes),
    MatCheckboxModule,
    MatButtonToggleModule,
    MatDatepickerModule,
    MatNativeDateModule,
  ],
  exports: [],
  declarations: [
    MetadataComponent,
    MetadataFiltersComponent,
    MetadataDatasetComponent,
    DatasetFormComponent,
    DatasetCardComponent,
    AfFormComponent,
    ActorComponent,
    AfCardComponent,
    ButtonDeleteAfComponent,
    ButtonCloseAfComponent,
    DatasetActivationToggleComponent,
    OrganismFormDialogComponent,
  ],
  providers: [
    { provide: MAT_DATE_LOCALE, useValue: 'fr-FR' },
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
