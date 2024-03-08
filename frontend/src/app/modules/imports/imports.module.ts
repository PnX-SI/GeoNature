import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatStepperModule } from '@angular/material/stepper';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { NgChartsModule } from 'ng2-charts';

import { ImportModalDestinationComponent } from './components/modal_destination/import-modal-destination.component';
import { ModalDeleteImport } from './components/delete-modal/delete-modal.component';
import { DataService } from './services/data.service';
import { CsvExportService } from './services/csv-export.service';
import { FieldMappingService } from './services/mappings/field-mapping.service';
import { ContentMappingService } from './services/mappings/content-mapping.service';
import { ImportListComponent } from './components/import_list/import-list.component';
import { ImportErrorsComponent } from './components/import_errors/import_errors.component';
import { ImportProcessService } from './components/import_process/import-process.service';
import { ImportProcessResolver } from './components/import_process/import-process.resolver';
import { ImportProcessComponent } from './components/import_process/import-process.component';
import { UploadFileStepComponent } from './components/import_process/upload-file-step/upload-file-step.component';
import { DecodeFileStepComponent } from './components/import_process/decode-file-step/decode-file-step.component';
import { FieldsMappingStepComponent } from './components/import_process/fields-mapping-step/fields-mapping-step.component';
import { ContentMappingStepComponent } from './components/import_process/content-mapping-step/content-mapping-step.component';
import { ImportStepComponent } from './components/import_process/import-step/import-step.component';
import { StepperComponent } from './components/import_process/stepper/stepper.component';
import { FooterStepperComponent } from './components/import_process/footer-stepper/footer-stepper.component';
import { Step } from './models/enums.model';
import { ImportReportComponent } from './components/import_report/import_report.component';
import { DestinationsComponent } from './components/destinations/destinations.component';

const routes: Routes = [
  { path: '', component: ImportListComponent },
  {
    path: ':id_import/errors',
    component: ImportErrorsComponent,
    resolve: { importData: ImportProcessResolver },
  },
  {
    path: ':destination/:id_import/report',
    component: ImportReportComponent,
    resolve: { importData: ImportProcessResolver },
  },
  {
    path: ':destination/process',
    component: ImportProcessComponent,
    children: [
      {
        path: 'upload',
        component: UploadFileStepComponent,
        data: { step: Step.Upload },
        resolve: { importData: ImportProcessResolver },
      },
      {
        path: ':id_import/upload',
        component: UploadFileStepComponent,
        data: { step: Step.Upload },
        resolve: { importData: ImportProcessResolver },
      },
      {
        path: ':id_import/decode',
        component: DecodeFileStepComponent,
        data: { step: Step.Decode },
        resolve: { importData: ImportProcessResolver },
      },
      {
        path: ':id_import/fieldmapping',
        component: FieldsMappingStepComponent,
        data: { step: Step.FieldMapping },
        resolve: { importData: ImportProcessResolver },
      },
      {
        path: ':id_import/contentmapping',
        component: ContentMappingStepComponent,
        data: { step: Step.ContentMapping },
        resolve: { importData: ImportProcessResolver },
      },
      {
        path: ':id_import/import',
        component: ImportStepComponent,
        data: { step: Step.Import },
        resolve: { importData: ImportProcessResolver },
      },
    ],
  },
];

@NgModule({
  declarations: [
    ImportListComponent,
    ImportErrorsComponent,
    ImportModalDestinationComponent,
    ModalDeleteImport,
    UploadFileStepComponent,
    DecodeFileStepComponent,
    FieldsMappingStepComponent,
    ContentMappingStepComponent,
    ImportStepComponent,
    StepperComponent,
    FooterStepperComponent,
    ImportProcessComponent,
    ImportReportComponent,
    DestinationsComponent,
  ],
  imports: [
    NgChartsModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
    CommonModule,
    MatProgressSpinnerModule,
    MatStepperModule,
    MatCheckboxModule,
    NgbModule,
  ],
  entryComponents: [ModalDeleteImport],
  providers: [
    DataService,
    ImportProcessService,
    ImportProcessResolver,
    CsvExportService,
    FieldMappingService,
    ContentMappingService,
  ],
  bootstrap: [],
})
export class ImportsModule {}
