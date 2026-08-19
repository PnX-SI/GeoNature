import { Injectable, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientXsrfModule } from '@angular/common/http';
import { MatPaginatorIntl } from '@angular/material/paginator';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonToggleModule } from '@angular/material/button-toggle';

import { DatasetFormComponent } from './datasets/dataset-form/dataset-form.component';
import { DatasetCardComponent } from './datasets/dataset-card/dataset-card.component';
import { AfFormComponent } from './af/af-form/af-form.component';
import { ActorComponent } from './actors/actors.component';
import { MetadataComponent } from './metadata.component';
import { MetadataDatasetComponent } from './metadata-dataset.component';
import { AfCardComponent } from './af/af-card/af-card.component';
import { NgChartsModule } from 'ng2-charts';
import { MetadataService } from './services/metadata.service';
import { MetadataDataService } from './services/metadata-data.service';
import { ActorFormService } from './services/actor-form.service';
import { ButtonDeleteAfComponent } from './af/button-delete-af/button-delete-af.component';
import { ButtonCloseAfComponent } from './af/button-close-af/button-close-af.component';
import { OrganismFormDialogComponent } from './organisms/organism-form-dialog.component';
import { DatasetActivationToggleComponent } from './datasets/dataset-activation-toogle/dataset-activation-toggle.component';
import { PublicationsListComponent } from '@geonature/metadataModule/publications/publications-list/publications-list.component';
import { PublicationCardComponent } from '@geonature/metadataModule/publications/publication-card/publication-card.component';
import { PublicationFormModalComponent } from '@geonature/metadataModule/publications/publication-form-modal/publication-form-modal.component';
import { PublicationsService } from '@geonature/metadataModule/services/publication.service';
import { PublicationDeleteButtonComponent } from './publications/publication-delete-button/publication-delete-button.component';
import { PublicationConsultButtonComponent } from './publications/publication-consult-button/publication-consult-button.component';
import { ReactiveFormsModule } from '@angular/forms';
import { AssociatedDatasetCardListComponent } from './datasets/associated-dataset-card-list/associated-dataset-card-list-component';
import { AssociatedAfCardListComponent } from '@geonature/metadataModule/af/associated-af-card-list/associated-af-card-list.component';
import { PublicationAssociateButtonComponent } from '@geonature/metadataModule/publications/publication-associate-button/publication-associate-button.component';
import { PublicationAssociationModalComponent } from '@geonature/metadataModule/publications/publication-association-modal/publication-association-modal.component';
import { AssociatedPublicationsCardListComponent } from '@geonature/metadataModule/publications/associated-pubication-card-list/associated-publications-card-list.component';
import { PublicationDisassociateButtonComponent } from '@geonature/metadataModule/publications/disassociate-publication-button/disassociate-publication-button.component';
import { ProductionDatabaseComponent } from './production-database/production-database.component';

const routes: Routes = [
  { path: '', component: MetadataComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'dataset_detail/:id', component: DatasetCardComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'af_detail/:id', component: AfCardComponent },
  { path: 'publication', component: PublicationsListComponent },
  { path: 'publication_detail/:id', component: PublicationCardComponent },
];

@Injectable()
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
    NgChartsModule,
    RouterModule.forChild(routes),
    MatCheckboxModule,
    MatButtonToggleModule,
    ReactiveFormsModule,
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
    ButtonDeleteAfComponent,
    ButtonCloseAfComponent,
    DatasetActivationToggleComponent,
    OrganismFormDialogComponent,
    PublicationsListComponent,
    PublicationFormModalComponent,
    PublicationDeleteButtonComponent,
    PublicationConsultButtonComponent,
    PublicationCardComponent,
    AssociatedDatasetCardListComponent,
    AssociatedAfCardListComponent,
    PublicationAssociateButtonComponent,
    PublicationAssociationModalComponent,
    AssociatedPublicationsCardListComponent,
    PublicationDisassociateButtonComponent,
    ProductionDatabaseComponent,
  ],
  providers: [
    MetadataService,
    MetadataDataService,
    ActorFormService,
    PublicationsService,
    {
      provide: MatPaginatorIntl,
      useClass: MetadataPaginator,
    },
  ],
})
export class MetadataModule {}
