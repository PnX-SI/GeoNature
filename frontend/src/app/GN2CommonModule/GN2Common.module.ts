import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  MatCardModule,
  MatMenuModule,
  MatSidenavModule,
  MatTooltipModule,
  MatListModule,
  MatIconModule,
  MatToolbarModule,
  MatExpansionModule,
  MatPaginatorModule,
  MatStepperModule,
  MatProgressSpinnerModule,
  MatButtonModule
} from '@angular/material';

import { HttpClient } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { NgbModule, NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { AutoCompleteModule } from 'primeng/primeng';
import { NgSelectModule } from '@ng-select/ng-select';
import { TreeModule } from 'angular-tree-component';

// Components
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { DateComponent } from './form/date/date.component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { DatasetsComponent } from './form/datasets/datasets.component';
import { DynamicFormComponent } from './form/dynamic-form/dynamic-form.component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';

import { MapComponent } from './map/map.component';
import { MarkerComponent } from './map/marker/marker.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';

import { GPSComponent } from './map/gps/gps.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { LeafletFileLayerComponent } from './map/filelayer/filelayer.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { MapListGenericFiltersComponent } from './map-list/generic-filters/generic-filters.component';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
import { MunicipalitiesComponent } from '@geonature_common/form/municipalities/municipalities.component';
import { GenericFormGeneratorComponent } from '@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { AreasComponent } from '@geonature_common/form/areas/areas.component';
import { AcquisitionFrameworksComponent } from '@geonature_common/form/acquisition-frameworks/acquisition-frameworks.component';
import { ModalDownloadComponent } from '@geonature_common/others/modal-download/modal-download.component';
import { PeriodComponent } from '@geonature_common/form/date/period.component';
import { AutoCompleteComponent } from '@geonature_common/form/autocomplete/autocomplete.component';
import { SyntheseSearchComponent } from '@geonature_common/form/synthese-form/synthese-form.component';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';

// directive
import { DisableControlDirective } from './form/disable-control.directive';

// pipe
import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';

// Service
import { MapService } from './map/map.service';
import { DataFormService } from './form/data-form.service';
import { MapListService } from './map-list/map-list.service';
import { CommonService } from './service/common.service';
import { FormService } from './form/form.service';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

// add all rxjs operators
import 'rxjs/Rx';
import { MultiSelectComponent } from './form/multiselect/multiselect.component';

@NgModule({
  imports: [
    CommonModule,
    MatIconModule,
    MatTooltipModule,
    MatSidenavModule,
    MatMenuModule,
    MatCardModule,
    MatListModule,
    MatToolbarModule,
    MatExpansionModule,
    MatPaginatorModule,
    MatStepperModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    FormsModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    NgSelectModule,
    TranslateModule.forChild(),
    NgbModule.forRoot(),
    AutoCompleteModule,
    TreeModule
  ],
  declarations: [
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    GeojsonComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe,
    DatasetsComponent,
    MapListGenericFiltersComponent,
    ObserversTextComponent,
    DynamicFormComponent,
    MunicipalitiesComponent,
    MultiSelectComponent,
    GenericFormGeneratorComponent,
    GenericFormComponent,
    AreasComponent,
    AcquisitionFrameworksComponent,
    ModalDownloadComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SyntheseSearchComponent,
    TaxonAdvancedModalComponent
  ],
  providers: [
    TranslateService,
    MapService,
    DataFormService,
    MapListService,
    CommonService,
    FormService,
    DynamicFormService,
    NgbDatePeriodParserFormatter,
    SyntheseDataService
  ],
  entryComponents: [TaxonAdvancedModalComponent],
  exports: [
    MunicipalitiesComponent,
    DynamicFormComponent,
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    MapComponent,
    MarkerComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    GeojsonComponent,
    GPSComponent,
    MapListComponent,
    MapDataComponent,
    DisableControlDirective,
    ReadablePropertiePipe,
    DatasetsComponent,
    ModalDownloadComponent,
    FormsModule,
    ReactiveFormsModule,
    MatIconModule,
    MatTooltipModule,
    MatSidenavModule,
    MatMenuModule,
    MatCardModule,
    MatListModule,
    MatToolbarModule,
    MatExpansionModule,
    MatPaginatorModule,
    NgxDatatableModule,
    NgSelectModule,
    MatStepperModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    NgbModule,
    TranslateModule,
    MapListGenericFiltersComponent,
    ObserversTextComponent,
    MultiSelectComponent,
    GenericFormGeneratorComponent,
    GenericFormComponent,
    AreasComponent,
    AcquisitionFrameworksComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SyntheseSearchComponent,
    TaxonAdvancedModalComponent
  ]
})
export class GN2CommonModule {}
